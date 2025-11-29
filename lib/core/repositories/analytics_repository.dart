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
        '$baseUrl/analytics/timeline-by-level?projectId=$projectId&hours=$hours',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final rawPoints = data
          .map((json) => LogTimelinePoint.fromJson(json))
          .toList();

      // Aggregate points by timestamp
      final Map<DateTime, Map<String, int>> aggregated = {};

      for (final point in rawPoints) {
        // Normalize timestamp to remove seconds/milliseconds if needed,
        // but usually backend returns hourly buckets like "2025-11-25T13:00:00"
        final timestamp = point.timestamp;

        if (!aggregated.containsKey(timestamp)) {
          aggregated[timestamp] = {};
        }

        point.counts.forEach((level, count) {
          aggregated[timestamp]![level] =
              (aggregated[timestamp]![level] ?? 0) + count;
        });
      }

      // Convert back to list and sort
      final List<LogTimelinePoint> result = aggregated.entries.map((entry) {
        return LogTimelinePoint(timestamp: entry.key, counts: entry.value);
      }).toList();

      result.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return result;
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

  Future<PerformanceMetrics> getPerformanceMetrics({
    required String projectId,
    required String apiKey,
    int hours = 24,
    String? metric,
  }) async {
    final queryParams = {
      'projectId': projectId,
      'hours': hours.toString(),
      if (metric != null) 'metric': metric,
    };
    final uri = Uri.parse(
      '$baseUrl/analytics/performance/overview',
    ).replace(queryParameters: queryParams);

    final response = await _client.get(uri, headers: {'x-api-key': apiKey});

    if (response.statusCode == 200) {
      return PerformanceMetrics.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load performance metrics');
    }
  }

  Future<FunnelData> getFunnelData({
    required String projectId,
    required List<String> steps,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (steps.isEmpty) {
      throw Exception('At least one step is required for funnel analysis');
    }

    final queryParams = {
      'projectId': projectId,
      'steps': steps.join(','),
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final uri = Uri.parse(
      '$baseUrl/analytics/funnel',
    ).replace(queryParameters: queryParams);

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return FunnelData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load funnel data');
    }
  }

  Future<List<String>> getAvailableEvents({required String projectId}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/analytics/events?projectId=$projectId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> events = data['events'] ?? [];
      return events.map((e) => e.toString()).toList();
    } else {
      throw Exception('Failed to load available events');
    }
  }

  // Named Funnel Methods
  Future<List<String>> getAvailableFunnelNames({
    required String projectId,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/analytics/funnels?projectId=$projectId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e.toString()).toList();
    } else {
      // Enhanced error logging
      print('Error fetching funnel names:');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception(
        'Failed to load available funnel names (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<NamedFunnelData> getNamedFunnelData({
    required String projectId,
    required String funnelName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = {
      'projectId': projectId,
      'funnelName': funnelName,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final uri = Uri.parse(
      '$baseUrl/analytics/funnel-analysis',
    ).replace(queryParameters: queryParams);

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return NamedFunnelData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load named funnel data');
    }
  }
}
