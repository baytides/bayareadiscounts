# Azure Infrastructure for Bay Area Discounts

This directory contains Infrastructure as Code (IaC) using Azure Bicep to deploy all Azure resources needed for the Bay Area Discounts application.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Bay Area Discounts                      │
│                    Azure Architecture                       │
└─────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐
│  Static Web App  │────────▶│ Azure Functions  │
│  (Frontend)      │   API   │  (Backend API)   │
└──────────────────┘         └─────────┬────────┘
                                       │
                                       ▼
                             ┌──────────────────┐
                             │   Cosmos DB      │
                             │ (NoSQL Database) │
                             └──────────────────┘
                                       ▲
                                       │
                             ┌─────────┴────────┐
                             │ Application      │
                             │   Insights       │
                             │  (Monitoring)    │
                             └──────────────────┘
```

## 📦 Resources Deployed

### 1. **Azure Cosmos DB** (Serverless)
- **Purpose**: NoSQL database for program data
- **Pricing**: Serverless (pay-per-request)
- **Free tier**: 1000 RU/s, 25 GB storage
- **Partition key**: `/category` for efficient queries
- **Indexing**: Automatic indexing on all fields

### 2. **Azure Functions** (Consumption Plan)
- **Purpose**: Serverless API endpoints
- **Pricing**: Pay-per-execution (first 1M executions free/month)
- **Runtime**: Node.js 20
- **Endpoints**:
  - `GET /api/programs` - List all programs (with filters)
  - `GET /api/programs/{id}` - Get single program
  - `GET /api/categories` - List all categories

### 3. **Azure Storage Account**
- **Purpose**: Required for Azure Functions runtime
- **Pricing**: LRS (Locally Redundant Storage) - minimal cost

### 4. **Application Insights**
- **Purpose**: Monitoring, logging, and analytics
- **Free tier**: 5 GB/month included
- **Features**:
  - API performance monitoring
  - Error tracking
  - Usage analytics
  - Custom metrics

## 🚀 Deployment Guide

### Prerequisites

1. **Azure Account**
   - Sign up at https://azure.microsoft.com/free/
   - $200 free credit for 30 days
   - Many services free forever

2. **Azure CLI**
   ```bash
   # macOS
   brew install azure-cli

   # Windows
   winget install Microsoft.AzureCLI

   # Linux
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

3. **Login to Azure**
   ```bash
   az login
   ```

### Step 1: Create Resource Group

```bash
# Create a resource group
az group create \
  --name bayareadiscounts-rg \
  --location westus2
```

### Step 2: Deploy Infrastructure

```bash
# Deploy the Bicep template
az deployment group create \
  --resource-group bayareadiscounts-rg \
  --template-file infrastructure/bicep/main.bicep \
  --parameters infrastructure/bicep/parameters.json.example
```

This will create:
- ✅ Cosmos DB account
- ✅ Cosmos DB database and container
- ✅ Azure Functions app
- ✅ Storage account
- ✅ Application Insights

Deployment takes ~5-10 minutes.

### Step 3: Get Connection Strings

```bash
# Get Cosmos DB endpoint and key
az cosmosdb show \
  --resource-group bayareadiscounts-rg \
  --name <cosmos-account-name> \
  --query documentEndpoint

az cosmosdb keys list \
  --resource-group bayareadiscounts-rg \
  --name <cosmos-account-name> \
  --query primaryMasterKey
```

### Step 4: Migrate Data

```bash
# Set environment variables
export COSMOS_DB_ENDPOINT="https://your-cosmos.documents.azure.com:443/"
export COSMOS_DB_KEY="your-cosmos-key"
export COSMOS_DB_DATABASE_NAME="bayareadiscounts"
export COSMOS_DB_CONTAINER_NAME="programs"

# Install dependencies
cd scripts
npm install

# Run migration
npm run migrate
```

### Step 5: Deploy Functions

```bash
# Install dependencies
cd azure-functions
npm install

# Deploy to Azure Functions
func azure functionapp publish <function-app-name>
```

Or use GitHub Actions (see below).

## 🔐 GitHub Secrets Setup

For automated deployments via GitHub Actions, configure these secrets:

### Authentication

The application uses **Managed Identity** (Azure AD) for all authentication to Azure services (Cosmos DB, Translator, Storage). No API keys or connection strings are needed in environment variables.

### Required Secrets

1. **AZURE_FUNCTION_APP_NAME**
   - Your Function App name (e.g., `bayareadiscounts-func-prod-abc123`)

2. **AZURE_FUNCTION_APP_PUBLISH_PROFILE**
   ```bash
   az functionapp deployment list-publishing-profiles \
     --resource-group bayareadiscounts-rg \
     --name <function-app-name> \
     --xml
   ```
   Copy the entire XML output

3. **AZURE_CLIENT_ID** (for infrastructure deployment)
   - Create a service principal:
   ```bash
   az ad sp create-for-rbac \
     --name "bayareadiscounts-deployer" \
     --role contributor \
     --scopes /subscriptions/<subscription-id>/resourceGroups/bayareadiscounts-rg \
     --sdk-auth
   ```

4. **AZURE_TENANT_ID**
   - From the service principal output above

5. **AZURE_SUBSCRIPTION_ID**
   - From the service principal output above

6. **AZURE_RESOURCE_GROUP**
   - Value: `bayareadiscounts-rg`

## 🔄 CI/CD Workflows

### 1. Azure Functions Deployment
**File**: `.github/workflows/azure-functions-deploy.yml`

**Triggers**:
- Push to `main` branch (when `azure-functions/` changes)
- Manual trigger via GitHub Actions UI

**What it does**:
- Installs dependencies
- Deploys code to Azure Functions
- Updates API endpoints

### 2. Infrastructure Deployment
**File**: `.github/workflows/azure-infrastructure-deploy.yml`

**Triggers**:
- Manual trigger only (via GitHub Actions UI)

**What it does**:
- Deploys/updates Azure resources using Bicep
- Creates or modifies Cosmos DB, Functions, etc.

## 💰 Cost Estimation

Based on moderate usage (1000 visitors/day):

| Service | Pricing Tier | Monthly Cost |
|---------|-------------|--------------|
| Cosmos DB | Serverless | $0-5 (likely free tier) |
| Azure Functions | Consumption | $0 (within free tier) |
| Storage Account | Standard LRS | $0.02 |
| Application Insights | Basic | $0 (within free tier) |
| **Total** | | **~$0.02/month** |

**Free tiers include**:
- Cosmos DB: 1000 RU/s, 25 GB storage
- Functions: 1M executions, 400k GB-s/month
- App Insights: 5 GB data/month

## 🔧 Configuration

### Environment Variables

Configuration is managed through Azure Function App Settings (set automatically by Bicep):

```bash
az functionapp config appsettings set \
  --resource-group bayareadiscounts-rg \
  --name <function-app-name> \
  --settings \
    COSMOS_DB_ENDPOINT="https://..." \
    COSMOS_DB_DATABASE_NAME="bayareadiscounts" \
    COSMOS_DB_CONTAINER_NAME="programs" \
    AZURE_TRANSLATOR_ENDPOINT="https://..."
```

**Note**: No API keys needed. Authentication uses Managed Identity (DefaultAzureCredential).

## 📊 Monitoring

Access monitoring dashboards:

```bash
# Get Application Insights URL
az monitor app-insights component show \
  --resource-group bayareadiscounts-rg \
  --app <app-insights-name> \
  --query "appId"
```

Or visit: [Azure Portal](https://portal.azure.com) → Application Insights

## 🗑️ Cleanup

To delete all Azure resources:

```bash
# WARNING: This deletes everything!
az group delete \
  --name bayareadiscounts-rg \
  --yes \
  --no-wait
```

## 📝 License

This infrastructure code is licensed under the MIT License.
See [LICENSE](../LICENSE) for details.

## 🆘 Troubleshooting

### Issue: Deployment fails with "name already exists"
**Solution**: Resource names must be globally unique. Edit `parameters.json` to use a different `appName`.

### Issue: Migration script fails with authentication error
**Solution**: The migration script uses legacy key-based auth. For new deployments, use Managed Identity. Run: `az login` and ensure your account has appropriate roles on Cosmos DB.

### Issue: Functions not appearing in Azure Portal
**Solution**: Wait 5-10 minutes after deployment, then refresh. Functions may take time to register.

### Issue: CORS errors when calling API
**Solution**: Update the `cors.allowedOrigins` in `main.bicep` to include your domain.

## 📚 Learn More

- [Azure Cosmos DB Documentation](https://docs.microsoft.com/azure/cosmos-db/)
- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Free Account](https://azure.microsoft.com/free/)
