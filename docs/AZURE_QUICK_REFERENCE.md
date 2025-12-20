# Quick Reference: Azure Services

## 🚀 Service Endpoints

### Public URLs
- **Website (Static Web App)**: https://wonderful-coast-09041e01e.2.azurestaticapps.net
- **CDN (Front Door)**: https://bayareadiscounts-web-b9gzhvbpdedgc2hn.z02.azurefd.net
- **API Gateway**: https://bayareadiscounts-api.azure-api.net
- **Functions (Direct)**: https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api

### API Endpoints (via API Management)
```bash
GET https://bayareadiscounts-api.azure-api.net/programs
GET https://bayareadiscounts-api.azure-api.net/programs/{id}
GET https://bayareadiscounts-api.azure-api.net/categories
GET https://bayareadiscounts-api.azure-api.net/areas
GET https://bayareadiscounts-api.azure-api.net/stats
POST https://bayareadiscounts-api.azure-api.net/translate
```

---

## 📊 Monitoring Dashboards

### Application Insights
```bash
# View in Azure Portal
https://portal.azure.com/#@/resource/subscriptions/7848d90a-1826-43f6-a54e-090c2d18946f/resourceGroups/bayareadiscounts-rg/providers/microsoft.insights/components/bayareadiscounts-insights-prod

# Quick metrics query
az monitor app-insights metrics show \
  --app bayareadiscounts-insights-prod \
  --resource-group bayareadiscounts-rg \
  --metric 'requests/count'
```

### Cache Performance
```bash
# Check Redis cache hit rate (once configured)
az monitor metrics list \
  --resource /subscriptions/7848d90a-1826-43f6-a54e-090c2d18946f/resourceGroups/bayareadiscounts-rg/providers/Microsoft.Cache/Redis/bayareadiscounts-redis \
  --metric "cacheHits,cacheMisses"
```

---

## 🔧 Common Commands

### Check Service Status
```bash
# All services at once
az resource list \
  --resource-group bayareadiscounts-rg \
  --query "[].{Name:name, Type:type, Status:provisioningState}" \
  --output table

# Redis status (until ready)
az redis show \
  --name bayareadiscounts-redis \
  --resource-group bayareadiscounts-rg \
  --query "{status: provisioningState, host: hostName}"

# API Management status
az apim show \
  --name bayareadiscounts-api \
  --resource-group bayareadiscounts-rg \
  --query "{status: provisioningState, gateway: gatewayUrl}"
```

### Configure Redis (When Ready)
```bash
# 1. Get access keys
az redis list-keys \
  --name bayareadiscounts-redis \
  --resource-group bayareadiscounts-rg

# 2. Set Functions app settings
az functionapp config appsettings set \
  --name bayareadiscounts-func-prod-clx32fwtnzehq \
  --resource-group bayareadiscounts-rg \
  --settings \
    REDIS_HOST="bayareadiscounts-redis.redis.cache.windows.net" \
    REDIS_KEY="<primary-key-from-step-1>"

# 3. Restart Functions app
az functionapp restart \
  --name bayareadiscounts-func-prod-clx32fwtnzehq \
  --resource-group bayareadiscounts-rg
```

### View Logs
```bash
# Functions logs (live tail)
az functionapp log tail \
  --name bayareadiscounts-func-prod-clx32fwtnzehq \
  --resource-group bayareadiscounts-rg

# Application Insights recent errors
az monitor app-insights query \
  --app bayareadiscounts-insights-prod \
  --analytics-query "exceptions | where timestamp > ago(1h) | order by timestamp desc | take 20"

# Functions metrics
az monitor app-insights query \
  --app bayareadiscounts-insights-prod \
  --analytics-query "customMetrics | where name contains 'Programs' | where timestamp > ago(1h)"
```

### Test API Endpoints
```bash
# Test through API Management
curl https://bayareadiscounts-api.azure-api.net/programs?category=food

# Test Front Door
curl -I https://bayareadiscounts-web-b9gzhvbpdedgc2hn.z02.azurefd.net

# Check cache headers
curl -I https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs
# Look for: X-Cache: HIT or MISS
```

---

## 💡 Troubleshooting

### Redis Not Connecting
```bash
# 1. Verify Redis is ready
az redis show --name bayareadiscounts-redis --resource-group bayareadiscounts-rg

# 2. Test connection
redis-cli -h bayareadiscounts-redis.redis.cache.windows.net -p 6380 -a "<access-key>" --tls ping

# 3. Check Functions app settings
az functionapp config appsettings list \
  --name bayareadiscounts-func-prod-clx32fwtnzehq \
  --resource-group bayareadiscounts-rg \
  | grep -E "REDIS_HOST|REDIS_KEY"
```

### API Management Not Responding
```bash
# Check API status
az apim api show \
  --resource-group bayareadiscounts-rg \
  --service-name bayareadiscounts-api \
  --api-id bayareadiscounts-functions

# List operations
az apim api operation list \
  --resource-group bayareadiscounts-rg \
  --service-name bayareadiscounts-api \
  --api-id bayareadiscounts-functions
```

### Front Door Not Routing
```bash
# Check health probe
az afd origin show \
  --resource-group bayareadiscounts-rg \
  --profile-name bayareadiscounts-fd \
  --origin-group-name website-origins \
  --origin-name static-web-app

# Check route
az afd route show \
  --resource-group bayareadiscounts-rg \
  --profile-name bayareadiscounts-fd \
  --endpoint-name bayareadiscounts-web \
  --route-name default-route
```

### High Costs Alert
```bash
# Check current month costs
az consumption usage list \
  --start-date $(date -u -v-1d '+%Y-%m-%d') \
  --end-date $(date -u '+%Y-%m-%d') \
  | jq '[.[] | {date: .date, cost: .pretaxCost, service: .meterDetails.meterName}]'

# Set budget alert (if not set)
az consumption budget create \
  --budget-name monthly-budget \
  --amount 100 \
  --time-grain monthly \
  --category cost
```

---

## 📈 Performance Optimization

### Cache Hit Rate Goal: >70%
```bash
# Monitor cache metrics
az monitor metrics list \
  --resource bayareadiscounts-redis \
  --resource-group bayareadiscounts-rg \
  --resource-type Microsoft.Cache/Redis \
  --metric "cacheHitRate"
```

### Cosmos DB RU Optimization
```bash
# Check RU consumption
az cosmosdb mongodb collection throughput show \
  --account-name bayareadiscounts-cosmos-prod-clx32fwtnzehq \
  --database-name bayareadiscounts \
  --name programs \
  --resource-group bayareadiscounts-rg
```

---

## 🔐 Security Checklist

- ✅ Managed Identity for Functions ↔ Cosmos DB
- ✅ Managed Identity for Functions ↔ Key Vault
- ✅ HTTPS redirect on Front Door
- ✅ CORS configured in API Management
- ✅ Redis requires TLS 1.2+
- ✅ Key Vault RBAC enabled
- ⏸️ Custom domain SSL (pending)
- ⏸️ API Management rate limiting (requires Standard tier)

---

## 🎯 Next Actions

1. **Wait for Redis (~5-10 more minutes)**
   ```bash
   watch -n 30 'az redis show --name bayareadiscounts-redis --resource-group bayareadiscounts-rg --query provisioningState'
   ```

2. **Configure Redis connection** (see "Configure Redis" above)

3. **Test cache performance**
   ```bash
   # First request (should be MISS)
   curl -I https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs
   
   # Second request (should be HIT)
   curl -I https://bayareadiscounts-func-prod-clx32fwtnzehq.azurewebsites.net/api/programs
   ```

4. **Set up custom domain** (optional)
   - Point bayareadiscounts.com DNS to Front Door
   - Configure SSL certificate

---

*For detailed information, see [AZURE_SERVICES_GUIDE.md](AZURE_SERVICES_GUIDE.md)*
