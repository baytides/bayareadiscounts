#!/usr/bin/env node

/**
 * Migration Script: YAML to Cosmos DB
 *
 * This script reads all YAML program files and uploads them to Azure Cosmos DB.
 *
 * Usage:
 *   node scripts/migrate-to-cosmos.js
 *
 * Required environment variables:
 *   - COSMOS_DB_ENDPOINT: Cosmos DB account endpoint
 *   - COSMOS_DB_KEY: Cosmos DB account key
 *   - COSMOS_DB_DATABASE_NAME: Database name (default: bayareadiscounts)
 *   - COSMOS_DB_CONTAINER_NAME: Container name (default: programs)
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const { CosmosClient } = require('@azure/cosmos');

// Configuration
const endpoint = process.env.COSMOS_DB_ENDPOINT;
const key = process.env.COSMOS_DB_KEY;
const databaseName = process.env.COSMOS_DB_DATABASE_NAME || 'bayareadiscounts';
const containerName = process.env.COSMOS_DB_CONTAINER_NAME || 'programs';

// Validate environment variables
if (!endpoint || !key) {
  console.error('❌ Error: Missing required environment variables');
  console.error('   Please set COSMOS_DB_ENDPOINT and COSMOS_DB_KEY');
  process.exit(1);
}

// Initialize Cosmos DB client
const client = new CosmosClient({ endpoint, key });
const database = client.database(databaseName);
const container = database.container(containerName);

/**
 * Load all YAML files from _data/programs directory
 */
function loadYamlFiles() {
  const programsDir = path.join(__dirname, '../_data/programs');
  const files = fs.readdirSync(programsDir)
    .filter(file => file.endsWith('.yml') && file !== 'README.md');

  console.log(`📁 Found ${files.length} YAML files`);

  const allPrograms = [];

  for (const file of files) {
    const filePath = path.join(programsDir, file);
    const fileContents = fs.readFileSync(filePath, 'utf8');
    const programs = yaml.load(fileContents);

    if (Array.isArray(programs)) {
      console.log(`   ✓ ${file}: ${programs.length} programs`);
      allPrograms.push(...programs);
    }
  }

  return allPrograms;
}

/**
 * Upload programs to Cosmos DB
 */
async function uploadPrograms(programs) {
  console.log(`\n📤 Uploading ${programs.length} programs to Cosmos DB...`);

  let successCount = 0;
  let errorCount = 0;
  const errors = [];

  for (const program of programs) {
    try {
      // Add Cosmos DB metadata
      const document = {
        ...program,
        // Use program id as the Cosmos DB id
        id: program.id,
        // Add timestamp
        uploadedAt: new Date().toISOString()
      };

      // Upsert (insert or update) the document
      await container.items.upsert(document);
      successCount++;

      if (successCount % 10 === 0) {
        process.stdout.write(`\r   Uploaded: ${successCount}/${programs.length}`);
      }

    } catch (error) {
      errorCount++;
      errors.push({
        id: program.id,
        name: program.name,
        error: error.message
      });
    }
  }

  console.log(`\r   Uploaded: ${successCount}/${programs.length}`);
  console.log(`\n✅ Upload complete!`);
  console.log(`   Success: ${successCount}`);
  console.log(`   Errors: ${errorCount}`);

  if (errors.length > 0) {
    console.log('\n❌ Errors:');
    errors.forEach(err => {
      console.log(`   - ${err.id} (${err.name}): ${err.error}`);
    });
  }

  return { successCount, errorCount, errors };
}

/**
 * Main migration function
 */
async function migrate() {
  console.log('🚀 Starting migration: YAML → Cosmos DB\n');
  console.log(`📊 Target Database: ${databaseName}`);
  console.log(`📊 Target Container: ${containerName}\n`);

  try {
    // Load YAML files
    const programs = loadYamlFiles();

    if (programs.length === 0) {
      console.log('⚠️  No programs found to migrate');
      return;
    }

    // Upload to Cosmos DB
    const result = await uploadPrograms(programs);

    console.log('\n✨ Migration complete!');

    if (result.errorCount > 0) {
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ Migration failed:', error.message);
    console.error(error);
    process.exit(1);
  }
}

// Run migration
migrate();
