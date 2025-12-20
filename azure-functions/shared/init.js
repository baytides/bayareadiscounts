// Shared initialization for Azure Functions
const appInsights = require('applicationinsights');
const { createClient } = require('redis');
const { SecretClient } = require('@azure/keyvault-secrets');
const { DefaultAzureCredential } = require('@azure/identity');

// Initialize Application Insights
if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  appInsights.setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING)
    .setAutoDependencyCorrelation(true)
    .setAutoCollectRequests(true)
    .setAutoCollectPerformance(true, true)
    .setAutoCollectExceptions(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectConsole(true)
    .setUseDiskRetriesOnly(false)
    .setSendLiveMetrics(true)
    .setDistributedTracingMode(appInsights.DistributedTracingModes.AI_AND_W3C);
  
  appInsights.defaultClient.context.tags[appInsights.defaultClient.context.keys.cloudRole] = 'bayareadiscounts-api';
  appInsights.start();
  console.log('Application Insights initialized');
}

// Initialize Redis client
let redisClient = null;
async function getRedisClient() {
  if (redisClient && redisClient.isOpen) {
    return redisClient;
  }

  const redisHost = process.env.REDIS_HOST;
  const redisKey = process.env.REDIS_KEY;
  
  if (!redisHost || !redisKey) {
    console.warn('Redis not configured, caching disabled');
    return null;
  }

  try {
    redisClient = createClient({
      url: `rediss://${redisHost}:6380`,
      password: redisKey,
      socket: {
        tls: true,
        keepAlive: 30000
      }
    });

    redisClient.on('error', (err) => console.error('Redis Client Error:', err));
    await redisClient.connect();
    console.log('Redis client connected');
    return redisClient;
  } catch (err) {
    console.error('Failed to connect to Redis:', err);
    return null;
  }
}

// Initialize Key Vault client
let keyVaultClient = null;
function getKeyVaultClient() {
  if (keyVaultClient) {
    return keyVaultClient;
  }

  const vaultUrl = process.env.KEY_VAULT_URL;
  if (!vaultUrl) {
    console.warn('Key Vault not configured');
    return null;
  }

  const credential = new DefaultAzureCredential();
  keyVaultClient = new SecretClient(vaultUrl, credential);
  console.log('Key Vault client initialized');
  return keyVaultClient;
}

// Helper to get secret from Key Vault or fallback to env var
async function getSecret(secretName, envVarName) {
  const kvClient = getKeyVaultClient();
  if (kvClient) {
    try {
      const secret = await kvClient.getSecret(secretName);
      return secret.value;
    } catch (err) {
      console.warn(`Failed to get secret ${secretName} from Key Vault:`, err.message);
    }
  }
  return process.env[envVarName];
}

// Helper to cache API responses in Redis
async function cacheGet(key) {
  const client = await getRedisClient();
  if (!client) return null;

  try {
    const value = await client.get(key);
    if (value) {
      appInsights.defaultClient?.trackMetric({ name: 'Cache Hit', value: 1 });
      return JSON.parse(value);
    }
    appInsights.defaultClient?.trackMetric({ name: 'Cache Miss', value: 1 });
  } catch (err) {
    console.error('Redis get error:', err);
  }
  return null;
}

async function cacheSet(key, value, ttlSeconds = 3600) {
  const client = await getRedisClient();
  if (!client) return;

  try {
    await client.setEx(key, ttlSeconds, JSON.stringify(value));
  } catch (err) {
    console.error('Redis set error:', err);
  }
}

module.exports = {
  getRedisClient,
  getKeyVaultClient,
  getSecret,
  cacheGet,
  cacheSet,
  appInsights
};
