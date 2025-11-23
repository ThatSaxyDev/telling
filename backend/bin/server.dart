import 'dart:convert';
import 'dart:async';
import 'dart:math';


import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:crypto/crypto.dart';

// Database instance
late final Database _db;

// Validation constants
const validLogLevels = {'trace', 'debug', 'info', 'warning', 'error', 'fatal'};
const validLogTypes = {
  'general',
  'analytics',
  'event',
  'performance',
  'network',
  'security',
  'exception',
  'crash',
  'custom',
  // Legacy support
  'log', // Maps to 'general'
  'error', // Maps to 'general'
  'errorr', // Maps to 'general' (typo fix)
};

// Rate limiting state
final Map<String, List<DateTime>> _requestTimestamps = {};
const maxRequestsPerMinute = 100;

// Duplicate detection cache
final Map<String, DateTime> _recentLogs = {};
const dedupeWindowSeconds = 10;

// Configure routes
final _router = Router()
  ..get('/', _rootHandler)
  // Auth Routes
  ..post('/api/v1/auth/register', _registerHandler)
  ..post('/api/v1/auth/login', _loginHandler)
  // Project Routes
  ..get('/api/v1/projects', _getUserProjectsHandler)
  ..post('/api/v1/projects', _createProjectHandler)
  ..delete('/api/v1/projects/<projectId>', _deleteProjectHandler)
  ..post('/api/v1/projects/<projectId>/keys', _regenerateApiKeyHandler)
  // Log Ingestion (Secured by API Key)
  ..post('/api/v1/logs', _postLogsHandler)
  // Analytics Routes (Secured by User Auth - TODO: Add middleware)
  ..get('/api/v1/logs', _getLogsHandler)
  ..get('/api/v1/stats', _getStatsHandler)
  ..get('/api/v1/users', _getActiveUsersHandler)
  ..get('/api/v1/users/<userId>/logs', _getUserLogsHandler)
  ..get('/api/v1/users/<userId>/stats', _getUserStatsHandler)
  ..get('/api/v1/users/<userId>/sessions', _getUserSessionsHandler)
  ..get('/api/v1/sessions', _getSessionsHandler)
  ..get('/api/v1/sessions/<sessionId>/logs', _getSessionLogsHandler)
  ..get('/api/v1/analytics/summary', _getAnalyticsSummaryHandler)
  ..get('/api/v1/analytics/timeline', _getLogsTimelineHandler)
  ..get('/api/v1/analytics/levels', _getLogLevelsHandler)
  ..get('/api/v1/analytics/errors', _getTopErrorsHandler)
  ..get('/api/v1/analytics/users', _getActiveUsersHandler);

Response _rootHandler(Request req) {
  return Response.ok('Telling Backend API v2.0.0 (Secured)\n');
}

// ===== Authentication Handlers =====

Future<Response> _registerHandler(Request req) async {
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
    final userId = _generateUuid();

    _db.execute(
      'INSERT INTO users (id, email, password_hash, name, created_at) VALUES (?, ?, ?, ?, ?)',
      [userId, email, passwordHash, name, DateTime.now().toIso8601String()],
    );

    // Create default project
    final projectId = _generateUuid();
    final apiKey = _generateApiKey();
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

Future<Response> _loginHandler(Request req) async {
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

// ===== Project Handlers =====

Response _getUserProjectsHandler(Request req) {
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

Future<Response> _createProjectHandler(Request req) async {
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

  final projectId = _generateUuid();
  final apiKey = _generateApiKey();
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

Future<Response> _deleteProjectHandler(Request req, String projectId) async {
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

Response _regenerateApiKeyHandler(Request req, String projectId) {
  final userId = req.headers['x-user-id'];
  if (userId == null) return Response.forbidden('Missing user context');

  // Verify ownership
  final project = _db.select(
    'SELECT id FROM projects WHERE id = ? AND user_id = ?',
    [projectId, userId],
  );

  if (project.isEmpty) return Response.forbidden('Access denied');

  final newKey = _generateApiKey();
  _db.execute('UPDATE projects SET api_key = ? WHERE id = ?', [
    newKey,
    projectId,
  ]);

  return Response.ok(jsonEncode({'apiKey': newKey}));
}

// ===== Log Ingestion =====

Future<Response> _postLogsHandler(Request req) async {
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
        final hash = _hashLogEvent(event);
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

// ===== Analytics Handlers =====
// For now, these handlers will query ALL logs.
// In a real scenario, we'd add `WHERE project_id IN (SELECT id FROM projects WHERE user_id = ?)`
// based on the authenticated user's projects.

Response _getLogsHandler(Request req) {
  try {
    final userId = req.headers['x-user-id'];
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

Response _getStatsHandler(Request req) {
  try {
    final userId = req.headers['x-user-id'];
    if (userId == null) return Response.forbidden('Missing user context');

    final projectId = req.url.queryParameters['projectId'];
    if (projectId == null)
      return Response.badRequest(body: 'Missing projectId');

    // Verify ownership
    final projectCheck = _db.select(
      'SELECT id FROM projects WHERE id = ? AND user_id = ?',
      [projectId, userId],
    );
    if (projectCheck.isEmpty) return Response.forbidden('Access denied');

    final totalResult = _db.select(
      'SELECT COUNT(*) as count FROM logs WHERE project_id = ?',
      [projectId],
    );
    final total = totalResult.first['count'] as int;

    final errorResult = _db.select(
      "SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND level IN ('error', 'fatal')",
      [projectId],
    );
    final errorCount = errorResult.first['count'] as int;

    final warningResult = _db.select(
      "SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND level = 'warning'",
      [projectId],
    );
    final warningCount = warningResult.first['count'] as int;

    final eventResult = _db.select(
      "SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND type IN ('event', 'analytics')",
      [projectId],
    );
    final eventCount = eventResult.first['count'] as int;

    final performanceResult = _db.select(
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

// Get all unique users

// Get logs for a specific user
Response _getUserLogsHandler(Request req, String userId) {
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

// Get statistics for a specific user
Response _getUserStatsHandler(Request req, String userId) {
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

// Get sessions for a specific user
Response _getUserSessionsHandler(Request req, String userId) {
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

// Get all sessions globally
Response _getSessionsHandler(Request req) {
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

// Get logs for a specific session
Response _getSessionLogsHandler(Request req, String sessionId) {
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

// Analytics Handlers

Response _getAnalyticsSummaryHandler(Request req) {
  try {
    final userId = req.headers['x-user-id'];
    if (userId == null) return Response.forbidden('Missing user context');

    final projectId = req.url.queryParameters['projectId'];
    if (projectId == null)
      return Response.badRequest(body: 'Missing projectId');

    // Verify ownership
    final projectCheck = _db.select(
      'SELECT id FROM projects WHERE id = ? AND user_id = ?',
      [projectId, userId],
    );
    if (projectCheck.isEmpty) return Response.forbidden('Access denied');

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final todayLogsResult = _db.select(
      'SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND timestamp >= ?',
      [projectId, todayStart],
    );
    final todayLogs = todayLogsResult.first['count'] as int;

    final todayErrorsResult = _db.select(
      "SELECT COUNT(*) as count FROM logs WHERE project_id = ? AND timestamp >= ? AND level IN ('error', 'fatal')",
      [projectId, todayStart],
    );
    final todayErrors = todayErrorsResult.first['count'] as int;

    final activeUsersResult = _db.select(
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

Response _getLogsTimelineHandler(Request req) {
  try {
    final userId = req.headers['x-user-id'];
    if (userId == null) return Response.forbidden('Missing user context');

    final projectId = req.url.queryParameters['projectId'];
    if (projectId == null)
      return Response.badRequest(body: 'Missing projectId');

    // Verify ownership
    final projectCheck = _db.select(
      'SELECT id FROM projects WHERE id = ? AND user_id = ?',
      [projectId, userId],
    );
    if (projectCheck.isEmpty) return Response.forbidden('Access denied');

    // Group by hour for the last 24 hours
    final now = DateTime.now();
    final twentyFourHoursAgo = now
        .subtract(Duration(hours: 24))
        .toIso8601String();

    final results = _db.select(
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
        .map((row) => {'time': row['hour'], 'count': row['count'],
    }).toList();

    return Response.ok(
      jsonEncode(timeline),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    print('Error fetching timeline: $e');
    return Response.internalServerError(body: 'Error fetching timeline');
  }
}

Response _getLogLevelsHandler(Request req) {
  try {
    final userId = req.headers['x-user-id'];
    if (userId == null) return Response.forbidden('Missing user context');

    final projectId = req.url.queryParameters['projectId'];
    if (projectId == null)
      return Response.badRequest(body: 'Missing projectId');

    // Verify ownership
    final projectCheck = _db.select(
      'SELECT id FROM projects WHERE id = ? AND user_id = ?',
      [projectId, userId],
    );
    if (projectCheck.isEmpty) return Response.forbidden('Access denied');

    final results = _db.select(
      'SELECT level, COUNT(*) as count FROM logs WHERE project_id = ? GROUP BY level',
      [projectId]
    );

    final levels = results
        .map((row) => {'level': row['level'], 'count': row['count'],
    }).toList();

    return Response.ok(
      jsonEncode(levels),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    print('Error fetching log levels: $e');
    return Response.internalServerError(body: 'Error fetching log levels');
  }
}

Response _getTopErrorsHandler(Request req) {
  try {
    final params = req.url.queryParameters;
    final hours = int.tryParse(params['hours'] ?? '24') ?? 24;
    final limit = int.tryParse(params['limit'] ?? '10') ?? 10;
    final now = DateTime.now();
    final startTime = now.subtract(Duration(hours: hours));

    final results = _db.select(
      '''
      SELECT 
        message,
        COUNT(*) as count,
        MAX(timestamp) as last_seen
      FROM logs
      WHERE level IN (?, ?) AND timestamp >= ?
      GROUP BY message
      ORDER BY count DESC
      LIMIT ?
    ''',
      ['error', 'fatal', startTime.toIso8601String(), limit],
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

Response _getActiveUsersHandler(Request req) {
  try {
    final params = req.url.queryParameters;
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
      WHERE timestamp >= ? AND user_id IS NOT NULL
      GROUP BY user_id
      ORDER BY log_count DESC
      LIMIT ?
    ''',
      [startTime.toIso8601String(), limit],
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

// ===== UTILS =====

String _generateUuid() {
  return DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(10000).toString();
}

String _generateApiKey() {
  final bytes = List<int>.generate(32, (_) => Random().nextInt(255));
  return base64Url.encode(bytes);
}

// Generate hash for log event deduplication
String _hashLogEvent(Map<String, dynamic> event) {
  final key = '${event['message']}_${event['level']}_${event['stackTrace']}';
  return key.hashCode.toString();
}

// Start periodic cleanup timer
void startCleanupTimer() {
  Timer.periodic(const Duration(minutes: 1), (_) {
    final now = DateTime.now();

    // Clean request timestamps
    _requestTimestamps.removeWhere((_, timestamps) {
      timestamps.removeWhere((t) => now.difference(t).inMinutes >= 1);
      return timestamps.isEmpty;
    });

    // Clean recent logs cache
    _recentLogs.removeWhere(
      (hash, time) => now.difference(time).inSeconds > dedupeWindowSeconds,
    );

    if (_requestTimestamps.isNotEmpty || _recentLogs.isNotEmpty) {
      print(
        'Cleanup: ${_requestTimestamps.length} IPs tracked, ${_recentLogs.length} cached log hashes',
      );
    }
  });
}

// Manual CORS Middleware
Middleware corsHeaders() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(
          '',
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers':
                'Origin, Content-Type, X-Auth-Token, x-api-key, x-user-id',
          },
        );
      }
      final response = await handler(request);
      return response.change(
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers':
              'Origin, Content-Type, X-Auth-Token, x-api-key, x-user-id',
        },
      );
    };
  };
}

void main(List<String> args) async {
  // Initialize Database
  _db = sqlite3.open('telling.db');

  // 1. Users Table
  _db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE,
      password_hash TEXT,
      name TEXT,
      created_at TEXT
    )
  ''');

  // 2. Projects Table
  _db.execute('''
    CREATE TABLE IF NOT EXISTS projects (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      name TEXT,
      api_key TEXT UNIQUE,
      created_at TEXT,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )
  ''');

  // 3. Logs Table (Updated)
  // Create table if not exists
  _db.execute('''
    CREATE TABLE IF NOT EXISTS logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_id TEXT,
      type TEXT,
      level TEXT,
      message TEXT,
      timestamp TEXT,
      stack_trace TEXT,
      metadata TEXT,
      device TEXT,
      received_at TEXT,
      user_id TEXT,
      user_name TEXT,
      user_email TEXT,
      session_id TEXT,
      FOREIGN KEY(project_id) REFERENCES projects(id)
    );
  ''');
  
  // Migrate existing table if columns don't exist
  // These ALTER TABLE statements are now redundant if the CREATE TABLE IF NOT EXISTS
  // for logs already includes them, but keeping them for robustness against older schemas.
  try {
    _db.execute('ALTER TABLE logs ADD COLUMN user_id TEXT');
    print('Added user_id column');
  } catch (e) {
    // Column already exists, ignore
  }

  try {
    _db.execute('ALTER TABLE logs ADD COLUMN user_name TEXT');
    print('Added user_name column');
  } catch (e) {
    // Column already exists, ignore
  }

  try {
    _db.execute('ALTER TABLE logs ADD COLUMN user_email TEXT');
    print('Added user_email column');
  } catch (e) {
    // Column already exists, ignore
  }
  
  try {
    _db.execute('ALTER TABLE logs ADD COLUMN session_id TEXT');
    print('Added session_id column');
  } catch (e) {
    // Column already exists, ignore
  }
  
  print('Database initialized: telling.db');

  // Use any available host or container IP (usually `0.0.0.0`).


  // Configure a pipeline that logs requests and adds CORS headers.
  // Start cleanup timer for rate limiting caches
  startCleanupTimer();
  print(
    'Rate limiting enabled: $maxRequestsPerMinute req/min, ${dedupeWindowSeconds}s deduplication',
  );

  // Create the server handler with CORS middleware
  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(_router.call);

  // Start the server
  final server = await serve(handler, 'localhost', 8080);
  print('Serving at http://${server.address.host}:${server.port}');
}
