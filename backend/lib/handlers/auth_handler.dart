import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../db/database.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class AuthHandler {
  final _db = DatabaseService().db;

  // Helper to generate JWT
  String _generateJwt(String userId, String email) {
    final jwt = JWT({
      'sub': userId,
      'email': email,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }, issuer: jwtIssuer);
    return jwt.sign(SecretKey(jwtSecret), expiresIn: Duration(days: 7));
  }

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
      final existing = await _db.getAll(
        'SELECT id FROM users WHERE email = ?',
        [
        email,
      ]);
      if (existing.isNotEmpty) {
        return Response.badRequest(body: 'User already exists');
      }

      // Hash password (simple hash for demo - use bcrypt in prod)
      // TODO: Add salt
      final passwordHash = sha256.convert(utf8.encode(password)).toString();
      final userId = generateUuid();

      await _db.execute(
        'INSERT INTO users (id, email, password_hash, name, created_at) VALUES (?, ?, ?, ?, ?)',
        [userId, email, passwordHash, name, DateTime.now().toIso8601String()],
      );

      // Create default project
      // final projectId = generateUuid();
      // final apiKey = generateApiKey();
      // await _db.execute(
      //   'INSERT INTO projects (id, user_id, name, api_key, created_at) VALUES (?, ?, ?, ?, ?)',
      //   [
      //     projectId,
      //     userId,
      //     'Default Project',
      //     apiKey,
      //     DateTime.now().toIso8601String(),
      //   ],
      // );

      final token = _generateJwt(userId, email);

      return Response.ok(
        jsonEncode({
          'token': token,
          'user': {'id': userId, 'email': email, 'name': name},
          // 'defaultProject': {'id': projectId, 'apiKey': apiKey},
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
      final results = await _db.getAll(
        'SELECT id, name FROM users WHERE email = ? AND password_hash = ?',
        [email, passwordHash],
      );

      if (results.isEmpty) {
        return Response.forbidden('Invalid credentials');
      }

      final user = results.first;
      final userId = user['id'] as String;
      final token = _generateJwt(userId, email);

      return Response.ok(
        jsonEncode({
          'token': token,
          'user': {'id': userId, 'email': email, 'name': user['name']},
        }),
      );
    } catch (e) {
      return Response.internalServerError(body: 'Login failed');
    }
  }
}
