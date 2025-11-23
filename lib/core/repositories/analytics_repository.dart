import 'dart:convert';
import '../services/api_client.dart';
import '../models/analytics_models.dart';

class AnalyticsRepository {
  final ApiClient _client;
  final String baseUrl;

  AnalyticsRepository(this._client, {required this.baseUrl});

  Future<AnalyticsSummary> getSummary({
    required String projectId,
    int hours = 24,
  }) async {
    // Note: userId is extracted from the JWT token by the backend
    final response = await _client.get(
      Uri.parse('$baseUrl/analytics/summary?projectId=$projectId&hours=$hours'),
    );

    if (response.statusCode == 200) {
      return AnalyticsSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load analytics summary');
    }
  }

  Future<List<LogTimelinePoint>> getLogsTimeline({
    required String projectId,
    int hours = 24,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl/analytics/timeline?projectId=$projectId&hours=$hours',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LogTimelinePoint.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load logs timeline');
    }
  }

  Future<List<LogLevelStat>> getLogLevels({
    required String projectId,
    int hours = 24,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/analytics/levels?projectId=$projectId&hours=$hours'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LogLevelStat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load log levels');
    }
  }

  Future<List<TopErrorItem>> getTopErrors({
    required String projectId,
    int hours = 24,
    int limit = 10,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl/analytics/errors?projectId=$projectId&hours=$hours&limit=$limit',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TopErrorItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load top errors');
    }
  }

  Future<List<ActiveUserStat>> getActiveUsers({
    required String projectId,
    int hours = 24,
    int limit = 10,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl/analytics/users?projectId=$projectId&hours=$hours&limit=$limit',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ActiveUserStat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load active users');
    }
  }
}
