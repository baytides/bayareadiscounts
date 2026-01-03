#!/usr/bin/env node

/**
 * IMLS Museum Directory Sync Script
 *
 * Extracts Bay Area museums from the IMLS Museum Directory dataset.
 * Source: https://www.kaggle.com/datasets/imls/museum-directory
 *
 * Note: This dataset is from 2014 and may contain outdated information.
 * Museums should be verified before display.
 *
 * Usage: node scripts/sync-imls-museums.cjs
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Bay Area cities (comprehensive list)
const BAY_AREA_CITIES = new Set([
  // San Francisco
  'san francisco',
  // San Mateo County
  'daly city', 'san mateo', 'redwood city', 'menlo park', 'palo alto', 'pacifica',
  'foster city', 'burlingame', 'san bruno', 'south san francisco', 'half moon bay',
  'belmont', 'san carlos', 'hillsborough', 'atherton', 'woodside', 'portola valley',
  'east palo alto', 'millbrae', 'brisbane', 'colma', 'moss beach', 'montara',
  // Santa Clara County
  'san jose', 'santa clara', 'sunnyvale', 'mountain view', 'cupertino', 'milpitas',
  'los gatos', 'campbell', 'saratoga', 'gilroy', 'morgan hill', 'los altos',
  'los altos hills', 'monte sereno', 'stanford',
  // Alameda County
  'oakland', 'berkeley', 'fremont', 'hayward', 'san leandro', 'alameda', 'livermore',
  'pleasanton', 'dublin', 'union city', 'newark', 'emeryville', 'albany', 'piedmont',
  'castro valley', 'san lorenzo',
  // Contra Costa County
  'richmond', 'concord', 'walnut creek', 'antioch', 'pittsburg', 'brentwood',
  'danville', 'san ramon', 'martinez', 'pleasant hill', 'el cerrito', 'orinda',
  'lafayette', 'moraga', 'hercules', 'pinole', 'el sobrante', 'clayton',
  // Marin County
  'san rafael', 'novato', 'sausalito', 'mill valley', 'tiburon', 'corte madera',
  'larkspur', 'san anselmo', 'fairfax', 'ross', 'belvedere', 'stinson beach',
  'bolinas', 'point reyes station',
  // Sonoma County
  'santa rosa', 'petaluma', 'rohnert park', 'windsor', 'healdsburg', 'sonoma',
  'sebastopol', 'cotati', 'cloverdale', 'bodega bay', 'guerneville', 'glen ellen',
  // Napa County
  'napa', 'american canyon', 'st helena', 'calistoga', 'yountville',
  // Solano County
  'vallejo', 'fairfield', 'vacaville', 'benicia', 'suisun city', 'dixon', 'rio vista'
]);

// Map IMLS museum types to our categories
function getCategory(type) {
  const typeMap = {
    'ART MUSEUM': 'Museums',
    'CHILDREN\'S MUSEUM': 'Museums',
    'GENERAL MUSEUM': 'Museums',
    'HISTORY MUSEUM': 'Museums',
    'NATURAL HISTORY MUSEUM': 'Museums',
    'SCIENCE & TECHNOLOGY MUSEUM OR PLANETARIUM': 'Museums',
    'ZOO, AQUARIUM, OR WILDLIFE CONSERVATION': 'Recreation',
    'ARBORETUM, BOTANICAL GARDEN, OR NATURE CENTER': 'Parks & Open Space',
    'HISTORIC PRESERVATION': 'Museums'
  };
  return typeMap[type] || 'Museums';
}

// Create a description based on museum type
function getDescription(type, name) {
  const descriptions = {
    'ART MUSEUM': 'Art museum featuring collections and exhibitions.',
    'CHILDREN\'S MUSEUM': 'Interactive museum designed for children and families with hands-on exhibits.',
    'GENERAL MUSEUM': 'Museum with diverse collections and exhibits.',
    'HISTORY MUSEUM': 'Museum dedicated to preserving and presenting local and regional history.',
    'NATURAL HISTORY MUSEUM': 'Museum featuring natural history exhibits including geology, biology, and paleontology.',
    'SCIENCE & TECHNOLOGY MUSEUM OR PLANETARIUM': 'Science and technology museum with interactive exhibits and educational programs.',
    'ZOO, AQUARIUM, OR WILDLIFE CONSERVATION': 'Wildlife facility dedicated to animal conservation and education.',
    'ARBORETUM, BOTANICAL GARDEN, OR NATURE CENTER': 'Botanical garden or nature center featuring plants and natural habitats.',
    'HISTORIC PRESERVATION': 'Historic site or organization dedicated to preserving local heritage.'
  };
  return descriptions[type] || 'Cultural institution serving the community.';
}

// Format phone number
function formatPhone(phone) {
  if (!phone) return null;
  const digits = phone.replace(/\D/g, '');
  if (digits.length === 10) {
    return `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}`;
  }
  return phone;
}

// Create slug from name
function createSlug(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 50);
}

// Normalize name for matching
function normalizeName(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '')
    .replace(/museum|the|of|and|art|san|francisco|oakland|california|bay|area/g, '');
}

// Find matching existing entry
function findMatchingEntry(imlsMuseum, existingEntries) {
  const imlsNorm = normalizeName(imlsMuseum.name);

  for (const entry of existingEntries) {
    // Skip entries that are already synced from IMLS
    if (entry.sync_source === 'imls-museums') continue;

    // Check if category is Museums or related
    if (entry.category !== 'Museums') continue;

    const entryNorm = normalizeName(entry.name);

    // Exact normalized match
    if (imlsNorm === entryNorm) return entry;

    // One contains the other (for partial matches like "Asian Art Museum" vs "Asian Art Museum of San Francisco")
    if (imlsNorm.includes(entryNorm) || entryNorm.includes(imlsNorm)) {
      // Make sure it's a substantial match (at least 5 chars matching)
      if (Math.min(imlsNorm.length, entryNorm.length) >= 5) {
        return entry;
      }
    }
  }

  return null;
}

// Parse CSV properly (handle quoted fields)
function parseCSVLine(line) {
  const row = [];
  let current = '';
  let inQuotes = false;

  for (const char of line) {
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      row.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }
  row.push(current.trim());
  return row;
}

async function main() {
  const csvPath = path.join(__dirname, '../data-exports/gov-datasets/museums.csv');
  const recreationPath = path.join(__dirname, '../src/data/recreation.yml');

  // Check if CSV exists
  if (!fs.existsSync(csvPath)) {
    console.error('Museum CSV not found. Please download from Kaggle first.');
    console.error('Run: kaggle datasets download imls/museum-directory -p data-exports/gov-datasets/ --unzip');
    process.exit(1);
  }

  // Read and parse CSV
  const csv = fs.readFileSync(csvPath, 'utf-8');
  const lines = csv.split('\n');

  // Filter Bay Area museums
  const bayAreaMuseums = [];

  for (let i = 1; i < lines.length; i++) {
    if (!lines[i].trim()) continue;

    const row = parseCSVLine(lines[i]);
    const state = row[12]; // State (Physical Location)
    const city = row[11]; // City (Physical Location)

    if (state === 'CA' && city && BAY_AREA_CITIES.has(city.toLowerCase())) {
      bayAreaMuseums.push({
        museumId: row[0],
        name: row[1],
        legalName: row[2],
        alternateName: row[3],
        type: row[4],
        address: row[10],
        city: row[11],
        state: row[12],
        zip: row[13],
        phone: row[14],
        lat: row[15],
        lng: row[16]
      });
    }
  }

  console.log(`Found ${bayAreaMuseums.length} Bay Area museums in IMLS dataset`);

  // Read existing recreation.yml
  const existingContent = fs.readFileSync(recreationPath, 'utf-8');
  const existingData = yaml.load(existingContent);

  // Track stats
  let merged = 0;
  let added = 0;
  let skipped = 0;
  const matchedIds = new Set();

  // Process each IMLS museum
  const newEntries = [];

  for (const museum of bayAreaMuseums) {
    // Try to find matching existing entry
    const existingEntry = findMatchingEntry(museum, existingData);

    if (existingEntry) {
      // Merge: enhance existing entry with IMLS data (only add missing fields)
      matchedIds.add(existingEntry.id);

      // Add city if missing
      if (!existingEntry.city && museum.city) {
        existingEntry.city = museum.city;
      }

      // Add address if missing
      if (!existingEntry.address && museum.address && museum.address !== '0') {
        existingEntry.address = museum.address;
      }

      // Add map_link if missing and we have coordinates
      if (!existingEntry.map_link && museum.lat && museum.lng && museum.lat !== '0' && museum.lng !== '0') {
        existingEntry.map_link = `https://www.google.com/maps?q=${museum.lat},${museum.lng}`;
      }

      // Add phone if missing
      if (!existingEntry.phone && museum.phone) {
        const phone = formatPhone(museum.phone);
        if (phone) {
          existingEntry.phone = phone;
        }
      }

      // Mark that we've enhanced this from IMLS
      if (!existingEntry.imls_id) {
        existingEntry.imls_id = museum.museumId;
      }

      console.log(`  Merged: ${museum.name} -> ${existingEntry.name}`);
      merged++;
    } else {
      // Check if this is a "Historic Preservation" type - these are often societies, not museums
      if (museum.type === 'HISTORIC PRESERVATION') {
        skipped++;
        continue;
      }

      // New entry
      const slug = createSlug(museum.name);
      const entry = {
        id: `imls-${slug}`,
        name: museum.name,
        category: getCategory(museum.type),
        area: 'Bay Area',
        city: museum.city,
        sync_source: 'imls-museums',
        imls_id: museum.museumId,
        description: getDescription(museum.type, museum.name),
        verified: false // Dataset is from 2014, needs verification
      };

      // Add address if available
      if (museum.address && museum.address !== '0') {
        entry.address = museum.address;
      }

      // Add map link if coordinates available
      if (museum.lat && museum.lng && museum.lat !== '0' && museum.lng !== '0') {
        entry.map_link = `https://www.google.com/maps?q=${museum.lat},${museum.lng}`;
      }

      // Add phone if available
      const phone = formatPhone(museum.phone);
      if (phone) {
        entry.phone = phone;
      }

      newEntries.push(entry);
      added++;
    }
  }

  // Remove old IMLS-only entries (those with sync_source: imls-museums)
  // but keep manually curated entries that were enhanced
  const filteredData = existingData.filter(item => item.sync_source !== 'imls-museums');

  // Add new entries
  const newData = [...filteredData, ...newEntries];

  // Write back
  const yamlContent = yaml.dump(newData, {
    lineWidth: -1,
    noRefs: true,
    quotingType: "'",
    forceQuotes: false
  });

  fs.writeFileSync(recreationPath, yamlContent);

  console.log(`\nResults:`);
  console.log(`  Merged with existing: ${merged}`);
  console.log(`  Added as new: ${added}`);
  console.log(`  Skipped (historic preservation orgs): ${skipped}`);

  // Summary by category for new entries
  if (newEntries.length > 0) {
    const byType = {};
    newEntries.forEach(e => {
      byType[e.category] = (byType[e.category] || 0) + 1;
    });
    console.log('\nNew entries by category:');
    Object.entries(byType).sort((a,b) => b[1] - a[1]).forEach(([cat, count]) => {
      console.log(`  ${cat}: ${count}`);
    });
  }
}

main().catch(console.error);
