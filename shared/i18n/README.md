# Bay Navigator Translations

This directory contains internationalization (i18n) files for Bay Navigator.

## Structure

```
shared/i18n/
├── json/                    # JSON files for cross-platform use
│   ├── en-ui.json          # English UI strings
│   ├── en-programs.json    # English program data
│   ├── es-ui.json          # Spanish UI strings
│   ├── es-programs.json    # Spanish program data
│   └── ...                 # Other languages
├── en.ts                   # English TypeScript module
├── es.ts                   # Spanish TypeScript module
├── zh-Hans.ts              # Chinese (Simplified) module
├── zh-Hant.ts              # Chinese (Traditional) module
├── vi.ts                   # Vietnamese module
├── fil.ts                  # Filipino module
├── ko.ts                   # Korean module
├── ru.ts                   # Russian module
├── fr.ts                   # French module
├── ar.ts                   # Arabic module
├── types.ts                # TypeScript type definitions
├── index.ts                # Main entry point
└── README.md               # This file
```

## Supported Languages

| Code    | Language              | Native Name |
| ------- | --------------------- | ----------- |
| en      | English               | English     |
| es      | Spanish               | Español     |
| zh-Hans | Chinese (Simplified)  | 简体中文    |
| zh-Hant | Chinese (Traditional) | 繁體中文    |
| vi      | Vietnamese            | Tiếng Việt  |
| fil     | Filipino              | Filipino    |
| ko      | Korean                | 한국어      |
| ru      | Russian               | Русский     |
| fr      | French                | Français    |
| ar      | Arabic                | العربية     |

## How Translations Work

1. **Source of Truth**: `src/i18n/en.json` contains all UI strings in English
2. **Program Data**: YAML files in `src/data/*.yml` contain program information
3. **Auto-Translation**: Azure Translator API generates translations automatically
4. **CI/CD**: GitHub Actions workflow runs when source files change

## Usage

### Web (Astro/TypeScript)

```typescript
import { loadTranslations, t, getProgramTranslation } from '@/shared/i18n';

// Load translations for a locale
const { ui, programs } = await loadTranslations('es');

// Translate UI strings
const searchText = t('common.search', ui); // "Buscar"

// Translate program data with fallback
const programName = getProgramTranslation(
  'alameda-food-bank',
  'name',
  programs,
  'Alameda County Community Food Bank' // English fallback
);
```

### Flutter/Dart

```dart
// Load JSON directly
final uiJson = await rootBundle.loadString('shared/i18n/json/es-ui.json');
final programsJson = await rootBundle.loadString('shared/i18n/json/es-programs.json');

final ui = jsonDecode(uiJson);
final programs = jsonDecode(programsJson);
```

### Other Platforms

Use the JSON files in `shared/i18n/json/` for any platform:

- `{locale}-ui.json` - UI strings
- `{locale}-programs.json` - Program data

## Adding/Updating Translations

1. Edit `src/i18n/en.json` for UI strings
2. Edit `src/data/*.yml` for program data
3. Push changes to `main` branch
4. GitHub Actions will automatically translate and commit

To force re-translation of all strings:

- Go to Actions > "Translate i18n Files"
- Click "Run workflow"
- Check "Force re-translate all strings"

## Manual Translation

Run locally (requires Azure Translator API key):

```bash
AZURE_TRANSLATOR_KEY=xxx node scripts/translate-i18n.cjs
```

## Files Not to Edit

**DO NOT manually edit these files** - they are auto-generated:

- `*.ts` files (except for review)
- `json/*.json` files
- `.i18n-hashes.json` (translation cache)

Only edit `src/i18n/en.json` for UI strings.
