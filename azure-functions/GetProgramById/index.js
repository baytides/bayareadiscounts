const { CosmosClient } = require('@azure/cosmos');
const { DefaultAzureCredential } = require('@azure/identity');

const endpoint = process.env.COSMOS_DB_ENDPOINT;
const databaseName = process.env.COSMOS_DB_DATABASE_NAME || 'bayareadiscounts';
const containerName = process.env.COSMOS_DB_CONTAINER_NAME || 'programs';

const credential = new DefaultAzureCredential();
const client = new CosmosClient({ endpoint, aadCredentials: credential });
const container = client.database(databaseName).container(containerName);

module.exports = async function (context, req) {
  const programId = req.params.id;
  context.log(`GetProgramById triggered for ID: ${programId}`);

  try {
    if (!endpoint) {
      throw new Error('COSMOS_DB_ENDPOINT is not configured');
    }

    const querySpec = {
      query: 'SELECT * FROM programs p WHERE p.id = @id',
      parameters: [{ name: '@id', value: programId }]
    };

    const { resources: programs } = await container.items
      .query(querySpec)
      .fetchAll();

    if (programs.length === 0) {
      context.res = {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
        body: { error: 'Program not found', id: programId }
      };
      return;
    }

    context.res = {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=300'
      },
      body: programs[0]
    };

  } catch (error) {
    context.log.error('Error fetching program:', error);
    context.res = {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
      body: { error: 'Failed to fetch program', message: error.message }
    };
  }
};
