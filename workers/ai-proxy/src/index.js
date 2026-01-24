/**
 * Bay Navigator AI Proxy Worker
 * Routes /api/chat requests to ai.baytides.org
 * All other requests go to baynavigator.org
 * Used for domain fronting / censorship circumvention
 */

export default {
  async fetch(request, env, _ctx) {
    const url = new URL(request.url);

    // Handle CORS preflight for /api/chat
    if (request.method === 'OPTIONS' && url.pathname.startsWith('/api/chat')) {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, X-API-Key',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // Route /api/chat to AI backend
    if (url.pathname.startsWith('/api/chat')) {
      const aiUrl = env.AI_ORIGIN + url.pathname + url.search;

      // Create new headers, excluding host
      const headers = new Headers();
      for (const [key, value] of request.headers) {
        if (key.toLowerCase() !== 'host') {
          headers.set(key, value);
        }
      }
      headers.set('Host', 'ai.baytides.org');

      // Forward to AI backend
      const response = await fetch(aiUrl, {
        method: request.method,
        headers: headers,
        body: request.method !== 'GET' && request.method !== 'HEAD' ? request.body : undefined,
      });

      // Return response with CORS headers
      const newHeaders = new Headers(response.headers);
      newHeaders.set('Access-Control-Allow-Origin', '*');
      newHeaders.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      newHeaders.set('Access-Control-Allow-Headers', 'Content-Type, X-API-Key');

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: newHeaders,
      });
    }

    // All other requests go to main site
    const mainUrl = env.MAIN_ORIGIN + url.pathname + url.search;

    const headers = new Headers();
    for (const [key, value] of request.headers) {
      if (key.toLowerCase() !== 'host') {
        headers.set(key, value);
      }
    }
    headers.set('Host', 'baynavigator.org');

    return fetch(mainUrl, {
      method: request.method,
      headers: headers,
      body: request.method !== 'GET' && request.method !== 'HEAD' ? request.body : undefined,
    });
  },
};
