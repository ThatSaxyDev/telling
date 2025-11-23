const validLogLevels = {'trace', 'debug', 'info', 'warning', 'error', 'fatal'};
const validLogTypes = {
  'general',
  'analytics',
  'event',
  'performance',
  'network',
  'security',
  'exception',
  'crash',
  'custom',
  // Legacy support
  'log', // Maps to 'general'
  'error', // Maps to 'general'
  'errorr', // Maps to 'general' (typo fix)
};

const maxRequestsPerMinute = 100;
const dedupeWindowSeconds = 10;

// Security
// TODO: In production, load this from environment variables!
const jwtSecret = 'development_secret_key_change_in_prod_12345';
const jwtIssuer = 'telling_backend';
