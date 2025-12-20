/**
 * Azure Function: Translate
 *
 * Translates text using Azure AI Translator API.
 * Privacy-focused: All translation happens server-side through Azure.
 *
 * @endpoint POST /api/translate
 * @param {string[]} texts - Array of text strings to translate
 * @param {string} targetLang - Target language code (e.g., 'es', 'zh-Hans', 'tl')
 * @param {string} sourceLang - Source language code (optional, defaults to 'en')
 * @returns {object} - Translated texts
 *
 * Supported languages:
 * - es: Spanish
 * - zh-Hans: Chinese (Simplified)
 * - zh-Hant: Chinese (Traditional)
 * - tl: Tagalog
 * - vi: Vietnamese
 * - ko: Korean
 * - ru: Russian
 * - ar: Arabic
 * - fa: Persian
 * - ja: Japanese
 * - fr: French
 * - hi: Hindi
 */

const https = require('https');
const crypto = require('crypto');
const { DefaultAzureCredential } = require('@azure/identity');

const credential = new DefaultAzureCredential();

module.exports = async function (context, req) {
  // CORS headers
  context.res = {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Content-Type': 'application/json'
    }
  };

  // Handle OPTIONS for CORS preflight
  if (req.method === 'OPTIONS') {
    context.res.status = 200;
    return;
  }

  try {
    const { texts, targetLang, sourceLang = 'en' } = req.body;

    // Validate input
    if (!texts || !Array.isArray(texts) || texts.length === 0) {
      context.res.status = 400;
      context.res.body = {
        error: 'Missing or invalid parameter: texts (must be non-empty array)'
      };
      return;
    }

    if (texts.length > 100) {
      context.res.status = 400;
      context.res.body = {
        error: 'Too many texts to translate at once (max 100). Please batch your requests.'
      };
      return;
    }

    if (!targetLang) {
      context.res.status = 400;
      context.res.body = {
        error: 'Missing required parameter: targetLang'
      };
      return;
    }

    // Validate target language
    const supportedLanguages = [
      'es', 'zh-Hans', 'zh-Hant', 'tl', 'vi',
      'ko', 'ru', 'ar', 'fa', 'ja', 'fr', 'hi', 'en'
    ];

    if (!supportedLanguages.includes(targetLang)) {
      context.res.status = 400;
      context.res.body = {
        error: `Unsupported language: ${targetLang}`,
        supportedLanguages: supportedLanguages
      };
      return;
    }

    // Get Azure Translator credentials from environment (AAD via managed identity)
    const endpoint = process.env.AZURE_TRANSLATOR_ENDPOINT || 'https://api.cognitive.microsofttranslator.com';

    if (!endpoint) {
      context.res.status = 500;
      context.res.body = {
        error: 'Azure Translator endpoint not configured',
        note: 'Set AZURE_TRANSLATOR_ENDPOINT to your Translator resource endpoint'
      };
      return;
    }

    const token = await credential.getToken('https://cognitiveservices.azure.com/.default');

    if (!token || !token.token) {
      context.res.status = 500;
      context.res.body = {
        error: 'Failed to acquire Azure AD token for Translator',
        note: 'Ensure the Function App managed identity has Cognitive Services User access on the Translator resource and local auth is disabled.'
      };
      return;
    }

    // Prepare translation request
    const path = '/translate';
    const params = new URLSearchParams({
      'api-version': '3.0',
      'from': sourceLang,
      'to': targetLang
    });

    const requestBody = texts.map(text => ({ text }));

    // Make request to Azure Translator API
    const response = await makeTranslatorRequest(
      endpoint,
      path + '?' + params.toString(),
      requestBody,
      token.token
    );

    // Extract translated texts
    const translations = response.map(item =>
      item.translations && item.translations[0] ? item.translations[0].text : ''
    );

    context.res.status = 200;
    context.res.body = {
      success: true,
      sourceLang: sourceLang,
      targetLang: targetLang,
      translations: translations,
      count: translations.length
    };

  } catch (error) {
    context.log.error('Translation error:', error);
    context.res.status = 500;
    context.res.body = {
      error: 'Translation service error',
      message: error.message
    };
  }
};

// Helper function to make HTTPS request to Azure Translator
function makeTranslatorRequest(endpoint, path, body, bearerToken) {
  return new Promise((resolve, reject) => {
    const hostname = endpoint.replace('https://', '').replace('http://', '');
    const requestBody = JSON.stringify(body);

    const options = {
      hostname: hostname,
      port: 443,
      path: path,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${bearerToken}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestBody),
        'X-ClientTraceId': crypto.randomUUID()
      }
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error('Failed to parse response: ' + e.message));
          }
        } else {
          reject(new Error(`Azure Translator API returned status ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(requestBody);
    req.end();
  });
}
