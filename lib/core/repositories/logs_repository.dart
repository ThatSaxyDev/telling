import 'dart:convert';
import '../services/api_client.dart';
import '../models/log_model/log_model.dart';

class LogsRepository {
  final String baseUrl;
  final ApiClient _client;

  LogsRepository(this._client, {
    this.baseUrl = 'http://localhost:8080/api/v1',
  });

  /// Fetch logs from the API with pagination and optional user filter
  Future<List<LogModel>> fetchLogs({
    int page = 1,
    int limit = 50,
    String? userId, // Filter by user ID
    required String projectId, // For project isolation
  }) async {
    try {
      var uri = Uri.parse(
        '$baseUrl/logs?page=$page&limit=$limit&projectId=$projectId',
      );

      // Add userId query parameter if provided
      if (userId != null && userId.isNotEmpty) {
        uri = Uri.parse(
          '$baseUrl/logs?page=$page&limit=$limit&projectId=$projectId&userId=$userId',
        );
      }
      
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((json) => LogModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw LogsRepositoryException(
          'Failed to fetch logs: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw LogsRepositoryException('Unexpected error: $e');
    }
  }

  /// Fetch unique users
  Future<List<Map<String, dynamic>>> fetchUsers({
    required String projectId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users?projectId=$projectId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList.map((json) => json as Map<String, dynamic>).toList();
      } else {
        throw LogsRepositoryException(
          'Failed to fetch users: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw LogsRepositoryException('Unexpected error: $e');
    }
  }

  /// Fetch log statistics
  Future<Map<String, int>> fetchStats({
    required String projectId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/stats?projectId=$projectId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        return Map<String, int>.from(json);
      } else {
        throw LogsRepositoryException(
          'Failed to fetch stats: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw LogsRepositoryException('Unexpected error: $e');
    }
  }

  /// Fetch global sessions
  Future<List<Map<String, dynamic>>> fetchSessions({
    required String projectId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$baseUrl/sessions?projectId=$projectId&limit=$limit&offset=$offset',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList.map((json) => json as Map<String, dynamic>).toList();
      } else {
        throw LogsRepositoryException(
          'Failed to fetch sessions: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw LogsRepositoryException('Unexpected error: $e');
    }
  }

  /// Fetch logs for a specific session
  Future<List<LogModel>> fetchSessionLogs(
    String sessionId, {
    required String projectId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/sessions/$sessionId/logs?projectId=$projectId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((json) => LogModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw LogsRepositoryException(
          'Failed to fetch session logs: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw LogsRepositoryException('Unexpected error: $e');
    }
  }

  /// Fetch a single log by ID
  Future<LogModel> fetchLogById(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/logs/$id'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LogModel.fromJson(json);
      } else if (response.statusCode == 404) {
        throw LogsRepositoryException('Log not found', 404);
      } else {
        throw LogsRepositoryException(
          'Failed to fetch log: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw LogsRepositoryException('Unexpected error: $e');
    }
  }

  /// Delete a log by ID
  Future<void> deleteLog(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/logs/$id'),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw LogsRepositoryException(
          'Failed to delete log: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw LogsRepositoryException('Unexpected error: $e');
    }
  }
}

class LogsRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  LogsRepositoryException(this.message, [this.statusCode]);

  @override
  String toString() => 'LogsRepositoryException: $message${statusCode != null ? " (HTTP $statusCode)" : ""}';
}
