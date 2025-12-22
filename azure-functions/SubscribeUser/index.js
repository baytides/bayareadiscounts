const { CosmosClient } = require('@azure/cosmos');
const { DefaultAzureCredential } = require('@azure/identity');
const { EmailClient } = require('@azure/communication-email');
const { appInsights } = require('../shared/init');
const crypto = require('crypto');

const endpoint = process.env.COSMOS_DB_ENDPOINT;
const databaseName = process.env.COSMOS_DB_DATABASE_NAME || 'bayareadiscounts';
const containerName = process.env.SUBSCRIPTIONS_CONTAINER_NAME || 'subscriptions';
// Initialize ACS Email client
const acsConnectionString = process.env.ACS_CONNECTION_STRING;
const acsSender = process.env.ACS_SENDER_ADDRESS || 'donotreply@bayareadiscounts.com';
const emailClient = acsConnectionString ? new EmailClient(acsConnectionString) : null;

const credential = new DefaultAzureCredential();
const client = new CosmosClient({ endpoint, aadCredentials: credential });
const container = client.database(databaseName).container(containerName);

// Generate secure unsubscribe token
function generateUnsubscribeToken(email) {
  const secret = process.env.UNSUBSCRIBE_SECRET || 'change-me-in-production';
  return crypto.createHmac('sha256', secret)
    .update(email)
    .digest('hex');
}

module.exports = async function (context, req) {
  const startTime = Date.now();
  context.log('SubscribeUser triggered');

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    context.res = {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
      }
    };
    return;
  }

  try {
    if (!endpoint) throw new Error('COSMOS_DB_ENDPOINT not configured');

    const body = req.body || {};
    const email = (body.email || '').toLowerCase().trim();
    const eligibility = body.eligibility;
    const county = body.county || 'none';
    const areas = body.areas;

    // Proper email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
      context.res = {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: { error: 'Invalid email format' }
      };
      return;
    }

    // Validate arrays
    if (!Array.isArray(eligibility) || !Array.isArray(areas)) {
      context.res = {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: { error: 'Invalid request format: eligibility and areas must be arrays' }
      };
      return;
    }

    const id = email; // use email as id for simplicity
    const doc = {
      id,
      email,
      eligibility,
      county,
      areas,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      type: 'subscription'
    };

    // Upsert subscription
    const { resource } = await container.items.upsert(doc);
    context.log('Subscription upserted', resource.id);

    // Send confirmation email (best-effort)
    if (emailClient) {
      try {
        const manageUrl = process.env.PUBLIC_BASE_URL || 'https://bayareadiscounts.com';
        const token = generateUnsubscribeToken(email);
        const unsubscribeLink = `${manageUrl}/api/UnsubscribeUser?email=${encodeURIComponent(email)}&token=${token}`;

        const message = {
          senderAddress: acsSender,
          content: {
            subject: 'You\'re subscribed to Bay Area Discounts updates',
            html: `
              <div style="max-width:640px;margin:0 auto;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;color:#111">
                <div style="text-align:center;margin-bottom:16px">
                  <img src="${manageUrl}/assets/images/logo/banner.png" alt="Bay Area Discounts" style="max-width:100%;height:auto"/>
                </div>
                <h2 style="margin:0 0 8px">Subscription confirmed</h2>
                <p>Thanks for subscribing! We'll send updates when new programs are added that match your preferences.</p>
                <h3 style="margin:16px 0 8px">Your preferences</h3>
                <ul>
                  <li><strong>Eligibility:</strong> ${eligibility.join(', ') || 'None selected'}</li>
                  <li><strong>County:</strong> ${county}</li>
                  <li><strong>Areas:</strong> ${areas.join(', ') || 'None selected'}</li>
                </ul>
                <p><a href="${unsubscribeLink}" style="color:#1e40af">Unsubscribe</a></p>
              </div>
            `,
            plainText: `Thanks for subscribing!\nEligibility: ${eligibility.join(', ') || 'None'}\nCounty: ${county}\nAreas: ${areas.join(', ') || 'None'}\nUnsubscribe: ${unsubscribeLink}`
          },
          recipients: {
            to: [{ address: email }]
          }
        };
        await emailClient.beginSend(message);
      } catch (emailErr) {
        context.log.warn('Email send failed:', emailErr.message);
      }
    }

    appInsights.defaultClient?.trackMetric({ name: 'SubscribeUser Response Time', value: Date.now() - startTime });

    context.res = {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: { ok: true, id: resource.id }
    };
  } catch (err) {
    context.log.error('SubscribeUser error:', err);
    context.res = {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: {
        error: 'Failed to subscribe',
        ...(process.env.NODE_ENV === 'development' && { message: err.message })
      }
    };
  }
};
