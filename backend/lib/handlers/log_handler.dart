import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db/database.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class LogHandler {
  final _db = DatabaseService().db;
  final Map<String, DateTime> _recentLogs = {};

  Future<Response> postLogsHandler(Request req) async {
    try {
      // Validate API Key
      final apiKey = req.headers['x-api-key'];
      if (apiKey == null) {
        return Response.forbidden('Missing API Key');
      }

      final projectResult = _db.select(
        'SELECT id FROM projects WHERE api_key = ?',
        [apiKey],
      );
      if (projectResult.isEmpty) {
        return Response.forbidden('Invalid API Key');
      }
      final projectId = projectResult.first['id'] as String;

      final payload = await req.readAsString();
      final List<dynamic> events = jsonDecode(payload);

      final stmt = _db.prepare(
        'INSERT INTO logs (project_id, type, level, message, timestamp, stack_trace, metadata, device, received_at, user_id, user_name, user_email, session_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      );

      int saved = 0;
      int duplicates = 0;

      for (var event in events) {
        if (event is Map<String, dynamic>) {
          // Normalize level/type...
          String level = event['level'] ?? 'info';
          if (!validLogLevels.contains(level.toLowerCase())) {
            print('Warning: Invalid log level "$level", defaulting to "info"');
            level = 'info';
          }

          String type = event['type'] ?? 'general';
          final typeLower = type.toLowerCase();
          if (!validLogTypes.contains(typeLower)) {
            print('Warning: Invalid log type "$type", defaulting to "general"');
            type = 'general';
          } else {
            // Map legacy values
            if (typeLower == 'log' ||
                typeLower == 'error' ||
                typeLower == 'errorr') {
              type = 'general';
              print('Info: Mapping legacy type "${event['type']}" to "general"');
            }
          }

          // Dedupe check
          final hash = hashLogEvent(event);
          final lastSeen = _recentLogs[hash];
          final now = DateTime.now();

          if (lastSeen != null &&
              now.difference(lastSeen).inSeconds < dedupeWindowSeconds) {
            duplicates++;
            continue;
          }

          stmt.execute([
            projectId, // Link to project
            type,
            level,
            event['message'] ?? '',
            event['timestamp'] ?? DateTime.now().toIso8601String(),
            event['stackTrace'],
            event['metadata'] != null ? jsonEncode(event['metadata']) : null,
            event['device'] != null ? jsonEncode(event['device']) : null,
            DateTime.now().toIso8601String(),
            event['userId'],
            event['userName'],
            event['userEmail'],
            event['sessionId'],
          ]);

          _recentLogs[hash] = now;
          saved++;
        }
      }
      stmt.dispose();

      return Response.ok(
        jsonEncode({
          'status': 'success',
          'saved': saved,
          'duplicates': duplicates,
        }),
      );
    } catch (e) {
      print('Error processing logs: $e');
      return Response.internalServerError(body: 'Error processing logs');
    }
  }

  Response getLogsHandler(Request req) {
    try {
      final userId = req.context['userId'] as String?;
      if (userId == null) return Response.forbidden('Missing user context');

      final params = req.url.queryParameters;
      final projectId = params['projectId'];

      if (projectId == null) {
        return Response.badRequest(body: 'Missing projectId');
      }

      // Verify project ownership
      final projectCheck = _db.select(
        'SELECT id FROM projects WHERE id = ? AND user_id = ?',
        [projectId, userId],
      );
      if (projectCheck.isEmpty) {
        return Response.forbidden('Access denied to project');
      }

      final page = int.tryParse(params['page'] ?? '1') ?? 1;
      final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
      final offset = (page - 1) * limit;
      final filterUserId = params['userId'];

      String query = 'SELECT * FROM logs WHERE project_id = ?';
      List<Object?> queryParams = [projectId];

      if (filterUserId != null && filterUserId.isNotEmpty) {
        query += ' AND user_id = ?';
        queryParams.add(filterUserId);
      }

      query += ' ORDER BY id DESC LIMIT ? OFFSET ?';
      queryParams.addAll([limit, offset]);

      final results = _db.select(query, queryParams);

      final logs = results.map((row) {
        return {
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
        };
      }).toList();

      return Response.ok(
        jsonEncode(logs),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('Error fetching logs: $e');
      return Response.internalServerError(body: 'Error fetching logs');
    }
  }

  void cleanup() {
    final now = DateTime.now();
    _recentLogs.removeWhere(
      (hash, time) => now.difference(time).inSeconds > dedupeWindowSeconds,
    );
  }
}
