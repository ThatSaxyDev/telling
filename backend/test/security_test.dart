import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  final baseUrl = 'http://localhost:8080';

  test('Root endpoint should be public', () async {
    final response = await http.get(Uri.parse('$baseUrl/'));
    expect(response.statusCode, 200);
    expect(response.body, contains('Telling Backend API'));
  });

  test('Protected endpoint should return 403 without token', () async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/projects'));
    expect(response.statusCode, 403);
  });

  test('Full Auth Flow: Register -> Login -> Access Protected', () async {
    // 1. Register
    final email = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final registerRes = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      body: jsonEncode({
        'email': email,
        'password': 'password123',
        'name': 'Test User',
      }),
    );
    expect(registerRes.statusCode, 200);
    final registerData = jsonDecode(registerRes.body);
    final token = registerData['token'] as String;
    expect(token, isNotEmpty);

    // 2. Access Protected with Token
    final projectsRes = await http.get(
      Uri.parse('$baseUrl/api/v1/projects'),
      headers: {'Authorization': 'Bearer $token'},
    );
    expect(projectsRes.statusCode, 200);
    final projects = jsonDecode(projectsRes.body) as List;
    expect(projects.length, 1); // Default project
    expect(projects[0]['name'], 'Default Project');
  });
}
