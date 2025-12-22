const { CosmosClient } = require('@azure/cosmos');
const { DefaultAzureCredential } = require('@azure/identity');
const { cacheGet, cacheSet, appInsights } = require('../shared/init');

// Initialize Cosmos DB client with Managed Identity
const endpoint = process.env.COSMOS_DB_ENDPOINT;
const databaseName = process.env.COSMOS_DB_DATABASE_NAME || 'bayareadiscounts';
const containerName = process.env.COSMOS_DB_CONTAINER_NAME || 'programs';

const credential = new DefaultAzureCredential();
const client = new CosmosClient({ endpoint, aadCredentials: credential });
const container = client.database(databaseName).container(containerName);

module.exports = async function (context, req) {
  const startTime = Date.now();
  context.log('GetPrograms function triggered');

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

  try {
    if (!endpoint) {
      throw new Error('COSMOS_DB_ENDPOINT is not configured');
    }

    // Parse query parameters
    const category = req.query.category;
    const area = req.query.area;
    const eligibility = req.query.eligibility;
    const search = req.query.search;

    // Create cache key from query params
    const cacheKey = `programs:${category || 'all'}:${area || 'all'}:${eligibility || 'all'}:${search || 'none'}`;

    // Try cache first
    const cached = await cacheGet(cacheKey);
    if (cached) {
      context.log('Returning cached result');
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
      appInsights.defaultClient?.trackMetric({ name: 'GetPrograms Response Time', value: Date.now() - startTime });
      return;
    }

    // Build query
    let querySpec = {
      query: 'SELECT * FROM programs p WHERE 1=1',
      parameters: []
    };

    if (category) {
      querySpec.query += ' AND p.category = @category';
      querySpec.parameters.push({ name: '@category', value: category });
    }

    if (area) {
      querySpec.query += ' AND p.area = @area';
      querySpec.parameters.push({ name: '@area', value: area });
    }

    if (eligibility) {
      querySpec.query += ' AND ARRAY_CONTAINS(p.eligibility, @eligibility)';
      querySpec.parameters.push({ name: '@eligibility', value: eligibility });
    }

    if (search) {
      querySpec.query += ' AND (CONTAINS(LOWER(p.name), LOWER(@search)) OR CONTAINS(LOWER(p.benefit), LOWER(@search)))';
      querySpec.parameters.push({ name: '@search', value: search });
    }

    querySpec.query += ' ORDER BY p.name';

    context.log('Query:', querySpec);

    // Execute query
    const { resources: programs } = await container.items
      .query(querySpec)
      .fetchAll();

    context.log(`Found ${programs.length} programs`);

    const response = {
      programs,
      count: programs.length,
      timestamp: new Date().toISOString()
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

    appInsights.defaultClient?.trackMetric({ name: 'GetPrograms Response Time', value: Date.now() - startTime });
    appInsights.defaultClient?.trackMetric({ name: 'Programs Returned', value: programs.length });

  } catch (error) {
    context.log.error('Error fetching programs:', error);

    context.res = {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: {
        error: 'Failed to fetch programs',
        ...(process.env.NODE_ENV === 'development' && { message: error.message })
      }
    };
  }
};
