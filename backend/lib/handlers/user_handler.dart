import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db/database.dart';

class UserHandler {
  final _db = DatabaseService().db;

  Response getActiveUsersHandler(Request req) {
    try {
      // Validate user context
      final userId = req.headers['x-user-id'];
      if (userId == null) return Response.forbidden('Missing user context');

      final params = req.url.queryParameters;
      final projectId = params['projectId'];
      if (projectId == null) {
        return Response.badRequest(body: 'Missing projectId');
      }

      // Verify project ownership
      final project = _db.select(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, userId],
      );
      if (project.isEmpty) return Response.forbidden('Access denied');

      final hours = int.tryParse(params['hours'] ?? '24') ?? 24;
      final limit = int.tryParse(params['limit'] ?? '10') ?? 10;
      final now = DateTime.now();
      final startTime = now.subtract(Duration(hours: hours));

      final results = _db.select(
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

  Response getUserLogsHandler(Request req, String userId) {
    try {
      final limit =
          int.tryParse(req.url.queryParameters['limit'] ?? '100') ?? 100;
      final offset = int.tryParse(req.url.queryParameters['offset'] ?? '0') ?? 0;

      final results = _db.select(
        '''
        SELECT * FROM logs
        WHERE user_id = ?
        ORDER BY id DESC
        LIMIT ? OFFSET ?
      ''',
        [userId, limit, offset],
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

  Response getUserStatsHandler(Request req, String userId) {
    try {
      final totalLogs = _db.select(
        'SELECT COUNT(*) as count FROM logs WHERE user_id = ?',
        [userId],
      ).first['count'];

      final errorCount = _db.select(
        'SELECT COUNT(*) as count FROM logs WHERE user_id = ? AND (level = "error" OR level = "fatal")',
        [userId],
      ).first['count'];

      final sessionCount = _db.select(
        'SELECT COUNT(DISTINCT session_id) as count FROM logs WHERE user_id = ? AND session_id IS NOT NULL',
        [userId],
      ).first['count'];

      final lastActive = _db.select(
        'SELECT MAX(received_at) as last_seen FROM logs WHERE user_id = ?',
        [userId],
      ).first['last_seen'];

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

  Response getUserSessionsHandler(Request req, String userId) {
    try {
      // Get all session start events for this user
      final results = _db.select(
        '''
        SELECT session_id, MIN(timestamp) as start_time, MAX(timestamp) as end_time, COUNT(*) as event_count
        FROM logs
        WHERE user_id = ? AND session_id IS NOT NULL
        GROUP BY session_id
        ORDER BY start_time DESC
        LIMIT 50
      ''',
        [userId],
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

  Response getSessionsHandler(Request req) {
    try {
      final limit = int.tryParse(req.url.queryParameters['limit'] ?? '50') ?? 50;
      final offset = int.tryParse(req.url.queryParameters['offset'] ?? '0') ?? 0;

      final results = _db.select(
        '''
        SELECT 
          session_id, 
          user_id,
          user_name,
          MIN(timestamp) as start_time, 
          MAX(timestamp) as end_time, 
          COUNT(*) as event_count
        FROM logs
        WHERE session_id IS NOT NULL
        GROUP BY session_id
        ORDER BY start_time DESC
        LIMIT ? OFFSET ?
      ''',
        [limit, offset],
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

  Response getSessionLogsHandler(Request req, String sessionId) {
    print('Fetching logs for session: $sessionId');
    try {
      final results = _db.select(
        '''
        SELECT * FROM logs
        WHERE session_id = ?
        ORDER BY timestamp ASC
      ''',
        [sessionId],
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
