/// API Configuration
///
/// Central configuration for API endpoints
class ApiConfig {
  // Base URL for the backend API
  static const String baseUrl =
      'https://tellingserver-ngyfcea-thatsaxydev.globeapp.dev/api/v1';

  // Specific endpoint paths
  static const String authPath = '$baseUrl/auth';
  static const String projectsPath = '$baseUrl/projects';
  static const String logsPath = '$baseUrl/logs';
  static const String analyticsPath = '$baseUrl/analytics';
  static const String usersPath = '$baseUrl/users';
  static const String sessionsPath = '$baseUrl/sessions';
  static const String statsPath = '$baseUrl/stats';

  // For development, you can switch between local and production
  // static const String baseUrl = 'http://localhost:8080/api/v1';
}
