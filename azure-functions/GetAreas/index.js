const { CosmosClient } = require('@azure/cosmos');
const { DefaultAzureCredential } = require('@azure/identity');

const endpoint = process.env.COSMOS_DB_ENDPOINT;
const databaseName = process.env.COSMOS_DB_DATABASE_NAME || 'bayareadiscounts';
const containerName = process.env.COSMOS_DB_CONTAINER_NAME || 'programs';

const credential = new DefaultAzureCredential();
const client = new CosmosClient({ endpoint, aadCredentials: credential });
const container = client.database(databaseName).container(containerName);

module.exports = async function (context, req) {
  context.log('GetAreas function triggered');

  try {
    if (!endpoint) {
      throw new Error('COSMOS_DB_ENDPOINT is not configured');
    }

    const querySpec = {
      query: `
        SELECT
          p.area,
          COUNT(1) as count
        FROM programs p
        GROUP BY p.area
        ORDER BY p.area
      `
    };

    const { resources: areas } = await container.items
      .query(querySpec)
      .fetchAll();

    context.log(`Found ${areas.length} areas`);

    context.res = {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=3600'
      },
      body: {
        count: areas.length,
        areas: areas
      }
    };

  } catch (error) {
    context.log.error('Error fetching areas:', error);
    context.res = {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
      body: { error: 'Failed to fetch areas', message: error.message }
    };
  }
};
