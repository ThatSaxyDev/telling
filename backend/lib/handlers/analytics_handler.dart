import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db/database.dart';

class AnalyticsHandler {
  final _db = DatabaseService().db;

  Future<Response> getStatsHandler(Request req) async {
    try {
      final userId = req.context['userId'] as String?;
      if (userId == null) return Response.forbidden('Missing user context');

      final projectId = req.url.queryParameters['projectId'];
      if (projectId == null)
        return Response.badRequest(body: 'Missing projectId');

      // Verify ownership
      final projectCheck = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, userId],
      );
      if (projectCheck.isEmpty) return Response.forbidden('Access denied');

      final totalResult = await _db.getAll(
        'SELECT COUNT(*) as count FROM logs WHERE project_id = ?',
        [projectId],
      );
      final total = totalResult.first['count'] as int;

      final errorResult = await _db.getAll(
        "SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND level IN ('error', 'fatal')",
        [projectId],
      );
      final errorCount = errorResult.first['count'] as int;

      final warningResult = await _db.getAll(
        "SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND level = 'warning'",
        [projectId],
      );
      final warningCount = warningResult.first['count'] as int;

      final eventResult = await _db.getAll(
        "SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND type IN ('event', 'analytics')",
        [projectId],
      );
      final eventCount = eventResult.first['count'] as int;

      final performanceResult = await _db.getAll(
        "SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND type = 'performance'",
        [projectId],
      );
      final performanceCount = performanceResult.first['count'] as int;

      final stats = {
        'totalLogs': total,
        'errorCount': errorCount,
        'warningCount': warningCount,
        'eventCount': eventCount,
        'performanceCount': performanceCount,
      };

      return Response.ok(
        jsonEncode(stats),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('Error fetching stats: $e');
      return Response.internalServerError(body: 'Error fetching stats');
    }
  }

  Future<Response> getAnalyticsSummaryHandler(Request req) async {
    try {
      final userId = req.context['userId'] as String?;
      if (userId == null) return Response.forbidden('Missing user context');

      final projectId = req.url.queryParameters['projectId'];
      if (projectId == null)
        return Response.badRequest(body: 'Missing projectId');

      // Verify ownership
      final projectCheck = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, userId],
      );
      if (projectCheck.isEmpty) return Response.forbidden('Access denied');

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

      final todayLogsResult = await _db.getAll(
        'SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND timestamp >= ?',
        [projectId, todayStart],
      );
      final todayLogs = todayLogsResult.first['count'] as int;

      final todayErrorsResult = await _db.getAll(
        "SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND timestamp >= ? AND level IN ('error', 'fatal')",
        [projectId, todayStart],
      );
      final todayErrors = todayErrorsResult.first['count'] as int;

      final activeUsersResult = await _db.getAll(
        'SELECT COUNT(DISTINCT user_id) as count FROM logs WHERE project_id = ? AND timestamp >= ? AND user_id IS NOT NULL',
        [projectId, todayStart],
      );
      final activeUsers = activeUsersResult.first['count'] as int;

      return Response.ok(
        jsonEncode({
          'todayLogs': todayLogs,
          'todayErrors': todayErrors,
          'activeUsers': activeUsers,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('Error fetching analytics summary: $e');
      return Response.internalServerError(
        body: 'Error fetching analytics summary',
      );
    }
  }

  Future<Response> getLogsTimelineHandler(Request req) async {
    try {
      final userId = req.context['userId'] as String?;
      if (userId == null) return Response.forbidden('Missing user context');

      final projectId = req.url.queryParameters['projectId'];
      if (projectId == null)
        return Response.badRequest(body: 'Missing projectId');

      // Verify ownership
      final projectCheck = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, userId],
      );
      if (projectCheck.isEmpty) return Response.forbidden('Access denied');

      // Group by hour for the last 24 hours
      final now = DateTime.now();
      final twentyFourHoursAgo = now
          .subtract(Duration(hours: 24))
          .toIso8601String();

      final results = await _db.getAll(
        '''
        SELECT 
          strftime('%Y-%m-%dT%H:00:00', timestamp) as hour,
          COUNT(*) as count
        FROM logs 
        WHERE project_id = ? AND timestamp >= ?
        GROUP BY hour
        ORDER BY hour ASC
        ''',
        [projectId, twentyFourHoursAgo],
      );

      final timeline = results
          .map((row) => {'time': row['hour'], 'count': row['count']})
          .toList();

      return Response.ok(
        jsonEncode(timeline),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('Error fetching timeline: $e');
      return Response.internalServerError(body: 'Error fetching timeline');
    }
  }

  Future<Response> getLogLevelsHandler(Request req) async {
    try {
      final userId = req.context['userId'] as String?;
      if (userId == null) return Response.forbidden('Missing user context');

      final projectId = req.url.queryParameters['projectId'];
      if (projectId == null)
        return Response.badRequest(body: 'Missing projectId');

      // Verify ownership
      final projectCheck = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, userId],
      );
      if (projectCheck.isEmpty) return Response.forbidden('Access denied');

      final results = await _db.getAll(
        'SELECT level, COUNT(*) as count FROM logs WHERE project_id = ? GROUP BY level',
        [projectId],
      );

      final levels = results
          .map((row) => {'level': row['level'], 'count': row['count']})
          .toList();

      return Response.ok(
        jsonEncode(levels),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('Error fetching log levels: $e');
      return Response.internalServerError(body: 'Error fetching log levels');
    }
  }

  Future<Response> getTopErrorsHandler(Request req) async {
    try {
      final userId = req.context['userId'] as String?;
      if (userId == null) return Response.forbidden('Missing user context');

      final params = req.url.queryParameters;
      final projectId =
          params['projectId']; // Assuming projectId is needed for context, though not explicitly used in query before?
      // Wait, getTopErrorsHandler previously didn't check project ownership! It just queried ALL logs.
      // That's a bug in the previous implementation. I should fix it now.
      // It needs to filter by project_id.

      if (projectId == null) {
        // If no project ID, maybe it was intended for all user's projects?
        // For now, let's enforce projectId to be safe.
        return Response.badRequest(body: 'Missing projectId');
      }

      // Verify ownership
      final projectCheck = await _db.getAll(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, userId],
      );
      if (projectCheck.isEmpty) return Response.forbidden('Access denied');

      final hours = int.tryParse(params['hours'] ?? '24') ?? 24;
      final limit = int.tryParse(params['limit'] ?? '10') ?? 10;
      final now = DateTime.now();
      final startTime = now.subtract(Duration(hours: hours));

      final results = await _db.getAll(
        '''
        SELECT 
          message,
          COUNT(*) as count,
          MAX(timestamp) as last_seen
        FROM logs
        WHERE project_id = ? AND level IN (?, ?) AND timestamp >= ?
        GROUP BY message
        ORDER BY count DESC
        LIMIT ?
      ''',
        [projectId, 'error', 'fatal', startTime.toIso8601String(), limit],
      );

      final topErrors = results.map((row) {
        return {
          'message': row['message'],
          'count': row['count'],
          'lastSeen': row['last_seen'],
        };
      }).toList();

      return Response.ok(
        jsonEncode(topErrors),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }
}
