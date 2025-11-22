import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analytics_models.dart';

class AnalyticsRepository {
  final String baseUrl;

  AnalyticsRepository({required this.baseUrl});

  Future<AnalyticsSummary> getSummary({int hours = 24}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/summary?hours=$hours'),
    );

    if (response.statusCode == 200) {
      return AnalyticsSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load analytics summary');
    }
  }

  Future<List<LogTimelinePoint>> getLogsTimeline({int hours = 24}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/logs-timeline?hours=$hours'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LogTimelinePoint.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load logs timeline');
    }
  }

  Future<List<LogLevelStat>> getLogLevels({int hours = 24}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/log-levels?hours=$hours'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LogLevelStat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load log levels');
    }
  }

  Future<List<TopErrorItem>> getTopErrors({
    int hours = 24,
    int limit = 10,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/top-errors?hours=$hours&limit=$limit'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TopErrorItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load top errors');
    }
  }

  Future<List<ActiveUserStat>> getActiveUsers({
    int hours = 24,
    int limit = 10,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/active-users?hours=$hours&limit=$limit'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ActiveUserStat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load active users');
    }
  }
}
