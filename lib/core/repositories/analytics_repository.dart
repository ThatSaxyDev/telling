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
    try {
      // Note: userId is extracted from the JWT token by the backend
      final response = await _client.get(
        Uri.parse(
          '$baseUrl/analytics/summary?projectId=$projectId&hours=$hours',
        ),
      );

      if (response.statusCode == 200) {
        return AnalyticsSummary.fromJson(jsonDecode(response.body));
      } else {
        throw AnalyticsRepositoryException(
          'Failed to load analytics summary',
          response.statusCode,
        );
      }
    } catch (e) {
      throw AnalyticsRepositoryException(_sanitizeError(e));
    }
  }

  Future<List<LogTimelinePoint>> getLogsTimeline({
    required String projectId,
    int hours = 24,
  }) async {
    try {
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
        throw AnalyticsRepositoryException(
          'Failed to load logs timeline',
          response.statusCode,
        );
      }
    } catch (e) {
      throw AnalyticsRepositoryException(_sanitizeError(e));
    }
  }

  Future<List<LogLevelStat>> getLogLevels({
    required String projectId,
    int hours = 24,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$baseUrl/analytics/levels?projectId=$projectId&hours=$hours',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LogLevelStat.fromJson(json)).toList();
      } else {
        throw AnalyticsRepositoryException(
          'Failed to load log levels',
          response.statusCode,
        );
      }
    } catch (e) {
      throw AnalyticsRepositoryException(_sanitizeError(e));
    }
  }

  Future<List<TopErrorItem>> getTopErrors({
    required String projectId,
    int hours = 24,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$baseUrl/analytics/errors?projectId=$projectId&hours=$hours&limit=$limit',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TopErrorItem.fromJson(json)).toList();
      } else {
        throw AnalyticsRepositoryException(
          'Failed to load top errors',
          response.statusCode,
        );
      }
    } catch (e) {
      throw AnalyticsRepositoryException(_sanitizeError(e));
    }
  }

  Future<List<ActiveUserStat>> getActiveUsers({
    required String projectId,
    int hours = 24,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$baseUrl/analytics/users?projectId=$projectId&hours=$hours&limit=$limit',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ActiveUserStat.fromJson(json)).toList();
      } else {
        throw AnalyticsRepositoryException(
          'Failed to load active users',
          response.statusCode,
        );
      }
    } catch (e) {
      throw AnalyticsRepositoryException(_sanitizeError(e));
    }
  }

  Future<PerformanceMetrics> getPerformanceMetrics({
    required String projectId,
    required String apiKey,
    int hours = 24,
    String? metric,
  }) async {
    try {
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
        throw AnalyticsRepositoryException(
          'Failed to load performance metrics',
          response.statusCode,
        );
      }
    } catch (e) {
      throw AnalyticsRepositoryException(_sanitizeError(e));
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

    try {
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
        throw AnalyticsRepositoryException(
          'Failed to load funnel data',
          response.statusCode,
        );
      }
    } catch (e) {
      throw AnalyticsRepositoryException(_sanitizeError(e));
    }
  }

  Future<List<String>> getAvailableEvents({required String projectId}) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/analytics/events?projectId=$projectId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> events = data['events'] ?? [];
        return events.map((e) => e.toString()).toList();
      } else {
        throw AnalyticsRepositoryException(
          'Failed to load available events',
          response.statusCode,
        );
      }
    } catch (e) {
      throw AnalyticsRepositoryException(_sanitizeError(e));
    }
  }

  // Named Funnel Methods
  Future<List<String>> getAvailableFunnelNames({
    required String projectId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/analytics/funnels?projectId=$projectId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      } else {
        throw AnalyticsRepositoryException(
          'Failed to load available funnel names',
          response.statusCode,
        );
      }
    } catch (e) {
      throw AnalyticsRepositoryException(_sanitizeError(e));
    }
  }

  Future<NamedFunnelData> getNamedFunnelData({
    required String projectId,
    required String funnelName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
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
        throw AnalyticsRepositoryException(
          'Failed to load named funnel data',
          response.statusCode,
        );
      }
    } catch (e) {
      throw AnalyticsRepositoryException(_sanitizeError(e));
    }
  }

  String _sanitizeError(Object e) {
    final message = e.toString();
    if (message.contains('ClientException') ||
        message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Failed to host lookup')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'An unexpected error occurred. Please try again later.';
  }
}

class AnalyticsRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  AnalyticsRepositoryException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
