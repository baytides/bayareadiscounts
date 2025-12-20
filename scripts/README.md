# Scripts

Utility scripts for maintaining Bay Area Discounts.

## migrate-to-cosmos.js

**Purpose:** Migrates all program data from YAML files to Azure Cosmos DB.

**Usage:**
```bash
cd scripts
npm install

# Set environment variables
export COSMOS_DB_ENDPOINT="https://your-cosmos.documents.azure.com:443/"
export COSMOS_DB_KEY="your-key"
export COSMOS_DB_DATABASE_NAME="bayareadiscounts"
export COSMOS_DB_CONTAINER_NAME="programs"

# Run migration
npm run migrate
```

**When to use:**
- After merging PRs that update YAML files
- After fixing data issues in YAML
- When re-deploying infrastructure
- Initial data load

**Features:**
- ✅ Reads all YAML files in `_data/programs/`
- ✅ Upserts data (safe to run multiple times)
- ✅ Progress tracking
- ✅ Error reporting
- ✅ Validates Cosmos DB connection first

**Output:**
```
🚀 Starting migration: YAML → Cosmos DB
📁 Found 13 YAML files
📤 Uploading 237 programs to Cosmos DB...
✅ Upload complete!
```

See [AZURE_INTEGRATION.md](../docs/AZURE_INTEGRATION.md) for complete details.

---

## ../add_verification_dates.py

**Purpose:** Bulk add or update `verified_date` field in YAML files.

**Usage:**
```bash
# From repo root
python3 add_verification_dates.py
```

**When to use:**
- After bulk verification of programs
- When updating verification dates for all programs
- Data cleanup tasks

**Note:** This modifies YAML files directly. After running, you'll need to:
1. Review changes with `git diff`
2. Commit changes
3. Run migration to sync to Cosmos DB

---

## License

These scripts are part of Bay Area Discounts and licensed under MIT.
See [LICENSE](../LICENSE) for details.
