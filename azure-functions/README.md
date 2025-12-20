# Azure Functions API for Bay Area Discounts

This directory contains the serverless API backend for Bay Area Discounts, built with Azure Functions.

## 🚀 API Endpoints

Base URL (production): `https://<your-function-app>.azurewebsites.net/api`

Canonical API contract: see [openapi/bayareadiscounts-api.yaml](../openapi/bayareadiscounts-api.yaml). Client helpers live in [../shared](../shared).

### 1. Get All Programs

**GET** `/programs`

Returns all programs with optional filtering.

**Query Parameters:**
- `category` (string): Filter by category (e.g., "Food", "Health")
- `area` (string): Filter by geographic area (e.g., "San Francisco")
- `eligibility` (string): Filter by eligibility (e.g., "seniors", "low-income")
- `search` (string): Search program names and descriptions

**Examples:**
```bash
# Get all programs
GET /api/programs

# Get food programs in San Francisco
GET /api/programs?category=Food&area=San%20Francisco

# Get programs for seniors
GET /api/programs?eligibility=seniors

# Search for "meals"
GET /api/programs?search=meals
```

**Response:**
```json
{
  "count": 42,
  "programs": [
    {
      "id": "alameda-food-bank",
      "name": "Alameda County Community Food Bank",
      "category": "Food",
      "area": "Alameda County",
      "eligibility": ["low-income", "everyone"],
      "benefit": "Free food pantries and distributions throughout county",
      "timeframe": "Ongoing",
      "link": "https://www.accfb.org/",
      "link_text": "Find Location",
      "verified_date": "2025-12-16"
    }
  ]
}
```

### 2. Get Program by ID

**GET** `/programs/{id}`

Returns a single program by its ID.

**Example:**
```bash
GET /api/programs/alameda-food-bank
```

**Response:**
```json
{
  "id": "alameda-food-bank",
  "name": "Alameda County Community Food Bank",
  "category": "Food",
  ...
}
```

**Error Response (404):**
```json
{
  "error": "Program not found",
  "id": "invalid-id"
}
```

### 3. Get Categories

**GET** `/categories`

Returns all unique categories with program counts.

**Example:**
```bash
GET /api/categories
```

**Response:**
```json
{
  "count": 14,
  "categories": [
    {
      "category": "Food",
      "count": 35
    },
    {
      "category": "Health",
      "count": 18
    }
  ]
}
```

## 🏗️ Architecture

```
azure-functions/
├── GetPrograms/          # GET /api/programs
│   ├── index.js
│   └── function.json
├── GetProgramById/       # GET /api/programs/{id}
│   ├── index.js
│   └── function.json
├── GetCategories/        # GET /api/categories
│   ├── index.js
│   └── function.json
├── shared/
│   └── cosmosClient.js   # Shared Cosmos DB client
├── host.json             # Function host configuration
└── package.json          # Dependencies
```

## 🛠️ Local Development

### Prerequisites

1. **Node.js 20+**
   ```bash
   node --version  # Should be v20 or higher
   ```

2. **Azure Functions Core Tools**
   ```bash
   npm install -g azure-functions-core-tools@4
   ```

3. **Azure Cosmos DB** (local emulator or cloud)
   - Local: https://aka.ms/cosmosdb-emulator
   - Cloud: Use a dev Cosmos DB account

### Setup

1. **Install dependencies**
   ```bash
   cd azure-functions
   npm install
   ```

2. **Configure local settings**
   Create `local.settings.json`:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "FUNCTIONS_WORKER_RUNTIME": "node",
       "COSMOS_DB_ENDPOINT": "https://your-cosmos.documents.azure.com:443/",
       "COSMOS_DB_DATABASE_NAME": "bayareadiscounts",
       "COSMOS_DB_CONTAINER_NAME": "programs",
       "AZURE_TRANSLATOR_ENDPOINT": "https://your-translator.cognitiveservices.azure.com/"
     },
     "Host": {
       "CORS": "*"
     }
   }
   ```
   
   **Note**: No keys needed. Local development uses DefaultAzureCredential (Azure CLI login).

3. **Run locally**
   ```bash
   func start
   ```

   API will be available at: `http://localhost:7071/api`

### Testing Locally

```bash
# Test GET programs
curl http://localhost:7071/api/programs

# Test with filters
curl "http://localhost:7071/api/programs?category=Food"

# Test GET program by ID
curl http://localhost:7071/api/programs/alameda-food-bank

# Test GET categories
curl http://localhost:7071/api/categories
```

## 📦 Dependencies

### Production Dependencies
- `@azure/cosmos` - Cosmos DB client SDK
- `@azure/functions` - Azure Functions Node.js runtime

### Dev Dependencies
- `azure-functions-core-tools` - Local development and testing

## 🚀 Deployment

### Via GitHub Actions

Push to `main` branch - automatic deployment via `.github/workflows/azure-functions-deploy.yml`

**Deployment optimized for speed:**
- Pre-built `node_modules` (5-9 min total)
- Run-from-package mode for faster cold starts
- Includes all dependencies in zip

### Via Azure CLI

```bash
# Build and deploy
func azure functionapp publish <function-app-name>
```

### Via GitHub Actions

Push to `main` branch - automatic deployment via `.github/workflows/azure-functions-deploy.yml`

## 🔐 Environment Variables

Required configuration (set in Azure Function App Settings):

| Variable | Description | Managed by |
|----------|-------------|-----------------|
| `COSMOS_DB_ENDPOINT` | Cosmos DB endpoint URL | Set by Bicep or manually |
| `COSMOS_DB_DATABASE_NAME` | Database name | Set by Bicep |
| `COSMOS_DB_CONTAINER_NAME` | Container name | Set by Bicep |
| `AZURE_TRANSLATOR_ENDPOINT` | Translator resource endpoint | Set by Bicep or manually |
| `APPINSIGHTS_INSTRUMENTATIONKEY` | Application Insights key | Auto-set by Bicep |

**Authentication**: Uses Managed Identity (DefaultAzureCredential) via Azure AD. No keys required!

## 📊 Monitoring

### Application Insights

View function performance, errors, and logs:
```bash
# Stream logs in real-time
func azure functionapp logstream <function-app-name>
```

Or visit Azure Portal → Function App → Monitor

### Common Metrics
- Request count and duration
- Success/failure rates
- Cosmos DB RU consumption
- Error logs and exceptions

## 🔒 Security

### API Keys
- Functions use `authLevel: "anonymous"` (no API key required)
- CORS is configured to allow specific origins
- All traffic is HTTPS only

### Best Practices
✅ Use Azure Key Vault for secrets (future enhancement)
✅ Enable authentication for write operations
✅ Rate limiting via Azure API Management (future enhancement)
✅ Monitor for unusual traffic patterns

## 🧪 Testing

### Manual Testing

```bash
# Test all endpoints
curl https://<function-app>.azurewebsites.net/api/programs
curl https://<function-app>.azurewebsites.net/api/programs/alameda-food-bank
curl https://<function-app>.azurewebsites.net/api/categories
```

### Performance Testing

```bash
# Use Apache Bench
ab -n 100 -c 10 https://<function-app>.azurewebsites.net/api/programs

# Or Artillery
npm install -g artillery
artillery quick --count 10 --num 50 https://<function-app>.azurewebsites.net/api/programs
```

## 🐛 Troubleshooting

### Issue: "Cosmos DB configuration is missing"
**Solution**: Check that all `COSMOS_DB_*` environment variables are set in Function App Settings.

### Issue: CORS errors
**Solution**: Update `cors.allowedOrigins` in `infrastructure/bicep/main.bicep` and redeploy.

### Issue: 500 Internal Server Error
**Solution**: Check Application Insights logs for detailed error messages.

### Issue: Slow response times
**Solution**:
- Check Cosmos DB indexing policy
- Review query performance in Cosmos DB metrics
- Consider adding caching (Azure Cache for Redis)

## 📝 Adding New Functions

1. **Create function directory**
   ```bash
   mkdir SubmitProgram
   ```

2. **Create function.json**
   ```json
   {
     "bindings": [
       {
         "authLevel": "anonymous",
         "type": "httpTrigger",
         "direction": "in",
         "name": "req",
         "methods": ["post"],
         "route": "programs"
       },
       {
         "type": "http",
         "direction": "out",
         "name": "res"
       }
     ]
   }
   ```

3. **Create index.js**
   ```javascript
   const { app } = require('@azure/functions');
   const { getProgramsContainer } = require('../shared/cosmosClient');

   app.http('SubmitProgram', {
     methods: ['POST'],
     authLevel: 'anonymous',
     route: 'programs',
     handler: async (request, context) => {
       // Your function logic here
     }
   });
   ```

4. **Test locally**
   ```bash
   func start
   ```

5. **Deploy**
   ```bash
   func azure functionapp publish <function-app-name>
   ```

## 📚 Learn More

- [Azure Functions Node.js Developer Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-node)
- [Azure Cosmos DB SDK for JavaScript](https://docs.microsoft.com/azure/cosmos-db/sql/sql-api-nodejs-get-started)
- [HTTP Triggers and Bindings](https://docs.microsoft.com/azure/azure-functions/functions-bindings-http-webhook)

## 📄 License

MIT License - see [LICENSE](../LICENSE) for details.
