/**
 * Smart Assistant Azure Function
 * Uses Azure OpenAI to help users find relevant programs based on their needs
 */

const AZURE_OPENAI_ENDPOINT = process.env.AZURE_OPENAI_ENDPOINT;
const AZURE_OPENAI_KEY = process.env.AZURE_OPENAI_KEY;
const AZURE_OPENAI_DEPLOYMENT = process.env.AZURE_OPENAI_DEPLOYMENT || 'gpt-4o-mini';
const API_VERSION = '2024-02-15-preview';

// System prompt that guides the AI assistant
const SYSTEM_PROMPT = `You are Bay Navigator's helpful assistant, designed to help Bay Area residents find free and low-cost community programs and services.

Your role is to:
1. Understand what the user is looking for (food assistance, utility help, healthcare, etc.)
2. Ask clarifying questions if needed (location, eligibility factors like age, income, veteran status)
3. Provide relevant program recommendations from the available categories
4. Be warm, empathetic, and helpful - many users may be in difficult situations

Available program categories:
- Food: Food banks, CalFresh, meal programs, groceries
- Health: Medical clinics, mental health, dental, vision, prescriptions
- Housing: Rental assistance, emergency shelter, housing programs
- Utilities: PG&E CARE/FERA, water assistance, phone programs, internet
- Transportation: Clipper discounts, paratransit, car programs
- Education: Job training, GED, college assistance, tutoring
- Legal: Free legal aid, immigration help, tenant rights
- Finance: Tax prep, banking, financial counseling
- Technology: Free computers, internet access, digital literacy
- Recreation: Free museum days, park programs, library services
- Community: Senior centers, disability services, veteran programs

Eligibility groups that programs may serve:
- Seniors (65+)
- Veterans
- Low-income households
- Students
- Families with children
- People with disabilities
- Immigrants/refugees
- Homeless/at-risk of homelessness

When responding:
- Keep responses concise and actionable (2-3 paragraphs max)
- Suggest specific program categories to explore
- If the user shares their situation, acknowledge it with empathy
- Always encourage them to check program details as eligibility may vary
- End with a helpful next step or question

Do NOT:
- Make up specific program names or phone numbers
- Promise eligibility for any program
- Provide legal, medical, or financial advice
- Share information outside of Bay Area community resources`;

async function callAzureOpenAI(messages) {
  const url = `${AZURE_OPENAI_ENDPOINT}/openai/deployments/${AZURE_OPENAI_DEPLOYMENT}/chat/completions?api-version=${API_VERSION}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'api-key': AZURE_OPENAI_KEY
    },
    body: JSON.stringify({
      messages,
      max_tokens: 500,
      temperature: 0.7,
      top_p: 0.9,
      frequency_penalty: 0.3,
      presence_penalty: 0.1
    })
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Azure OpenAI API error: ${response.status} - ${error}`);
  }

  return response.json();
}

module.exports = async function (context, req) {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    context.res = {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Max-Age': '86400'
      }
    };
    return;
  }

  // CORS headers for all responses
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json'
  };

  try {
    // Validate configuration
    if (!AZURE_OPENAI_ENDPOINT || !AZURE_OPENAI_KEY) {
      context.res = {
        status: 503,
        headers: corsHeaders,
        body: JSON.stringify({
          error: 'Smart assistant is not configured. Please try again later.'
        })
      };
      return;
    }

    // Parse request
    const { message, conversationHistory = [] } = req.body || {};

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      context.res = {
        status: 400,
        headers: corsHeaders,
        body: JSON.stringify({
          error: 'Please provide a message.'
        })
      };
      return;
    }

    // Rate limiting check (simple in-memory, would use Redis in production)
    const userMessage = message.trim().slice(0, 500); // Limit message length

    // Build conversation messages
    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...conversationHistory.slice(-6).map(msg => ({
        role: msg.role,
        content: msg.content.slice(0, 500)
      })),
      { role: 'user', content: userMessage }
    ];

    // Call Azure OpenAI
    const completion = await callAzureOpenAI(messages);
    const assistantMessage = completion.choices?.[0]?.message?.content ||
      "I'm sorry, I couldn't process your request. Please try again.";

    context.res = {
      status: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        message: assistantMessage,
        usage: {
          promptTokens: completion.usage?.prompt_tokens,
          completionTokens: completion.usage?.completion_tokens
        }
      })
    };

  } catch (error) {
    context.log.error('Smart assistant error:', error);

    context.res = {
      status: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        error: 'Something went wrong. Please try again.'
      })
    };
  }
};
