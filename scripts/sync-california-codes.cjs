#!/usr/bin/env node
/**
 * Sync California State Codes Content
 *
 * Scrapes actual text content from California Legislature website for
 * commonly-asked-about code sections. This allows Carl to answer
 * specific legal questions with actual law text.
 *
 * Output: public/data/california-codes-content.json
 *
 * Usage:
 *   node scripts/sync-california-codes.cjs
 *   node scripts/sync-california-codes.cjs --verbose
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const OUTPUT_FILE = path.join(__dirname, '..', 'public', 'data', 'california-codes-content.json');
const VERBOSE = process.argv.includes('--verbose');

// High-value code sections that people commonly ask about
// Format: { code, sections: [{ num, title, keywords }] }
const SECTIONS_TO_SCRAPE = [
  // CIVIL CODE - Tenant Rights (most common questions)
  {
    code: 'CIV',
    name: 'Civil Code',
    sections: [
      { num: '1940', title: 'Application of tenant law', keywords: ['tenant', 'rental', 'lease'] },
      { num: '1940.2', title: 'Landlord entry requirements', keywords: ['landlord entry', 'notice', 'privacy'] },
      { num: '1941', title: 'Habitability requirements', keywords: ['habitability', 'repairs', 'livable'] },
      { num: '1941.1', title: 'Untenantable dwelling conditions', keywords: ['uninhabitable', 'conditions', 'repairs'] },
      { num: '1942', title: 'Tenant remedy for breach', keywords: ['repair', 'deduct', 'remedy'] },
      { num: '1942.4', title: 'Rent withholding for violations', keywords: ['rent withhold', 'habitability'] },
      { num: '1942.5', title: 'Retaliation prohibited', keywords: ['retaliation', 'eviction', 'complaint'] },
      { num: '1946', title: 'Notice to terminate tenancy', keywords: ['notice', 'terminate', 'end lease'] },
      { num: '1946.2', title: 'Just cause eviction', keywords: ['just cause', 'eviction', 'AB 1482'] },
      { num: '1947.12', title: 'Rent cap (AB 1482)', keywords: ['rent cap', 'rent increase', 'AB 1482'] },
      { num: '1950.5', title: 'Security deposit rules', keywords: ['security deposit', 'refund', 'deductions'] },
      { num: '1950.7', title: 'Last month rent as deposit', keywords: ['last month', 'deposit'] },
      { num: '1954', title: 'Landlord right of access', keywords: ['landlord access', 'entry', '24 hours'] },
    ],
  },
  // LABOR CODE - Employment (second most common)
  {
    code: 'LAB',
    name: 'Labor Code',
    sections: [
      { num: '201', title: 'Final wages - discharge', keywords: ['final paycheck', 'fired', 'terminated'] },
      { num: '202', title: 'Final wages - quit', keywords: ['final paycheck', 'quit', 'resignation'] },
      { num: '203', title: 'Penalty for late wages', keywords: ['waiting time penalty', 'late pay'] },
      { num: '226', title: 'Pay stub requirements', keywords: ['pay stub', 'itemized statement'] },
      { num: '246', title: 'Paid sick leave', keywords: ['sick leave', 'paid sick', 'illness'] },
      { num: '510', title: 'Overtime requirements', keywords: ['overtime', 'hours', 'time and half'] },
      { num: '512', title: 'Meal periods', keywords: ['meal break', 'lunch', '30 minutes'] },
      { num: '1194', title: 'Minimum wage recovery', keywords: ['minimum wage', 'underpaid'] },
      { num: '1197', title: 'Minimum wage requirement', keywords: ['minimum wage', 'hourly rate'] },
      { num: '2802', title: 'Expense reimbursement', keywords: ['expense', 'reimbursement', 'mileage'] },
    ],
  },
  // FAMILY CODE - Divorce/Custody (common family questions)
  {
    code: 'FAM',
    name: 'Family Code',
    sections: [
      { num: '2100', title: 'Disclosure requirements', keywords: ['divorce', 'disclosure', 'assets'] },
      { num: '3020', title: 'Best interest of child', keywords: ['child custody', 'best interest'] },
      { num: '3040', title: 'Custody order priorities', keywords: ['custody', 'parent', 'order'] },
      { num: '3100', title: 'Visitation rights', keywords: ['visitation', 'parenting time'] },
      { num: '4055', title: 'Child support calculation', keywords: ['child support', 'calculation', 'guideline'] },
    ],
  },
  // VEHICLE CODE - DMV/Traffic (common questions)
  {
    code: 'VEH',
    name: 'Vehicle Code',
    sections: [
      { num: '4000', title: 'Vehicle registration required', keywords: ['registration', 'register', 'dmv'] },
      { num: '12500', title: 'Driver license required', keywords: ['license', 'driving', 'unlicensed'] },
      { num: '14601', title: 'Driving on suspended license', keywords: ['suspended', 'license', 'driving'] },
      { num: '22350', title: 'Basic speed law', keywords: ['speed', 'speeding', 'safe'] },
      { num: '23152', title: 'DUI definition', keywords: ['dui', 'drunk driving', 'alcohol'] },
    ],
  },
  // UNEMPLOYMENT INSURANCE CODE - EDD/Benefits
  {
    code: 'UIC',
    name: 'Unemployment Insurance Code',
    sections: [
      { num: '1253', title: 'Eligibility for benefits', keywords: ['unemployment', 'eligible', 'qualify'] },
      { num: '1256', title: 'Disqualification - quit', keywords: ['quit', 'voluntary', 'disqualified'] },
      { num: '1257', title: 'Disqualification - misconduct', keywords: ['fired', 'misconduct', 'disqualified'] },
      { num: '2601', title: 'Disability insurance', keywords: ['disability', 'sdi', 'benefits'] },
      { num: '3301', title: 'Paid family leave', keywords: ['pfl', 'family leave', 'bonding'] },
    ],
  },
  // WELFARE AND INSTITUTIONS CODE - Benefits
  {
    code: 'WIC',
    name: 'Welfare and Institutions Code',
    sections: [
      { num: '11250', title: 'CalWORKs eligibility', keywords: ['calworks', 'tanf', 'cash aid'] },
      { num: '11450', title: 'CalWORKs grant amounts', keywords: ['calworks', 'grant', 'amount'] },
      { num: '18901', title: 'CalFresh (food stamps)', keywords: ['calfresh', 'food stamps', 'snap'] },
    ],
  },
];

// Base URL for California Legislature
const BASE_URL = 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml';

/**
 * Fetch a URL with timeout
 */
function fetchUrl(url, timeout = 15000) {
  return new Promise((resolve, reject) => {
    const req = https.get(
      url,
      {
        headers: {
          'User-Agent': 'BayNavigator/1.0 (California Codes Sync)',
          Accept: 'text/html',
        },
      },
      (res) => {
        if (res.statusCode !== 200) {
          reject(new Error(`HTTP ${res.statusCode}`));
          return;
        }

        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => resolve(data));
      }
    );

    req.on('error', reject);
    req.setTimeout(timeout, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

/**
 * Extract code section text from HTML
 */
function extractSectionText(html) {
  // Find content between <p> tags in the code section
  const paragraphs = [];
  const pRegex = /<p[^>]*>([\s\S]*?)<\/p>/gi;
  let match;

  while ((match = pRegex.exec(html)) !== null) {
    let text = match[1]
      // Remove HTML tags
      .replace(/<[^>]+>/g, '')
      // Decode HTML entities
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/&#\d+;/g, '')
      // Clean up whitespace
      .replace(/\s+/g, ' ')
      .trim();

    if (text.length > 10) {
      paragraphs.push(text);
    }
  }

  return paragraphs.join('\n\n');
}

/**
 * Scrape a single code section
 */
async function scrapeSection(code, sectionNum) {
  const url = `${BASE_URL}?lawCode=${code}&sectionNum=${sectionNum}`;

  try {
    const html = await fetchUrl(url);
    const text = extractSectionText(html);

    if (!text || text.length < 50) {
      return null;
    }

    return {
      code,
      section: sectionNum,
      url,
      text: text.substring(0, 5000), // Cap at 5000 chars per section
      scraped: new Date().toISOString(),
    };
  } catch (error) {
    if (VERBOSE) console.log(`    ⚠️ ${code} ${sectionNum}: ${error.message}`);
    return null;
  }
}

/**
 * Main sync function
 */
async function syncCaliforniaCodes() {
  console.log('🔄 Syncing California state codes content...\n');

  const cache = {
    generated: new Date().toISOString(),
    source: 'California Legislature (leginfo.legislature.ca.gov)',
    description:
      'Actual text content from California state codes for commonly-asked legal questions',
    codes: {},
    sections: [],
    byKeyword: {},
  };

  let successCount = 0;
  let failCount = 0;

  for (const codeGroup of SECTIONS_TO_SCRAPE) {
    console.log(`  📚 ${codeGroup.name} (${codeGroup.code})`);

    cache.codes[codeGroup.code] = {
      name: codeGroup.name,
      sections: [],
    };

    for (const section of codeGroup.sections) {
      if (VERBOSE) console.log(`    Fetching ${codeGroup.code} §${section.num}...`);

      const result = await scrapeSection(codeGroup.code, section.num);

      if (result) {
        const sectionData = {
          ...result,
          title: section.title,
          keywords: section.keywords,
        };

        cache.sections.push(sectionData);
        cache.codes[codeGroup.code].sections.push(sectionData);

        // Index by keywords
        for (const keyword of section.keywords) {
          const kw = keyword.toLowerCase();
          if (!cache.byKeyword[kw]) cache.byKeyword[kw] = [];
          cache.byKeyword[kw].push({
            code: codeGroup.code,
            section: section.num,
            title: section.title,
          });
        }

        console.log(`    ✅ §${section.num}: ${section.title} (${result.text.length} chars)`);
        successCount++;
      } else {
        console.log(`    ❌ §${section.num}: ${section.title}`);
        failCount++;
      }

      // Be nice to the server
      await new Promise((r) => setTimeout(r, 500));
    }
  }

  // Calculate totals
  cache.totals = {
    codes: Object.keys(cache.codes).length,
    sections: cache.sections.length,
    keywords: Object.keys(cache.byKeyword).length,
    totalChars: cache.sections.reduce((sum, s) => sum + s.text.length, 0),
  };

  // Ensure output directory exists
  const outputDir = path.dirname(OUTPUT_FILE);
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  // Write cache file
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(cache, null, 2));

  const fileSizeKB = Math.round(fs.statSync(OUTPUT_FILE).size / 1024);

  console.log(`
📊 Sync Complete
   Sections scraped: ${successCount} succeeded, ${failCount} failed
   Total codes: ${cache.totals.codes}
   Total sections: ${cache.totals.sections}
   Total keywords indexed: ${cache.totals.keywords}
   Content size: ${Math.round(cache.totals.totalChars / 1024)} KB of legal text
   File size: ${fileSizeKB} KB
   Output: ${OUTPUT_FILE}
`);

  return { successCount, failCount };
}

// Run if called directly
if (require.main === module) {
  syncCaliforniaCodes()
    .then(({ failCount }) => {
      process.exit(failCount > 10 ? 1 : 0);
    })
    .catch((error) => {
      console.error('Fatal error:', error);
      process.exit(1);
    });
}

module.exports = { syncCaliforniaCodes };
