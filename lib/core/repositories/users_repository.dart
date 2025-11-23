import 'dart:convert';
import '../services/api_client.dart';
import '../models/user.dart';
import '../models/log_entry.dart';

class UsersRepository {
  final ApiClient _client;
  final String baseUrl;

  UsersRepository(
    this._client, {
    this.baseUrl = 'http://localhost:8080/api/v1',
  });

  Future<List<User>> getUsers({
    required String projectId,
  }) async {
    try {
      // Note: x-user-id is no longer needed as it's extracted from the JWT token
      final response = await _client.get(
        Uri.parse('$baseUrl/users?projectId=$projectId'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
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
        throw Exception('Failed to load user stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
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
        throw Exception('Failed to load user sessions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
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
        throw Exception('Failed to load user logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
