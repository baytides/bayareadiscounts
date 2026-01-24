/**
 * Structured Logging Utility for Azure Functions
 *
 * Provides consistent, structured JSON logging for all Azure Functions.
 * Compatible with Azure Application Insights and Log Analytics.
 *
 * PRIVACY: This logger is designed to protect user anonymity:
 * - IP addresses are hashed (for rate limiting) but never stored in plaintext
 * - User agents are simplified to prevent fingerprinting
 * - No personal data should ever be logged
 *
 * Usage:
 *   const { createLogger } = require('../shared/logger');
 *   const logger = createLogger(context, 'carbon-stats');
 *   logger.info('Processing request', { userId: '123', query: 'food assistance' });
 *   logger.error('Search failed', { error: err.message, stack: err.stack });
 */

const crypto = require('crypto');

/**
 * Hash an IP address for rate limiting without storing the actual IP
 * Uses a daily rotating salt so hashes can't be correlated across days
 */
function hashIP(ip) {
  if (!ip) return 'unknown';
  // Daily rotating salt based on date (UTC)
  const date = new Date().toISOString().split('T')[0];
  const salt = `baynavigator-${date}`;
  return crypto
    .createHash('sha256')
    .update(ip + salt)
    .digest('hex')
    .slice(0, 16);
}

/**
 * Simplify user agent to basic browser/device type without fingerprinting details
 */
function simplifyUserAgent(ua) {
  if (!ua) return 'unknown';
  // Just identify general browser type, not version details
  if (ua.includes('Mobile')) return 'mobile';
  if (ua.includes('Chrome')) return 'chrome';
  if (ua.includes('Firefox')) return 'firefox';
  if (ua.includes('Safari')) return 'safari';
  if (ua.includes('Edge')) return 'edge';
  return 'other';
}

/**
 * Log levels with numeric values for filtering
 */
const LogLevel = {
  DEBUG: 10,
  INFO: 20,
  WARN: 30,
  ERROR: 40,
};

/**
 * Create a structured logger for an Azure Function
 *
 * @param {object} context - Azure Functions context object
 * @param {string} functionName - Name of the function for log identification
 * @param {object} options - Logger options
 * @returns {object} Logger instance with debug, info, warn, error methods
 */
function createLogger(context, functionName, options = {}) {
  const {
    minLevel = LogLevel.DEBUG,
    includeTimestamp = true,
    includeInvocationId = true,
  } = options;

  const invocationId = context.invocationId || 'unknown';

  /**
   * Format a log entry as structured JSON
   */
  function formatLogEntry(level, message, data = {}) {
    const entry = {
      timestamp: includeTimestamp ? new Date().toISOString() : undefined,
      level,
      function: functionName,
      invocationId: includeInvocationId ? invocationId : undefined,
      message,
      ...data,
    };

    // Remove undefined values
    Object.keys(entry).forEach((key) => {
      if (entry[key] === undefined) {
        delete entry[key];
      }
    });

    return entry;
  }

  /**
   * Write a log entry to the appropriate context.log method
   */
  function writeLog(levelName, levelValue, message, data) {
    if (levelValue < minLevel) return;

    const entry = formatLogEntry(levelName, message, data);
    const jsonString = JSON.stringify(entry);

    switch (levelName) {
      case 'ERROR':
        context.log.error(jsonString);
        break;
      case 'WARN':
        context.log.warn(jsonString);
        break;
      case 'INFO':
        context.log.info(jsonString);
        break;
      case 'DEBUG':
      default:
        context.log.verbose(jsonString);
        break;
    }
  }

  return {
    /**
     * Log debug-level message (verbose, for troubleshooting)
     * @param {string} message - Log message
     * @param {object} data - Additional structured data
     */
    debug(message, data = {}) {
      writeLog('DEBUG', LogLevel.DEBUG, message, data);
    },

    /**
     * Log info-level message (normal operations)
     * @param {string} message - Log message
     * @param {object} data - Additional structured data
     */
    info(message, data = {}) {
      writeLog('INFO', LogLevel.INFO, message, data);
    },

    /**
     * Log warning-level message (potential issues)
     * @param {string} message - Log message
     * @param {object} data - Additional structured data
     */
    warn(message, data = {}) {
      writeLog('WARN', LogLevel.WARN, message, data);
    },

    /**
     * Log error-level message (failures)
     * @param {string} message - Log message
     * @param {object} data - Additional structured data (include error details)
     */
    error(message, data = {}) {
      writeLog('ERROR', LogLevel.ERROR, message, data);
    },

    /**
     * Log the start of a function invocation
     * PRIVACY: IP addresses are hashed, user agents simplified
     * @param {object} req - HTTP request object
     */
    logRequest(req) {
      // Get the first IP from x-forwarded-for (client IP)
      const forwardedFor = req.headers?.['x-forwarded-for'];
      const clientIP = forwardedFor?.split(',')[0]?.trim();

      this.info('Function invoked', {
        method: req.method,
        // Don't log full URL - may contain sensitive query params
        path: req.url?.split('?')[0],
        headers: {
          'content-type': req.headers?.['content-type'],
          // Simplified user agent - no fingerprinting details
          'client-type': simplifyUserAgent(req.headers?.['user-agent']),
          // Hashed IP for rate limiting - not the actual IP
          'client-hash': hashIP(clientIP),
        },
        bodySize: req.body ? JSON.stringify(req.body).length : 0,
      });
    },

    /**
     * Log the response being sent
     * @param {number} status - HTTP status code
     * @param {object} body - Response body (will be summarized)
     * @param {number} durationMs - Request duration in milliseconds
     */
    logResponse(status, body, durationMs) {
      this.info('Function completed', {
        status,
        durationMs,
        responseSize: body ? JSON.stringify(body).length : 0,
      });
    },

    /**
     * Create a child logger with additional context
     * @param {object} additionalContext - Additional context to include in all logs
     * @returns {object} Child logger instance
     */
    child(additionalContext) {
      const parent = this;
      return {
        debug(message, data = {}) {
          parent.debug(message, { ...additionalContext, ...data });
        },
        info(message, data = {}) {
          parent.info(message, { ...additionalContext, ...data });
        },
        warn(message, data = {}) {
          parent.warn(message, { ...additionalContext, ...data });
        },
        error(message, data = {}) {
          parent.error(message, { ...additionalContext, ...data });
        },
      };
    },
  };
}

/**
 * Utility to measure operation duration
 *
 * Usage:
 *   const timer = createTimer();
 *   // ... do work ...
 *   logger.info('Operation completed', { durationMs: timer.elapsed() });
 */
function createTimer() {
  const start = Date.now();
  return {
    elapsed() {
      return Date.now() - start;
    },
    reset() {
      return Date.now();
    },
  };
}

/**
 * Safely extract error information for logging
 * @param {Error|any} error - Error object or any value
 * @returns {object} Structured error information
 */
function extractErrorInfo(error) {
  if (error instanceof Error) {
    return {
      name: error.name,
      message: error.message,
      stack: error.stack?.split('\n').slice(0, 5).join('\n'), // First 5 stack frames
      code: error.code,
    };
  }
  return {
    message: String(error),
  };
}

module.exports = {
  createLogger,
  createTimer,
  extractErrorInfo,
  LogLevel,
  hashIP, // Export for rate limiting
};
