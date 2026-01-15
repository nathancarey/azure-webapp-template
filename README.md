# Azure App Service - 1-Click Deployment

Deploy a complete Azure App Service stack with monitoring and secrets management using a single click.

## Quick Deploy

<!--
  UPDATE THIS URL: Replace YOUR_ORG/YOUR_REPO with your actual GitHub organization and repository name.
  Example: https://raw.githubusercontent.com/contoso/azure-webapp/main/templates/azuredeploy.json
-->

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR_ORG%2FYOUR_REPO%2Fmain%2Ftemplates%2Fazuredeploy.json)

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FYOUR_ORG%2FYOUR_REPO%2Fmain%2Ftemplates%2Fazuredeploy.json)

## What Gets Deployed

| Resource | Description |
|----------|-------------|
| **App Service Plan** | Linux-based hosting plan for your web app |
| **Web App** | Azure App Service with managed identity |
| **Staging Slot** | (Optional) Deployment slot for blue-green deployments |
| **Application Insights** | (Optional) Full-stack monitoring and diagnostics |
| **Log Analytics Workspace** | (Optional) Centralized log storage for App Insights |
| **Key Vault** | (Optional) Secure secrets management with RBAC |

## Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │              Resource Group                  │
                    │                                              │
                    │  ┌─────────────────┐  ┌──────────────────┐  │
                    │  │  App Service    │  │   Key Vault      │  │
                    │  │  Plan (Linux)   │  │   (RBAC-enabled) │  │
                    │  └────────┬────────┘  └────────▲─────────┘  │
                    │           │                     │            │
                    │  ┌────────▼────────┐   Managed  │            │
                    │  │    Web App      │───Identity─┘            │
                    │  │  (+ Staging)    │                         │
                    │  └────────┬────────┘                         │
                    │           │                                  │
                    │  ┌────────▼────────┐  ┌──────────────────┐  │
                    │  │  Application    │──│  Log Analytics   │  │
                    │  │  Insights       │  │  Workspace       │  │
                    │  └─────────────────┘  └──────────────────┘  │
                    │                                              │
                    └─────────────────────────────────────────────┘
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `appName` | Unique name for your web app | *Required* |
| `location` | Azure region for deployment | Resource Group location |
| `sku` | App Service Plan tier (F1, B1, S1, P1v2, etc.) | B1 |
| `linuxFxVersion` | Runtime stack (.NET, Node, Python, PHP, Java) | DOTNETCORE\|8.0 |
| `enableAutoUpdate` | Enable staging slot for zero-downtime updates | true |
| `enableApplicationInsights` | Deploy Application Insights + Log Analytics | true |
| `enableKeyVault` | Deploy Key Vault with app access | true |
| `keyVaultSku` | Key Vault tier (standard or premium for HSM) | standard |
| `logRetentionDays` | Days to retain logs (7-730) | 30 |

## Features

### Application Insights

When enabled, provides:
- **Live Metrics** - Real-time performance monitoring
- **Request Tracing** - End-to-end transaction visibility
- **Failure Analysis** - Automatic exception detection
- **Performance Profiling** - Response time breakdown
- **Availability Tests** - Uptime monitoring (configure in portal)

The Web App is automatically configured with:
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Auto-injected
- `ApplicationInsightsAgent_EXTENSION_VERSION` - Set to `~3`
- Full telemetry collection enabled

### Key Vault Integration

When enabled, provides:
- **RBAC Authorization** - Modern role-based access control
- **Managed Identity** - Web App gets `Key Vault Secrets User` role
- **Soft Delete** - 90-day recovery window
- **Purge Protection** - Prevents permanent deletion

Access secrets in your app using Key Vault references:
```
@Microsoft.KeyVault(SecretUri=https://your-vault.vault.azure.net/secrets/MySecret/)
```

Or via the SDK with the managed identity (no credentials needed):
```csharp
var client = new SecretClient(
    new Uri(Environment.GetEnvironmentVariable("KEY_VAULT_URI")),
    new DefaultAzureCredential()
);
var secret = await client.GetSecretAsync("MySecret");
```

### Staging Slot (Auto-Update)

When `enableAutoUpdate=true` and SKU is B1 or higher:
- Staging slot created with auto-swap to production
- Deploy to staging, automatically promoted when healthy
- Zero-downtime deployments

## Alternative Deployment Methods

### Azure CLI

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-uri https://raw.githubusercontent.com/YOUR_ORG/YOUR_REPO/main/templates/azuredeploy.json \
  --parameters appName=<your-app-name> \
               enableApplicationInsights=true \
               enableKeyVault=true
```

### PowerShell

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "<your-resource-group>" `
  -TemplateUri "https://raw.githubusercontent.com/YOUR_ORG/YOUR_REPO/main/templates/azuredeploy.json" `
  -appName "<your-app-name>" `
  -enableApplicationInsights $true `
  -enableKeyVault $true
```

### Local Deployment

```powershell
# Clone and deploy locally
git clone https://github.com/YOUR_ORG/YOUR_REPO.git
cd YOUR_REPO

New-AzResourceGroupDeployment `
  -ResourceGroupName "<your-resource-group>" `
  -TemplateFile "./templates/azuredeploy.json" `
  -TemplateParameterFile "./templates/azuredeploy.parameters.json"
```

## Self-Updating

This template supports self-updating through:

1. **Re-deploy from GitHub** - The Deploy to Azure button always pulls the latest template from the `main` branch

2. **Staging Slot (Blue-Green)** - Deploy updates to staging, auto-swap to production

3. **Version Tracking** - `TEMPLATE_VERSION` app setting shows deployed version

## Runtime Options

| Runtime | Value |
|---------|-------|
| .NET 8 | `DOTNETCORE\|8.0` |
| .NET 7 | `DOTNETCORE\|7.0` |
| Node.js 20 | `NODE\|20-lts` |
| Node.js 18 | `NODE\|18-lts` |
| Python 3.12 | `PYTHON\|3.12` |
| Python 3.11 | `PYTHON\|3.11` |
| PHP 8.2 | `PHP\|8.2` |
| Java 17 | `JAVA\|17-java17` |
| Java 11 | `JAVA\|11-java11` |

## Pricing Estimates

### App Service

| SKU | vCPU | Memory | Price (approx) |
|-----|------|--------|----------------|
| F1 | Shared | 1 GB | Free |
| B1 | 1 | 1.75 GB | ~$13/month |
| B2 | 2 | 3.5 GB | ~$26/month |
| S1 | 1 | 1.75 GB | ~$73/month |
| P1v2 | 1 | 3.5 GB | ~$81/month |

> Note: F1 (Free) tier does not support Always On, deployment slots, or custom domains with SSL.

### Application Insights & Log Analytics

- **Pay-as-you-go**: ~$2.30/GB ingested
- **First 5 GB/month**: Free
- **Retention**: First 31 days free, then ~$0.10/GB/month

### Key Vault

- **Standard**: ~$0.03 per 10,000 operations
- **Premium (HSM)**: ~$1.00 per key/month + operations
- **Secrets**: Free storage, pay per operation

## Outputs

After deployment, the template outputs:

| Output | Description |
|--------|-------------|
| `webAppUrl` | URL of the deployed web app |
| `stagingSlotUrl` | URL of the staging slot (if enabled) |
| `applicationInsightsConnectionString` | App Insights connection string |
| `keyVaultUri` | Key Vault URI for SDK access |
| `webAppPrincipalId` | Managed Identity principal ID |

## After Deployment

1. **Navigate to** the [Azure Portal](https://portal.azure.com)
2. **Connect your code** via Deployment Center (GitHub, Azure DevOps, etc.)
3. **Add secrets** to Key Vault using the portal or CLI
4. **Configure alerts** in Application Insights
5. **Set up custom domains** and SSL certificates

### Quick CLI Commands

```bash
# Add a secret to Key Vault
az keyvault secret set --vault-name <vault-name> --name "MySecret" --value "secret-value"

# View App Insights live metrics
az monitor app-insights component show --app <app-insights-name> -g <resource-group>

# Stream web app logs
az webapp log tail --name <app-name> -g <resource-group>
```

## CI/CD with GitHub Actions

This repository includes GitHub Actions workflows for automated validation and deployment.

### Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `validate.yml` | PR, Push to main | Validates JSON syntax, ARM schema, parameters, security |
| `deploy.yml` | Manual (workflow_dispatch) | Deploys to Azure with environment selection |

### Setup (One-Time)

#### Option 1: Automated Setup Script

```powershell
# Run the setup script
.\scripts\Setup-GitHubOIDC.ps1 `
  -GitHubOrg "YOUR_ORG" `
  -GitHubRepo "YOUR_REPO" `
  -ResourceGroupName "rg-webapp-dev"
```

This script:
- Creates an Azure AD App Registration
- Configures federated credentials for GitHub OIDC
- Assigns Contributor role to the resource group
- Optionally sets GitHub secrets (if `gh` CLI is installed)

#### Option 2: Manual Setup

1. **Create Azure AD App Registration**
   ```bash
   az ad app create --display-name "github-actions-YOUR_REPO"
   az ad sp create --id <app-id>
   ```

2. **Add Federated Credentials** (Azure Portal)
   - Go to Azure AD > App Registrations > Your App > Certificates & Secrets
   - Add Federated Credential with:
     - Issuer: `https://token.actions.githubusercontent.com`
     - Subject: `repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main`

3. **Assign RBAC Role**
   ```bash
   az role assignment create \
     --assignee <service-principal-id> \
     --role "Contributor" \
     --scope "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
   ```

4. **Add GitHub Secrets**

   Go to: Repository > Settings > Secrets and variables > Actions

   | Secret | Value |
   |--------|-------|
   | `AZURE_CLIENT_ID` | App Registration Client ID |
   | `AZURE_TENANT_ID` | Azure AD Tenant ID |
   | `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID |
   | `AZURE_RG` | Resource Group name |
   | `AZURE_LOCATION` | Azure region (e.g., `eastus`) |

5. **Create GitHub Environments** (Optional, for environment protection)
   - Go to: Repository > Settings > Environments
   - Create: `dev`, `staging`, `prod`
   - Add required reviewers for `prod`

### Running Deployments

#### Manual Deployment (Recommended)

1. Go to: Actions > "Deploy to Azure" > Run workflow
2. Select environment (dev/staging/prod)
3. Enter app name and options
4. Click "Run workflow"

#### Auto-Deploy on Push (Optional)

Uncomment these lines in `.github/workflows/deploy.yml`:

```yaml
push:
  branches: [main]
  paths:
    - 'templates/**'
```

### Workflow Features

**Validation Workflow:**
- JSON syntax validation
- ARM schema verification
- Parameter file cross-check
- Security best practices audit
- What-If analysis (with Azure credentials)

**Deployment Workflow:**
- OIDC authentication (no secrets stored)
- What-If preview before deployment
- Environment-specific deployments
- Deployment verification
- Summary with outputs

## Troubleshooting

### Key Vault Access Denied
The Web App needs a few minutes after deployment for the managed identity to propagate. If you see 403 errors, wait 5 minutes and retry.

### Application Insights Not Showing Data
Ensure your application has the App Insights SDK installed, or for .NET apps, the auto-instrumentation agent will handle it automatically.

### Staging Slot Not Created
Staging slots require B1 or higher SKU. Free tier (F1) does not support deployment slots.

## Contributing

1. Fork this repository
2. Make your changes to the templates
3. Test with the "Visualize" button above
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.
