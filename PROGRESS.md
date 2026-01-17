# Project Progress - Azure ARM Template Package

**Last Updated**: January 2025
**Status**: Core package complete, ready for Azure OIDC setup

## Completed

### 1. ARM Template Package
- [x] Main ARM template (`azuredeploy.json`) v1.1.0
  - App Service Plan (Linux)
  - Web App with managed identity
  - Application Insights + Log Analytics (optional)
  - Key Vault with RBAC (optional)
  - Staging slot for blue-green deployments (optional)
- [x] Parameters file with sensible defaults
- [x] Metadata file for template discovery

### 2. GitHub Repository
- [x] Created: https://github.com/nathancarey/azure-webapp-template
- [x] Deploy to Azure button working
- [x] Visualize button working
- [x] README with full documentation

### 3. GitHub Actions Workflows
- [x] `validate.yml` - PR/push validation (JSON, schema, security checks)
- [x] `deploy.yml` - Manual deployment with environment selection

### 4. Helper Scripts
- [x] `Generate-DeployButton.ps1` - Generates encoded Deploy to Azure URLs
- [x] `Setup-GitHubOIDC.ps1` - Automates Azure AD + GitHub OIDC setup

## Not Yet Done

### Azure OIDC Setup (for CI/CD)
To enable GitHub Actions deployments, run:
```powershell
cd C:\claudecode\arm-deploy-package
.\scripts\Setup-GitHubOIDC.ps1 `
  -GitHubOrg "nathancarey" `
  -GitHubRepo "azure-webapp-template" `
  -ResourceGroupName "rg-webapp-dev"
```

This will:
1. Create Azure AD App Registration
2. Configure federated credentials for GitHub OIDC
3. Assign Contributor role to resource group
4. Set GitHub secrets (if gh CLI installed)

### GitHub Environments (Optional)
Create environments for deployment protection:
1. Go to: https://github.com/nathancarey/azure-webapp-template/settings/environments
2. Create: `dev`, `staging`, `prod`
3. Add required reviewers for `prod`

## Local Files

```
C:\claudecode\arm-deploy-package\
├── .github/workflows/
│   ├── validate.yml
│   └── deploy.yml
├── scripts/
│   ├── Generate-DeployButton.ps1
│   └── Setup-GitHubOIDC.ps1
├── templates/
│   ├── azuredeploy.json
│   └── azuredeploy.parameters.json
├── metadata.json
├── README.md
└── PROGRESS.md (this file)
```

## Quick Links

- **Repository**: https://github.com/nathancarey/azure-webapp-template
- **Deploy Button**: https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnathancarey%2Fazure-webapp-template%2Fmaster%2Ftemplates%2Fazuredeploy.json
- **Actions**: https://github.com/nathancarey/azure-webapp-template/actions

## Resume Commands

When ready to continue, run:
```powershell
cd C:\claudecode\arm-deploy-package
git pull  # Get any remote changes
```

Then set up Azure OIDC if you want CI/CD deployments working.
