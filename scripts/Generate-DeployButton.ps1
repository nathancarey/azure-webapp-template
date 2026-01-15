<#
.SYNOPSIS
    Generates the Deploy to Azure button URL for your ARM template.

.DESCRIPTION
    This script takes your GitHub repository details and generates the
    properly encoded Deploy to Azure button URL and markdown.

.PARAMETER Owner
    GitHub organization or username (e.g., "contoso" or "john-doe")

.PARAMETER Repo
    Repository name (e.g., "azure-webapp")

.PARAMETER Branch
    Branch name (default: "main")

.PARAMETER TemplatePath
    Path to the template within the repo (default: "templates/azuredeploy.json")

.EXAMPLE
    .\Generate-DeployButton.ps1 -Owner "contoso" -Repo "azure-webapp"

.EXAMPLE
    .\Generate-DeployButton.ps1 -Owner "myorg" -Repo "infra" -Branch "production" -TemplatePath "arm/main.json"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Owner,

    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [Parameter(Mandatory = $false)]
    [string]$Branch = "main",

    [Parameter(Mandatory = $false)]
    [string]$TemplatePath = "templates/azuredeploy.json"
)

# Build the raw GitHub URL
$rawUrl = "https://raw.githubusercontent.com/$Owner/$Repo/$Branch/$TemplatePath"

# URL encode it
$encodedUrl = [uri]::EscapeDataString($rawUrl)

# Build the Deploy to Azure URL
$deployUrl = "https://portal.azure.com/#create/Microsoft.Template/uri/$encodedUrl"

# Build the ARM Visualizer URL
$vizUrl = "http://armviz.io/#/?load=$encodedUrl"

# Output
Write-Host ""
Write-Host "=== Deploy to Azure Button Generator ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Raw Template URL:" -ForegroundColor Yellow
Write-Host $rawUrl
Write-Host ""
Write-Host "Deploy to Azure URL:" -ForegroundColor Yellow
Write-Host $deployUrl
Write-Host ""
Write-Host "ARM Visualizer URL:" -ForegroundColor Yellow
Write-Host $vizUrl
Write-Host ""
Write-Host "=== Markdown (copy this to your README.md) ===" -ForegroundColor Green
Write-Host ""

$markdown = @"
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)]($deployUrl)

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)]($vizUrl)
"@

Write-Host $markdown
Write-Host ""

# Also copy to clipboard if available
try {
    $markdown | Set-Clipboard
    Write-Host "(Markdown copied to clipboard)" -ForegroundColor DarkGray
} catch {
    # Clipboard not available, skip
}

# Output as object for pipeline usage
[PSCustomObject]@{
    RawUrl      = $rawUrl
    DeployUrl   = $deployUrl
    VisualizeUrl = $vizUrl
    Markdown    = $markdown
}
