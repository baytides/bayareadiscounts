const { CosmosClient } = require('@azure/cosmos');
const { DefaultAzureCredential } = require('@azure/identity');
const { appInsights } = require('../shared/init');
const crypto = require('crypto');

const endpoint = process.env.COSMOS_DB_ENDPOINT;
const databaseName = process.env.COSMOS_DB_DATABASE_NAME || 'bayareadiscounts';
const containerName = process.env.SUBSCRIPTIONS_CONTAINER_NAME || 'subscriptions';

const credential = new DefaultAzureCredential();
const client = new CosmosClient({ endpoint, aadCredentials: credential });
const container = client.database(databaseName).container(containerName);

// Verify unsubscribe token
function verifyUnsubscribeToken(email, token) {
  const secret = process.env.UNSUBSCRIBE_SECRET || 'change-me-in-production';
  const expectedToken = crypto.createHmac('sha256', secret)
    .update(email)
    .digest('hex');
  return token === expectedToken;
}

module.exports = async function (context, req) {
  const startTime = Date.now();
  context.log('UnsubscribeUser triggered');

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    context.res = {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
      }
    };
    return;
  }

  try {
    if (!endpoint) throw new Error('COSMOS_DB_ENDPOINT not configured');

    const email = (req.query.email || (req.body && req.body.email) || '').toLowerCase().trim();
    const token = req.query.token || (req.body && req.body.token) || '';

    if (!email || !email.includes('@')) {
      context.res = {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: { error: 'Invalid email' }
      };
      return;
    }

    // Verify token
    if (!verifyUnsubscribeToken(email, token)) {
      context.res = {
        status: 403,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: { error: 'Invalid or missing unsubscribe token' }
      };
      return;
    }

    // Delete by id (email). Partition key must match '/email'.
    try {
      await container.item(email, email).delete();
      context.log('Unsubscribed:', email);
    } catch (deleteErr) {
      // If item not found, that's okay - they're already unsubscribed
      if (deleteErr.code !== 404) {
        throw deleteErr;
      }
      context.log('Subscription not found (already unsubscribed):', email);
    }

    appInsights.defaultClient?.trackMetric({ name: 'UnsubscribeUser Response Time', value: Date.now() - startTime });

    context.res = {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: { ok: true, email }
    };
  } catch (err) {
    context.log.error('UnsubscribeUser error:', err);
    context.res = {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: {
        error: 'Failed to unsubscribe',
        ...(process.env.NODE_ENV === 'development' && { message: err.message })
      }
    };
  }
};
