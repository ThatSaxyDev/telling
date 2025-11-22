import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/log_model/log_model.dart';

class LogsRepository {
  final String baseUrl;
  final http.Client _client;

  LogsRepository({
    this.baseUrl = 'http://localhost:8080/api/v1',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Fetch all logs from the API
  Future<List<LogModel>> fetchLogs() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/logs'),
        headers: {'Content-Type': 'application/json'},
      );

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
    } on http.ClientException catch (e) {
      throw LogsRepositoryException('Network error: ${e.message}');
    } catch (e) {
      throw LogsRepositoryException('Unexpected error: $e');
    }
  }

  /// Fetch a single log by ID
  Future<LogModel> fetchLogById(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/logs/$id'),
        headers: {'Content-Type': 'application/json'},
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
    } on http.ClientException catch (e) {
      throw LogsRepositoryException('Network error: ${e.message}');
    } catch (e) {
      throw LogsRepositoryException('Unexpected error: $e');
    }
  }

  /// Delete a log by ID
  Future<void> deleteLog(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/logs/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw LogsRepositoryException(
          'Failed to delete log: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw LogsRepositoryException('Network error: ${e.message}');
    } catch (e) {
      throw LogsRepositoryException('Unexpected error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

class LogsRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  LogsRepositoryException(this.message, [this.statusCode]);

  @override
  String toString() => 'LogsRepositoryException: $message${statusCode != null ? " (HTTP $statusCode)" : ""}';
}
