/// API Configuration
///
/// Central configuration for API endpoints
class ApiConfig {
  // Base URL for the backend API
  static const String baseUrl = 'https://telling-api.kiishi.space/api/v1';
  
  // Pusher configuration (key and cluster are safe to expose)
  static const String pusherKey = '69b1d46dd91791fb62f0';
  static const String pusherCluster = 'eu';

  // Specific endpoint paths
  static const String authPath = '$baseUrl/auth';
  static const String projectsPath = '$baseUrl/projects';
  static const String logsPath = '$baseUrl/logs';
  static const String analyticsPath = '$baseUrl/analytics';
  static const String usersPath = '$baseUrl/users';
  static const String sessionsPath = '$baseUrl/sessions';
  static const String statsPath = '$baseUrl/stats';
  static const String projectConfigPath =
      '$baseUrl/project'; // For version config
  static const String notificationsPath = '$baseUrl/notifications';
  static const String organizationsPath = '$baseUrl/organizations';
  static const String pusherAuthPath =
      '$baseUrl/../pusher/auth'; // At root, not /api/v1

  // For local development, switch to:
  // static const String baseUrl = 'http://localhost:8080/api/v1';
}
