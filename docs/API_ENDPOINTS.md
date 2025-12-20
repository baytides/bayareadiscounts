# Bay Area Discounts - API Documentation

> Source of truth: [openapi/bayareadiscounts-api.yaml](openapi/bayareadiscounts-api.yaml). The summary below is for quick reference; update the OpenAPI file first, then mirror changes here if needed. For client code, see the shared helpers in [shared/](shared/).

## Base URL
```
https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net
```

## Endpoints

### 1. Get All Programs
**GET** `/api/programs`

Returns all programs with optional filtering.

**Query Parameters:**
- `category` (string): Filter by category
- `area` (string): Filter by geographic area
- `eligibility` (string): Filter by eligibility
- `search` (string): Search program names and descriptions

**Examples:**
```bash
# Get all programs
curl https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs

# Filter by category
curl https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs?category=Food

# Filter by area
curl https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs?area=San%20Francisco

# Search
curl https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs?search=meals

# Combine filters
curl https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs?category=Food&area=Alameda%20County
```

**Response:**
```json
{
  "count": 237,
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

---

### 2. Get Program by ID
**GET** `/api/programs/{id}`

Returns a single program by its ID.

**Example:**
```bash
curl https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs/alameda-food-bank
```

**Response:**
```json
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
```

**Error Response (404):**
```json
{
  "error": "Program not found",
  "id": "invalid-id"
}
```

---

### 3. Get Categories
**GET** `/api/categories`

Returns all categories with program counts.

**Example:**
```bash
curl https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/categories
```

**Response:**
```json
{
  "count": 18,
  "categories": [
    {
      "category": "Utilities",
      "count": 54
    },
    {
      "category": "Food",
      "count": 23
    }
  ]
}
```

---

### 4. Get Areas
**GET** `/api/areas`

Returns all geographic areas with program counts.

**Example:**
```bash
curl https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/areas
```

**Response:**
```json
{
  "count": 16,
  "areas": [
    {
      "area": "San Francisco",
      "count": 38
    },
    {
      "area": "Alameda County",
      "count": 18
    }
  ]
}
```

---

### 5. Get Statistics
**GET** `/api/stats`

Returns comprehensive statistics about the programs database.

**Example:**
```bash
curl https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/stats
```

**Response:**
```json
{
  "totalPrograms": 237,
  "categories": {
    "count": 18,
    "breakdown": [
      {
        "category": "Utilities",
        "count": 54
      },
      {
        "category": "Pet Resources",
        "count": 24
      }
    ]
  },
  "areas": {
    "total": 10,
    "top10": [
      {
        "area": "Statewide",
        "count": 45
      },
      {
        "area": "San Francisco",
        "count": 38
      }
    ]
  },
  "eligibility": {
    "types": 9,
    "breakdown": [
      {
        "eligibility": "everyone",
        "count": 156
      },
      {
        "eligibility": "low-income",
        "count": 98
      }
    ]
  }
}
```

---

## Response Headers

All successful responses include:
- `Content-Type: application/json`
- `Cache-Control: public, max-age=300` (5 minutes for most endpoints)
- `Cache-Control: public, max-age=3600` (1 hour for categories, areas, stats)

## Error Responses

### 404 Not Found
```json
{
  "error": "Program not found",
  "id": "invalid-id"
}
```

### 500 Internal Server Error
```json
{
  "error": "Failed to fetch programs",
  "message": "Detailed error message"
}
```

## Rate Limiting

Currently no rate limiting is enforced. The API runs on Azure Functions consumption plan with automatic scaling.

## CORS

The API allows requests from:
- `https://bayareadiscounts.com`
- `https://wonderful-coast-09041e01e.azurestaticapps.net`
- `http://localhost:4000` (for development)

## Testing

### Using curl
```bash
# Pretty print with jq
curl -s https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/categories | jq

# Check response time
curl -w "\nTime: %{time_total}s\n" https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs
```

### Using JavaScript
```javascript
// Fetch all programs
fetch('https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs')
  .then(res => res.json())
  .then(data => console.log(data.programs));

// Fetch filtered programs
fetch('https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs?category=Food')
  .then(res => res.json())
  .then(data => console.log(`Found ${data.count} food programs`));
```

## Performance

- **Average response time**: 100-300ms
- **Cold start**: 1-3 seconds (first request after idle)
- **Warm start**: 50-150ms
- **Database**: Azure Cosmos DB (serverless, auto-scaling)

## Monitoring

View API metrics in:
- **Azure Portal** → Function App → Monitor
- **Application Insights** → Performance
- **Instrumentation Key**: `5e69b212-4723-44d4-b23e-27da3f7cac8f`

## Future Endpoints (Planned)

- `POST /api/programs/suggest` - Submit program suggestions
- `GET /api/eligibility` - List eligibility types
- `GET /api/search/autocomplete` - Autocomplete suggestions
- `GET /api/similar/{id}` - Find similar programs

## Open Source

All API code is open source and available at:
https://github.com/baytides/bayareadiscounts

License: MIT (code) + CC BY 4.0 (data)

## Support

- **Issues**: https://github.com/baytides/bayareadiscounts/issues
- **Discussions**: https://github.com/baytides/bayareadiscounts/discussions

---

**Last Updated:** December 17, 2025
**API Version:** 1.0.0
**Status:** Production ✅
