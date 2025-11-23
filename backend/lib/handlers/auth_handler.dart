import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:crypto/crypto.dart';
import '../db/database.dart';
import '../utils/helpers.dart';

class AuthHandler {
  final _db = DatabaseService().db;

  Future<Response> registerHandler(Request req) async {
    try {
      final payload = jsonDecode(await req.readAsString());
      final email = payload['email'] as String?;
      final password = payload['password'] as String?;
      final name = payload['name'] as String?;

      if (email == null || password == null || name == null) {
        return Response.badRequest(body: 'Missing required fields');
      }

      // Check if user exists
      final existing = _db.select('SELECT id FROM users WHERE email = ?', [
        email,
      ]);
      if (existing.isNotEmpty) {
        return Response.badRequest(body: 'User already exists');
      }

      // Hash password (simple hash for demo - use bcrypt in prod)
      final passwordHash = sha256.convert(utf8.encode(password)).toString();
      final userId = generateUuid();

      _db.execute(
        'INSERT INTO users (id, email, password_hash, name, created_at) VALUES (?, ?, ?, ?, ?)',
        [userId, email, passwordHash, name, DateTime.now().toIso8601String()],
      );

      // Create default project
      final projectId = generateUuid();
      final apiKey = generateApiKey();
      _db.execute(
        'INSERT INTO projects (id, user_id, name, api_key, created_at) VALUES (?, ?, ?, ?, ?)',
        [
          projectId,
          userId,
          'Default Project',
          apiKey,
          DateTime.now().toIso8601String(),
        ],
      );

      return Response.ok(
        jsonEncode({
          'token': userId, // Simple token for demo (use JWT in prod)
          'user': {'id': userId, 'email': email, 'name': name},
          'defaultProject': {'id': projectId, 'apiKey': apiKey},
        }),
      );
    } catch (e) {
      print('Register error: $e');
      return Response.internalServerError(body: 'Registration failed');
    }
  }

  Future<Response> loginHandler(Request req) async {
    try {
      final payload = jsonDecode(await req.readAsString());
      final email = payload['email'] as String?;
      final password = payload['password'] as String?;

      if (email == null || password == null) {
        return Response.badRequest(body: 'Missing credentials');
      }

      final passwordHash = sha256.convert(utf8.encode(password)).toString();
      final results = _db.select(
        'SELECT id, name FROM users WHERE email = ? AND password_hash = ?',
        [email, passwordHash],
      );

      if (results.isEmpty) {
        return Response.forbidden('Invalid credentials');
      }

      final user = results.first;
      return Response.ok(
        jsonEncode({
          'token': user['id'], // Simple token
          'user': {'id': user['id'], 'email': email, 'name': user['name']},
        }),
      );
    } catch (e) {
      return Response.internalServerError(body: 'Login failed');
    }
  }
}
