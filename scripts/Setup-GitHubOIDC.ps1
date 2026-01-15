<#
.SYNOPSIS
    Sets up Azure OIDC authentication for GitHub Actions.

.DESCRIPTION
    This script creates an Azure AD App Registration and Federated Credential
    for passwordless GitHub Actions authentication using OpenID Connect (OIDC).

.PARAMETER GitHubOrg
    GitHub organization or username

.PARAMETER GitHubRepo
    GitHub repository name

.PARAMETER SubscriptionId
    Azure subscription ID (optional, uses current context if not provided)

.PARAMETER ResourceGroupName
    Resource group name for deployments

.PARAMETER Location
    Azure region for resource group (default: eastus)

.EXAMPLE
    .\Setup-GitHubOIDC.ps1 -GitHubOrg "contoso" -GitHubRepo "azure-webapp" -ResourceGroupName "rg-webapp-dev"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubOrg,

    [Parameter(Mandatory = $true)]
    [string]$GitHubRepo,

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  GitHub OIDC Setup for Azure" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI not found. Install from: https://aka.ms/installazurecli"
    exit 1
}
Write-Host "✓ Azure CLI installed" -ForegroundColor Green

# Check GitHub CLI (optional but helpful)
$hasGH = Get-Command gh -ErrorAction SilentlyContinue
if ($hasGH) {
    Write-Host "✓ GitHub CLI installed" -ForegroundColor Green
} else {
    Write-Host "⚠ GitHub CLI not installed (optional)" -ForegroundColor Yellow
}

# Login check
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Logging into Azure..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}
Write-Host "✓ Logged in as: $($account.user.name)" -ForegroundColor Green

# Set subscription
if ($SubscriptionId) {
    az account set --subscription $SubscriptionId
    $account = az account show | ConvertFrom-Json
}
$SubscriptionId = $account.id
$TenantId = $account.tenantId
Write-Host "✓ Subscription: $($account.name) ($SubscriptionId)" -ForegroundColor Green

# Create resource group if needed
Write-Host ""
Write-Host "Creating resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName | ConvertFrom-Json
if (-not $rgExists) {
    az group create --name $ResourceGroupName --location $Location | Out-Null
    Write-Host "✓ Created resource group: $ResourceGroupName" -ForegroundColor Green
} else {
    Write-Host "✓ Resource group exists: $ResourceGroupName" -ForegroundColor Green
}

# Create Azure AD App Registration
Write-Host ""
Write-Host "Creating Azure AD App Registration..." -ForegroundColor Yellow
$appName = "github-actions-$GitHubOrg-$GitHubRepo"

# Check if app already exists
$existingApp = az ad app list --display-name $appName 2>$null | ConvertFrom-Json
if ($existingApp -and $existingApp.Count -gt 0) {
    $appId = $existingApp[0].appId
    Write-Host "✓ App registration exists: $appName (ID: $appId)" -ForegroundColor Green
} else {
    $app = az ad app create --display-name $appName | ConvertFrom-Json
    $appId = $app.appId
    Write-Host "✓ Created app registration: $appName (ID: $appId)" -ForegroundColor Green
}

# Create Service Principal if needed
Write-Host ""
Write-Host "Creating Service Principal..." -ForegroundColor Yellow
$sp = az ad sp list --filter "appId eq '$appId'" 2>$null | ConvertFrom-Json
if (-not $sp -or $sp.Count -eq 0) {
    $sp = az ad sp create --id $appId | ConvertFrom-Json
    Write-Host "✓ Created service principal" -ForegroundColor Green
} else {
    $sp = $sp[0]
    Write-Host "✓ Service principal exists" -ForegroundColor Green
}
$spObjectId = $sp.id

# Create Federated Credentials for GitHub OIDC
Write-Host ""
Write-Host "Creating Federated Credentials..." -ForegroundColor Yellow

$federatedCredentials = @(
    @{
        name = "github-main-branch"
        subject = "repo:${GitHubOrg}/${GitHubRepo}:ref:refs/heads/main"
        description = "GitHub Actions - main branch"
    },
    @{
        name = "github-pull-request"
        subject = "repo:${GitHubOrg}/${GitHubRepo}:pull_request"
        description = "GitHub Actions - Pull Requests"
    },
    @{
        name = "github-environment-dev"
        subject = "repo:${GitHubOrg}/${GitHubRepo}:environment:dev"
        description = "GitHub Actions - dev environment"
    },
    @{
        name = "github-environment-staging"
        subject = "repo:${GitHubOrg}/${GitHubRepo}:environment:staging"
        description = "GitHub Actions - staging environment"
    },
    @{
        name = "github-environment-prod"
        subject = "repo:${GitHubOrg}/${GitHubRepo}:environment:prod"
        description = "GitHub Actions - prod environment"
    }
)

foreach ($cred in $federatedCredentials) {
    $existingCred = az ad app federated-credential list --id $appId --query "[?name=='$($cred.name)']" 2>$null | ConvertFrom-Json
    if ($existingCred -and $existingCred.Count -gt 0) {
        Write-Host "  ✓ $($cred.name) (exists)" -ForegroundColor Green
    } else {
        $credJson = @{
            name = $cred.name
            issuer = "https://token.actions.githubusercontent.com"
            subject = $cred.subject
            description = $cred.description
            audiences = @("api://AzureADTokenExchange")
        } | ConvertTo-Json -Compress

        $credJson | az ad app federated-credential create --id $appId --parameters "@-" | Out-Null
        Write-Host "  ✓ $($cred.name) (created)" -ForegroundColor Green
    }
}

# Assign Contributor role to resource group
Write-Host ""
Write-Host "Assigning RBAC roles..." -ForegroundColor Yellow

$roleAssignment = az role assignment list `
    --assignee $spObjectId `
    --scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName" `
    --role "Contributor" 2>$null | ConvertFrom-Json

if (-not $roleAssignment -or $roleAssignment.Count -eq 0) {
    az role assignment create `
        --assignee $spObjectId `
        --role "Contributor" `
        --scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName" | Out-Null
    Write-Host "✓ Assigned Contributor role to resource group" -ForegroundColor Green
} else {
    Write-Host "✓ Contributor role already assigned" -ForegroundColor Green
}

# Output summary
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  SETUP COMPLETE" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Add these secrets to your GitHub repository:" -ForegroundColor Yellow
Write-Host "  Settings > Secrets and variables > Actions > New repository secret" -ForegroundColor Gray
Write-Host ""
Write-Host "  AZURE_CLIENT_ID      = $appId" -ForegroundColor Cyan
Write-Host "  AZURE_TENANT_ID      = $TenantId" -ForegroundColor Cyan
Write-Host "  AZURE_SUBSCRIPTION_ID = $SubscriptionId" -ForegroundColor Cyan
Write-Host "  AZURE_RG             = $ResourceGroupName" -ForegroundColor Cyan
Write-Host "  AZURE_LOCATION       = $Location" -ForegroundColor Cyan
Write-Host ""

# Optionally set secrets with GitHub CLI
if ($hasGH) {
    Write-Host "Would you like to set these secrets automatically using GitHub CLI? (y/n)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host "Setting GitHub secrets..." -ForegroundColor Yellow

        gh secret set AZURE_CLIENT_ID --body $appId --repo "$GitHubOrg/$GitHubRepo"
        gh secret set AZURE_TENANT_ID --body $TenantId --repo "$GitHubOrg/$GitHubRepo"
        gh secret set AZURE_SUBSCRIPTION_ID --body $SubscriptionId --repo "$GitHubOrg/$GitHubRepo"
        gh secret set AZURE_RG --body $ResourceGroupName --repo "$GitHubOrg/$GitHubRepo"
        gh secret set AZURE_LOCATION --body $Location --repo "$GitHubOrg/$GitHubRepo"

        Write-Host "✓ All secrets configured!" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Add the secrets above to GitHub (if not done automatically)"
Write-Host "  2. Create GitHub environments: dev, staging, prod"
Write-Host "  3. Push your code to trigger the workflows"
Write-Host ""

# Return values for programmatic use
[PSCustomObject]@{
    ClientId = $appId
    TenantId = $TenantId
    SubscriptionId = $SubscriptionId
    ResourceGroupName = $ResourceGroupName
    ServicePrincipalObjectId = $spObjectId
}
