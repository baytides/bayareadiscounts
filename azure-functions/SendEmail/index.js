const { EmailClient } = require('@azure/communication-email');
const { getSecret, appInsights } = require('../shared/init');

module.exports = async function (context, req) {
  if (req.method === 'OPTIONS') {
    context.res = {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'content-type, authorization, ocp-apim-subscription-key'
      }
    };
    return;
  }

  const body = req.body || {};
  const to = body.to;
  const subject = body.subject || 'Notification';
  const content = body.content || '';
  const replyTo = body.replyTo;

  if (!to || !content) {
    context.res = {
      status: 400,
      body: { error: 'Missing required fields: to, content' }
    };
    return;
  }

  try {
    // Get ACS connection string from Key Vault or environment
    const connectionString = await getSecret('acs-connection-string', 'ACS_CONNECTION_STRING');
    if (!connectionString) {
      throw new Error('ACS connection string not configured');
    }

    const client = new EmailClient(connectionString);

    const message = {
      // Default to donotreply@bayareadiscounts.com if no explicit sender is configured.
      senderAddress: process.env.ACS_SENDER_ADDRESS || 'donotreply@bayareadiscounts.com',
      content: {
        subject,
        plainText: content,
        html: `<p>${content}</p>`
      },
      recipients: {
        to: [{ email: to }]
      }
    };

    if (replyTo) {
      message.replyTo = [{ email: replyTo }];
    }

    const response = await client.send(message);
    appInsights.defaultClient?.trackEvent({ name: 'EmailSent', properties: { to } });

    context.res = {
      status: 202,
      body: { messageId: response?.messageId || null, status: 'Accepted' }
    };
  } catch (err) {
    context.log.error('SendEmail error:', err);
    appInsights.defaultClient?.trackException({ exception: err });
    context.res = {
      status: 500,
      body: { error: 'Email send failed' }
    };
  }
};
