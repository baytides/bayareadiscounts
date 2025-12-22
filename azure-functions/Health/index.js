module.exports = async function (context, req) {
  context.log('Health check triggered');
  context.res = {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: {
      status: 'ok',
      timestamp: new Date().toISOString(),
      node: process.version
    }
  };
};
