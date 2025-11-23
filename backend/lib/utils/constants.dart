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
