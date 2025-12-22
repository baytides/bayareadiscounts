const { CosmosClient } = require('@azure/cosmos');
const { DefaultAzureCredential } = require('@azure/identity');
const { cacheGet, cacheSet } = require('../shared/init');

const endpoint = process.env.COSMOS_DB_ENDPOINT;
const databaseName = process.env.COSMOS_DB_DATABASE_NAME || 'bayareadiscounts';
const containerName = process.env.COSMOS_DB_CONTAINER_NAME || 'programs';

const credential = new DefaultAzureCredential();
const client = new CosmosClient({ endpoint, aadCredentials: credential });
const container = client.database(databaseName).container(containerName);

module.exports = async function (context, req) {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    context.res = {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
      }
    };
    return;
  }

  context.log('GetStats function triggered');

  try {
    if (!endpoint) {
      throw new Error('COSMOS_DB_ENDPOINT is not configured');
    }

    // Try cache first
    const cacheKey = 'stats:all';
    const cached = await cacheGet(cacheKey);
    if (cached) {
      context.log('Returning cached stats');
      context.res = {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=3600',
          'X-Cache': 'HIT',
          'Access-Control-Allow-Origin': '*'
        },
        body: cached
      };
      return;
    }

    // Get total count
    const countQuery = {
      query: 'SELECT VALUE COUNT(1) FROM programs'
    };
    const { resources: countResult } = await container.items
      .query(countQuery)
      .fetchAll();
    const totalPrograms = countResult[0];

    // Get category breakdown
    const categoryQuery = {
      query: `
        SELECT p.category, COUNT(1) as count
        FROM programs p
        GROUP BY p.category
      `
    };
    const { resources: categories } = await container.items
      .query(categoryQuery)
      .fetchAll();

    // Sort categories by count in application code
    categories.sort((a, b) => b.count - a.count);

    // Get area breakdown
    const areaQuery = {
      query: `
        SELECT p.area, COUNT(1) as count
        FROM programs p
        GROUP BY p.area
      `
    };
    const { resources: areas } = await container.items
      .query(areaQuery)
      .fetchAll();

    // Sort and take top 10 in application code
    const topAreas = areas.sort((a, b) => b.count - a.count).slice(0, 10);

    // Get eligibility breakdown (count distinct eligibility types)
    const eligibilityQuery = {
      query: `
        SELECT p.eligibility
        FROM programs p
        WHERE ARRAY_LENGTH(p.eligibility) > 0
      `
    };
    const { resources: eligibilityData } = await container.items
      .query(eligibilityQuery)
      .fetchAll();

    // Count unique eligibility types
    const eligibilityCounts = {};
    eligibilityData.forEach(item => {
      if (item.eligibility && Array.isArray(item.eligibility)) {
        item.eligibility.forEach(e => {
          eligibilityCounts[e] = (eligibilityCounts[e] || 0) + 1;
        });
      }
    });

    const eligibilityBreakdown = Object.entries(eligibilityCounts)
      .map(([eligibility, count]) => ({ eligibility, count }))
      .sort((a, b) => b.count - a.count);

    const response = {
      totalPrograms,
      categories: {
        count: categories.length,
        breakdown: categories
      },
      areas: {
        total: topAreas.length,
        top10: topAreas
      },
      eligibility: {
        types: eligibilityBreakdown.length,
        breakdown: eligibilityBreakdown
      }
    };

    // Cache for 1 hour
    await cacheSet(cacheKey, response, 3600);

    context.res = {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=3600',
        'X-Cache': 'MISS',
        'Access-Control-Allow-Origin': '*'
      },
      body: response
    };

  } catch (error) {
    context.log.error('Error fetching stats:', error);
    context.res = {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: {
        error: 'Failed to fetch stats',
        ...(process.env.NODE_ENV === 'development' && { message: error.message })
      }
    };
  }
};
