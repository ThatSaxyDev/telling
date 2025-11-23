import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db/database.dart';
import '../utils/helpers.dart';

class ProjectHandler {
  final _db = DatabaseService().db;

  Response getUserProjectsHandler(Request req) {
    // TODO: Extract user ID from token middleware
    final userId = req.headers['x-user-id'];
    if (userId == null) return Response.forbidden('Missing user context');

    final results = _db.select('SELECT * FROM projects WHERE user_id = ?', [
      userId,
    ]);

    final projects = results
        .map(
          (row) => {
            'id': row['id'],
            'name': row['name'],
            'apiKey': row['api_key'],
            'createdAt': row['created_at'],
          },
        )
        .toList();

    return Response.ok(jsonEncode(projects));
  }

  Future<Response> createProjectHandler(Request req) async {
    final userId = req.headers['x-user-id'];
    if (userId == null) return Response.forbidden('Missing user context');

    // Check project limit (Max 3)
    final countResult = _db.select(
      'SELECT COUNT(*) as count FROM projects WHERE user_id = ?',
      [userId],
    );
    final count = countResult.first['count'] as int;
    if (count >= 3) {
      return Response.forbidden('Project limit reached (Max 3)');
    }

    final payload = jsonDecode(await req.readAsString());
    final name = payload['name'] as String?;

    if (name == null) return Response.badRequest(body: 'Missing project name');

    final projectId = generateUuid();
    final apiKey = generateApiKey();
    final createdAt = DateTime.now().toIso8601String();

    _db.execute(
      'INSERT INTO projects (id, user_id, name, api_key, created_at) VALUES (?, ?, ?, ?, ?)',
      [projectId, userId, name, apiKey, createdAt],
    );

    return Response.ok(
      jsonEncode({
        'id': projectId,
        'name': name,
        'apiKey': apiKey,
        'createdAt': createdAt,
      }),
    );
  }

  Future<Response> deleteProjectHandler(Request req, String projectId) async {
    final userId = req.headers['x-user-id'];
    if (userId == null) return Response.forbidden('Missing user context');

    // Verify ownership
    final project = _db.select(
      'SELECT id FROM projects WHERE id = ? AND user_id = ?',
      [projectId, userId],
    );

    if (project.isEmpty) return Response.forbidden('Access denied');

    // Delete logs first (if no cascade)
    _db.execute('DELETE FROM logs WHERE project_id = ?', [projectId]);

    // Delete project
    _db.execute('DELETE FROM projects WHERE id = ?', [projectId]);

    return Response.ok(jsonEncode({'success': true}));
  }

  Response regenerateApiKeyHandler(Request req, String projectId) {
    final userId = req.headers['x-user-id'];
    if (userId == null) return Response.forbidden('Missing user context');

    // Verify ownership
    final project = _db.select(
      'SELECT id FROM projects WHERE id = ? AND user_id = ?',
      [projectId, userId],
    );

    if (project.isEmpty) return Response.forbidden('Access denied');

    final newKey = generateApiKey();
    _db.execute('UPDATE projects SET api_key = ? WHERE id = ?', [
      newKey,
      projectId,
    ]);

    return Response.ok(jsonEncode({'apiKey': newKey}));
  }
}
