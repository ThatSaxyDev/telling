import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/log_entry.dart';

class UsersRepository {
  final String baseUrl;

  UsersRepository({this.baseUrl = 'http://localhost:8080/api/v1'});

  Future<List<User>> getUsers({
    required String projectId,
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users?projectId=$projectId'),
        headers: {'x-user-id': userId},
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

  Future<UserStats> getUserStats(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/stats'));
      
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
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/users/$userId/sessions?limit=$limit&offset=$offset',
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
  
  Future<List<LogEntry>> getUserLogs(String userId, {int limit = 100, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/logs?limit=$limit&offset=$offset'),
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
