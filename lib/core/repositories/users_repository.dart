import 'dart:convert';
import '../services/api_client.dart';
import '../models/user.dart';
import '../models/log_entry.dart';
import '../config/api_config.dart';

class UsersRepository {
  final String baseUrl;
  final ApiClient _client;

  UsersRepository(this._client, {this.baseUrl = ApiConfig.baseUrl,
  });

  Future<List<User>> getUsers({
    required String projectId,
  }) async {
    try {
  
      final response = await _client.get(
        Uri.parse('$baseUrl/users?projectId=$projectId'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw UsersRepositoryException(
          'Failed to load users',
          response.statusCode,
        );
      }
    } catch (e) {
      throw UsersRepositoryException(_sanitizeError(e));
    }
  }

  Future<UserStats> getUserStats(
    String userId, {
    required String projectId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId/stats?projectId=$projectId'),
      );
      
      if (response.statusCode == 200) {
        return UserStats.fromJson(jsonDecode(response.body));
      } else {
        throw UsersRepositoryException(
          'Failed to load user stats',
          response.statusCode,
        );
      }
    } catch (e) {
      throw UsersRepositoryException(_sanitizeError(e));
    }
  }

  Future<List<UserSession>> getUserSessions(
    String userId, {
    required String projectId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$baseUrl/users/$userId/sessions?projectId=$projectId&limit=$limit&offset=$offset',
        ),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserSession.fromJson(json)).toList();
      } else {
        throw UsersRepositoryException(
          'Failed to load user sessions',
          response.statusCode,
        );
      }
    } catch (e) {
      throw UsersRepositoryException(_sanitizeError(e));
    }
  }
  
  Future<List<LogEntry>> getUserLogs(
    String userId, {
    required String projectId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$baseUrl/users/$userId/logs?projectId=$projectId&limit=$limit&offset=$offset',
        ),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LogEntry.fromJson(json)).toList();
      } else {
        throw UsersRepositoryException(
          'Failed to load user logs',
          response.statusCode,
        );
      }
    } catch (e) {
      throw UsersRepositoryException(_sanitizeError(e));
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

class UsersRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  UsersRepositoryException(this.message, [this.statusCode]);

  @override
  String toString() => message; // Clean message without prefix
}
