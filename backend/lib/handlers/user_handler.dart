import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db/database.dart';

class UserHandler {
  final _db = DatabaseService().db;

  Future<Response> getActiveUsersHandler(Request req) async {
    try {
      // Validate user context
      final userId = req.context['userId'] as String?;
      if (userId == null) return Response.forbidden('Missing user context');

      final params = req.url.queryParameters;
      final projectId = params['projectId'];
      if (projectId == null) {
        return Response.badRequest(body: 'Missing projectId');
      }

      // Verify project ownership
      final project = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, userId],
      );
      if (project.isEmpty) return Response.forbidden('Access denied');

      final hours = int.tryParse(params['hours'] ?? '24') ?? 24;
      final limit = int.tryParse(params['limit'] ?? '10') ?? 10;
      final now = DateTime.now();
      final startTime = now.subtract(Duration(hours: hours));

      final results = await _db.getAll(
        '''
        SELECT 
          user_id,
          user_name,
          user_email,
          COUNT(*) as log_count,
          MAX(timestamp) as last_active
        FROM logs
        WHERE timestamp >= ? AND user_id IS NOT NULL AND project_id = ?
        GROUP BY user_id
        ORDER BY log_count DESC
        LIMIT ?
      ''',
        [startTime.toIso8601String(), projectId, limit],
      );

      final activeUsers = results.map((row) {
        return {
          'userId': row['user_id'],
          'userName': row['user_name'],
          'userEmail': row['user_email'],
          'logCount': row['log_count'],
          'lastActive': row['last_active'],
        };
      }).toList();

      return Response.ok(
        jsonEncode(activeUsers),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }

  Future<Response> getUserLogsHandler(Request req, String userId) async {
    // Note: userId here is the target user ID (the one whose logs we want),
    // NOT the authenticated admin user ID.
    // We need to verify that the authenticated admin owns the project that these logs belong to.
    // However, this endpoint doesn't take a projectId param in the URL?
    // It seems to be fetching logs for a user across ALL projects? Or just one?
    // The previous implementation didn't check project ownership!
    // It just fetched logs by user_id.
    // We should probably require a projectId here too, or check if the target user has logs in any of the admin's projects.

    // For now, let's assume we need to pass a projectId to scope this.
    // Or, we can check if the authenticated user owns ANY project that has logs for this target user.
    
    try {
      final authUserId = req.context['userId'] as String?;
      if (authUserId == null) return Response.forbidden('Missing user context');

      // TODO: Improve this security model. For now, requiring projectId is safer.
      final projectId = req.url.queryParameters['projectId'];
      if (projectId == null) {
        // Fallback: Check if authUser owns the project associated with the logs?
        // But we are querying logs.
        // Let's require projectId for now to be safe and consistent.
        return Response.badRequest(body: 'Missing projectId');
      }

      // Verify ownership
      final project = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, authUserId],
      );
      if (project.isEmpty) return Response.forbidden('Access denied');

      final limit =
          int.tryParse(req.url.queryParameters['limit'] ?? '100') ?? 100;
      final offset = int.tryParse(req.url.queryParameters['offset'] ?? '0') ?? 0;

      final results = await _db.getAll(
        '''
        SELECT * FROM logs
        WHERE user_id = ? AND project_id = ?
        ORDER BY id DESC
        LIMIT ? OFFSET ?
      ''',
        [userId, projectId, limit, offset],
      );

      final logs = results
          .map(
            (row) => {
              'id': row['id'],
              'type': row['type'],
              'level': row['level'],
              'message': row['message'],
              'timestamp': row['timestamp'],
              'stackTrace': row['stack_trace'],
              'metadata': row['metadata'] != null
                  ? jsonDecode(row['metadata'])
                  : null,
              'device': row['device'] != null ? jsonDecode(row['device']) : null,
              'userId': row['user_id'],
              'userName': row['user_name'],
              'userEmail': row['user_email'],
              'sessionId': row['session_id'],
              'projectId': row['project_id'],
            },
          )
          .toList();

      return Response.ok(jsonEncode(logs));
    } catch (e) {
      print('Error fetching user logs: $e');
      return Response.internalServerError(body: 'Error fetching user logs');
    }
  }

  Future<Response> getUserStatsHandler(Request req, String userId) async {
    try {
      final authUserId = req.context['userId'] as String?;
      if (authUserId == null) return Response.forbidden('Missing user context');

      final projectId = req.url.queryParameters['projectId'];
      if (projectId == null)
        return Response.badRequest(body: 'Missing projectId');

      // Verify ownership
      final project = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, authUserId],
      );
      if (project.isEmpty) return Response.forbidden('Access denied');

      final totalLogs = (await _db.getAll(
        'SELECT COUNT(*) as count FROM logs WHERE user_id = ? AND project_id = ?',
        [userId, projectId],
      )).first['count'];

      final errorCount = (await _db.getAll(
        'SELECT COUNT(*) as count FROM logs WHERE user_id = ? AND project_id = ? AND (level = "error" OR level = "fatal")',
        [userId, projectId],
      )).first['count'];

      final sessionCount = (await _db.getAll(
        'SELECT COUNT(DISTINCT session_id) as count FROM logs WHERE user_id = ? AND project_id = ? AND session_id IS NOT NULL',
        [userId, projectId],
      )).first['count'];

      final lastActive = (await _db.getAll(
        'SELECT MAX(received_at) as last_seen FROM logs WHERE user_id = ? AND project_id = ?',
        [userId, projectId],
      )).first['last_seen'];

      return Response.ok(
        jsonEncode({
          'totalLogs': totalLogs,
          'errorCount': errorCount,
          'sessionCount': sessionCount,
          'lastActive': lastActive,
        }),
      );
    } catch (e) {
      print('Error fetching user stats: $e');
      return Response.internalServerError(body: 'Error fetching user stats');
    }
  }

  Future<Response> getUserSessionsHandler(Request req, String userId) async {
    try {
      final authUserId = req.context['userId'] as String?;
      if (authUserId == null) return Response.forbidden('Missing user context');

      final projectId = req.url.queryParameters['projectId'];
      if (projectId == null)
        return Response.badRequest(body: 'Missing projectId');

      // Verify ownership
      final project = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, authUserId],
      );
      if (project.isEmpty) return Response.forbidden('Access denied');

      // Get all session start events for this user
      final results = await _db.getAll(
        '''
        SELECT session_id, MIN(timestamp) as start_time, MAX(timestamp) as end_time, COUNT(*) as event_count
        FROM logs
        WHERE user_id = ? AND project_id = ? AND session_id IS NOT NULL
        GROUP BY session_id
        ORDER BY start_time DESC
        LIMIT 50
      ''',
        [userId, projectId],
      );

      final sessions = results.map((row) {
        final start = DateTime.parse(row['start_time']);
        final end = DateTime.parse(row['end_time']);
        final duration = end.difference(start).inSeconds;

        return {
          'sessionId': row['session_id'],
          'startTime': row['start_time'],
          'endTime': row['end_time'],
          'durationSeconds': duration,
          'eventCount': row['event_count'],
        };
      }).toList();

      return Response.ok(jsonEncode(sessions));
    } catch (e) {
      print('Error fetching user sessions: $e');
      return Response.internalServerError(body: 'Error fetching user sessions');
    }
  }

  Future<Response> getSessionsHandler(Request req) async {
    try {
      final authUserId = req.context['userId'] as String?;
      if (authUserId == null) return Response.forbidden('Missing user context');

      final projectId = req.url.queryParameters['projectId'];
      if (projectId == null)
        return Response.badRequest(body: 'Missing projectId');

      // Verify ownership
      final project = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, authUserId],
      );
      if (project.isEmpty) return Response.forbidden('Access denied');

      final limit = int.tryParse(req.url.queryParameters['limit'] ?? '50') ?? 50;
      final offset = int.tryParse(req.url.queryParameters['offset'] ?? '0') ?? 0;

      final results = await _db.getAll(
        '''
        SELECT 
          session_id, 
          user_id,
          user_name,
          MIN(timestamp) as start_time, 
          MAX(timestamp) as end_time, 
          COUNT(*) as event_count
        FROM logs
        WHERE session_id IS NOT NULL AND project_id = ?
        GROUP BY session_id
        ORDER BY start_time DESC
        LIMIT ? OFFSET ?
      ''',
        [projectId, limit, offset],
      );

      final sessions = results.map((row) {
        final start = DateTime.parse(row['start_time']);
        final end = DateTime.parse(row['end_time']);
        final duration = end.difference(start).inSeconds;

        return {
          'sessionId': row['session_id'],
          'userId': row['user_id'],
          'userName': row['user_name'],
          'startTime': row['start_time'],
          'endTime': row['end_time'],
          'durationSeconds': duration,
          'eventCount': row['event_count'],
        };
      }).toList();

      return Response.ok(jsonEncode(sessions));
    } catch (e) {
      print('Error fetching sessions: $e');
      return Response.internalServerError(body: 'Error fetching sessions');
    }
  }

  Future<Response> getSessionLogsHandler(Request req, String sessionId) async {
    print('Fetching logs for session: $sessionId');
    try {
      final authUserId = req.context['userId'] as String?;
      if (authUserId == null) return Response.forbidden('Missing user context');

      final projectId = req.url.queryParameters['projectId'];
      if (projectId == null)
        return Response.badRequest(body: 'Missing projectId');

      // Verify ownership
      final project = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, authUserId],
      );
      if (project.isEmpty) return Response.forbidden('Access denied');

      final results = await _db.getAll(
        '''
        SELECT * FROM logs
        WHERE session_id = ? AND project_id = ?
        ORDER BY timestamp ASC
      ''',
        [sessionId, projectId],
      );

      print('Found ${results.length} logs for session $sessionId');

      final logs = results
          .map(
            (row) => {
              'id': row['id'],
              'timestamp': row['timestamp'],
              'level': row['level'],
              'message': row['message'],
              'type': row['type'],
              'metadata': row['metadata'] != null
                  ? jsonDecode(row['metadata'] as String)
                  : {},
              'device': row['device'] != null
                  ? jsonDecode(row['device'] as String)
                  : {},
              'stackTrace': row['stack_trace'],
              'userId': row['user_id'],
              'sessionId': row['session_id'],
              'projectId': row['project_id'],
            },
          )
          .toList();

      return Response.ok(jsonEncode(logs));
    } catch (e, stack) {
      print('Error fetching session logs: $e');
      print(stack);
      return Response.internalServerError(body: 'Error fetching session logs');
    }
  }
}
