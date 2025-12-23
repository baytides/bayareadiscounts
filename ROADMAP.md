# Bay Area Discounts - Project Roadmap

## Current State Summary

**Version:** 1.0.0
**Last Updated:** December 23, 2025
**Status:** Production (Azure Static Web Apps)

### Architecture Overview
- **Frontend:** Jekyll static site with vanilla JavaScript
- **API:** Static JSON files generated from YAML program data
- **Hosting:** Azure Static Web Apps with global CDN
- **Data:** 237+ programs across 14 categories

---

## Completed Cleanup (December 2025)

### Documentation Updates
- [x] Updated README.md to reflect static JSON API (removed Azure Functions references)
- [x] Updated API_ENDPOINTS.md with correct static API documentation
- [x] Updated OpenAPI spec (openapi/bayareadiscounts-api.yaml)
- [x] Fixed translation.js endpoint (disabled deprecated Azure Functions endpoint)

### Technical Debt Addressed
- [x] Removed references to deprecated Azure Functions
- [x] Confirmed no duplicate source files in codebase (duplicates only in node_modules)
- [x] Verified .gitignore properly excludes duplicate files

---

## Phase 1: Immediate Refinements (Next 1-2 Weeks)

### Documentation Cleanup (Priority: High)
The following documentation files still contain outdated Azure Functions references and should be updated or archived:

1. **docs/AZURE_QUICK_REFERENCE.md** - References deprecated Functions endpoint
2. **docs/DEPLOYMENT_STATUS.md** - Contains old Functions URL
3. **docs/GETTING_STARTED_AZURE.md** - Describes Functions setup that no longer exists
4. **docs/AZURE_TRANSLATOR_SETUP.md** - Translation API was disabled
5. **docs/AZURE_TRANSLATOR_GUIDE.md** - Translation API documentation (archive)
6. **API-DOCUMENTATION.md** - Root level duplicate (consolidate with docs/)

**Recommended Action:** Create a `/docs/archive/` folder and move deprecated Azure Functions documentation there, or update to reflect the static JSON API approach.

### Code Quality (Priority: Medium)
- [ ] Add JSDoc comments to key JavaScript functions
- [ ] Add error boundary handling in step-flow.js
- [ ] Improve localStorage error handling (Safari private mode)

### Testing (Priority: Medium)
- [ ] Verify Playwright tests pass with current codebase
- [ ] Add test for API file generation script
- [ ] Add accessibility regression tests

---

## Phase 2: Feature Enhancements (1-3 Months)

### Search & Discovery
- [ ] **Fuzzy search** - Improve search to handle typos and partial matches
- [ ] **Search suggestions** - Auto-complete based on program names
- [ ] **Recent searches** - Store in localStorage for quick access
- [ ] **Saved searches** - Allow users to save filter combinations

### User Experience
- [ ] **Program comparison** - Side-by-side view of 2-3 programs
- [ ] **Print-friendly view** - Optimized print stylesheet for programs
- [ ] **Share functionality** - Generate shareable links with pre-applied filters
- [ ] **QR codes** - For offline access to program information

### Data & Content
- [ ] **Program verification system** - Track last verified date, highlight stale data
- [ ] **Community submissions** - GitHub Issue template for new program suggestions
- [ ] **Program ratings/feedback** - Simple thumbs up/down for usefulness
- [ ] **Multi-language support** - Translate UI and program descriptions

### Performance
- [ ] **Image optimization pipeline** - Compress and serve WebP images
- [ ] **Critical CSS extraction** - Inline above-the-fold styles
- [ ] **Preload key resources** - Add resource hints for faster loading

---

## Phase 3: Platform Expansion (3-6 Months)

### Mobile App
- [ ] **React Native app** using the static JSON API
- [ ] **Offline-first architecture** with local data caching
- [ ] **Push notifications** for new programs or deadline reminders
- [ ] **iOS and Android** distribution

### API Enhancements
- [ ] **GraphQL endpoint** - For more flexible data queries
- [ ] **Webhook notifications** - Notify subscribers when programs change
- [ ] **RSS/Atom feed** - For program updates

### Community Features
- [ ] **Program reviews** - Community feedback on program experiences
- [ ] **Success stories** - Anonymous testimonials
- [ ] **FAQ section** - Common questions about programs

---

## Azure Recommendations

### Current Azure Resources
You have Azure CLI access (v2.81.0) and an existing Static Web App deployment.

**Current Resource:**
```
Name: baytides-discounts-app
Location: West US 2
URL: blue-pebble-00a40d41e.4.azurestaticapps.net
Resource Group: baytides-discounts-rg
```

### Recommended Azure Services (If Needed)

#### 1. Azure CDN / Front Door (Optional)
**Use case:** Custom domain with advanced caching and WAF
**Cost:** ~$20-50/month
**When to add:** If you need:
- Custom caching rules per endpoint
- Web Application Firewall (WAF) protection
- Geographic load balancing
- Custom SSL certificates

```bash
# Check current CDN status
az cdn profile list --resource-group baytides-discounts-rg
```

#### 2. Azure Application Insights (Recommended)
**Use case:** Real-time monitoring and analytics
**Cost:** Free tier available (5GB/month)
**When to add:** Now - for production monitoring

```bash
# Create Application Insights resource
az monitor app-insights component create \
  --app bayareadiscounts-insights \
  --location westus2 \
  --resource-group baytides-discounts-rg \
  --kind web
```

#### 3. Azure Key Vault (If Adding Secrets)
**Use case:** Securely store API keys or credentials
**Cost:** ~$0.03/10,000 operations
**When to add:** If you add third-party integrations

#### 4. Azure Communication Services (Optional)
**Use case:** Email notifications or SMS alerts
**Cost:** Pay-per-use (~$0.00025/email)
**When to add:** If you want email notifications for new programs

### NOT Recommended (For This Project)

- **Azure Functions:** Already migrated away - static JSON is simpler and free
- **Azure Cosmos DB:** Overkill for static data - YAML/JSON is sufficient
- **Azure Redis Cache:** Only needed if you have dynamic API caching needs
- **Azure API Management:** Only for complex API scenarios with authentication

---

## Infrastructure Recommendations

### Keep as Static (Recommended)
The current static site + static JSON API architecture is ideal because:
1. **Zero operational cost** - No Functions compute charges
2. **Global CDN caching** - Fast worldwide response times
3. **No cold starts** - Static files are always ready
4. **Simple deployment** - Push to GitHub, auto-deploy
5. **Easy maintenance** - No runtime dependencies

### Consider Adding

#### GitHub Actions Improvements
- [ ] Add caching for npm and bundle dependencies
- [ ] Run Playwright tests on PR
- [ ] Deploy preview environments for PRs

#### Monitoring
- [ ] Add uptime monitoring (UptimeRobot, Better Uptime, or Azure)
- [ ] Set up Slack/Discord alerts for deployment failures
- [ ] Add performance budgets in CI

---

## Security Enhancements

### Current Security Posture
- [x] CSP headers configured
- [x] HTTPS only
- [x] No cookies
- [x] No user authentication
- [x] No PII collection

### Recommended Additions
- [ ] Add Subresource Integrity (SRI) for external scripts
- [ ] Implement security.txt file
- [ ] Add HSTS preload
- [ ] Regular dependency audits (`npm audit`)

---

## Data Management

### Current Workflow
1. Edit YAML files in `_data/programs/`
2. Run `node scripts/generate-api.js`
3. Commit changes
4. GitHub Actions deploys automatically

### Recommended Improvements
- [ ] Add YAML validation in pre-commit hook
- [ ] Create program data schema (JSON Schema)
- [ ] Add verified_date tracking automation
- [ ] Create data quality dashboard

---

## Metrics to Track

### Engagement
- Page views (via Plausible)
- Search queries used
- Most viewed categories
- Filter usage patterns

### Technical
- API response times
- Cache hit rates
- Error rates
- Lighthouse scores

### Community
- GitHub stars and forks
- Issues and PRs
- Program submissions

---

## Timeline Summary

| Phase | Timeframe | Focus |
|-------|-----------|-------|
| 1 | Now - 2 weeks | Documentation cleanup, testing |
| 2 | 1-3 months | Search improvements, UX enhancements |
| 3 | 3-6 months | Mobile app, API expansion |

---

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines on:
- Adding new programs
- Submitting code changes
- Reporting bugs
- Suggesting features

---

**Maintained by:** Bay Area Discounts Community
**License:** MIT (code) + CC BY 4.0 (data)
