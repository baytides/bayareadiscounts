# Bay Area Discounts - Program Data

This directory contains all program data for BayAreaDiscounts.com.

## 🔄 YAML + Cosmos DB Architecture

**These YAML files serve multiple purposes:**
1. **Version Control** - Track all program changes via Git history
2. **Backup** - Redundant copy of data stored in Azure Cosmos DB
3. **Open Source** - Anyone can view and download the complete dataset
4. **Easy Contributions** - Submit PRs to update programs
5. **Migration Source** - Can re-sync to Cosmos DB anytime

**The live website uses Azure Cosmos DB via API, not these YAML files directly.**

To sync YAML changes to the database, run:
```bash
cd scripts
npm install
npm run migrate
```

See [AZURE_INTEGRATION.md](../../docs/AZURE_INTEGRATION.md) for details.

## License

All data files in this directory are licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**.

**You are free to:**
- Share and redistribute the data in any format
- Adapt, remix, and build upon the data (even commercially)

**You must:**
- Give appropriate credit to Bay Area Discounts
- Provide a link to the license: https://creativecommons.org/licenses/by/4.0/
- Indicate if changes were made

## Attribution

When using this data, please use one of these attribution formats:

**For unmodified use:**
```
Program data from Bay Area Discounts (https://bayareadiscounts.com)
licensed under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)
```

**For modified/derivative works:**
```
Based on data from Bay Area Discounts (https://bayareadiscounts.com),
modified by [Your Name]. Original data licensed under CC BY 4.0.
```

**For apps or websites:**
Include attribution in your credits/about page or footer.

## Data Structure

Each YAML file contains programs organized by category. Programs follow this structure:

```yaml
- id: "unique-program-id"
  name: "Program Name"
  category: "Category Name"
  area: "Geographic Area"
  eligibility:
    - "💳"  # SNAP/EBT/Medi-Cal
    - "👵"  # Seniors
  benefit: "Description of what the program provides"
  timeframe: "Ongoing"
  link: "https://official-website.com"
  link_text: "Apply"
```

## Contributing

To add or update programs:
1. Fork this repository
2. Edit the appropriate YAML file in this directory
3. Submit a pull request

Or simply [open an issue](https://github.com/baytides/bayareadiscounts/issues/new) with program details.

## Data Accuracy

This is a community-maintained dataset. While we verify programs periodically:
- Always check official websites for current information
- Availability and eligibility can change
- Report outdated information via [GitHub issues](https://github.com/baytides/bayareadiscounts/issues/new)

---

**Full license:** [LICENSE-DATA](../../LICENSE-DATA)
**Project homepage:** [BayAreaDiscounts.com](https://bayareadiscounts.com)
**GitHub repository:** [github.com/baytides/bayareadiscounts](https://github.com/baytides/bayareadiscounts)
