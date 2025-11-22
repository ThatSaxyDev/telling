import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

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
  ..get('/api/v1/logs', _getLogsHandler)
  ..post('/api/v1/logs', _postLogsHandler)
  ..get('/api/v1/stats', _getStatsHandler)
  ..get('/api/v1/users', _getUsersHandler)
  ..get('/api/v1/users/<userId>/logs', _getUserLogsHandler)
  ..get('/api/v1/users/<userId>/stats', _getUserStatsHandler)
  ..get('/api/v1/users/<userId>/sessions', _getUserSessionsHandler);

Response _rootHandler(Request req) {
  return Response.ok('Telling Backend API v1.0.0 (SQLite)\n');
}

Response _getLogsHandler(Request req) {
  try {
    // Pagination parameters
    final params = req.url.queryParameters;
    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
    final offset = (page - 1) * limit;
    final userId = params['userId']; // Optional user filter

    // Build query with optional user filter
    String query = 'SELECT * FROM logs';
    List<Object?> queryParams = [];

    if (userId != null && userId.isNotEmpty) {
      query += ' WHERE user_id = ?';
      queryParams.add(userId);
    }

    query += ' ORDER BY id DESC LIMIT ? OFFSET ?';
    queryParams.addAll([limit, offset]);

    // Return logs in reverse chronological order (newest first)
    final ResultSet results = _db.select(query, queryParams);

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
    // Calculate stats efficiently using SQL
    final totalResult = _db.select('SELECT COUNT(*) as count FROM logs');
    final total = totalResult.first['count'] as int;

    final errorResult = _db.select(
      "SELECT COUNT(*) as count FROM logs WHERE level IN ('error', 'fatal')",
    );
    final errorCount = errorResult.first['count'] as int;

    final warningResult = _db.select(
      "SELECT COUNT(*) as count FROM logs WHERE level = 'warning'",
    );
    final warningCount = warningResult.first['count'] as int;

    final eventResult = _db.select(
      "SELECT COUNT(*) as count FROM logs WHERE type IN ('event', 'analytics')",
    );
    final eventCount = eventResult.first['count'] as int;

    final performanceResult = _db.select(
      "SELECT COUNT(*) as count FROM logs WHERE type = 'performance'",
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



Future<Response> _postLogsHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final List<dynamic> events = jsonDecode(payload);
    
    final stmt = _db.prepare(
      'INSERT INTO logs (type, level, message, timestamp, stack_trace, metadata, device, received_at, user_id, user_name, user_email, session_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );

    int saved = 0;
    int duplicates = 0;

    for (var event in events) {
      if (event is Map<String, dynamic>) {
        // Normalize and validate level
        String level = event['level'] ?? 'info';
        if (!validLogLevels.contains(level.toLowerCase())) {
          print('Warning: Invalid log level "$level", defaulting to "info"');
          level = 'info';
        }

        // Normalize and validate type (with legacy support)
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

        // Check for duplicates
        final hash = _hashLogEvent(event);
        final lastSeen = _recentLogs[hash];
        final now = DateTime.now();

        if (lastSeen != null &&
            now.difference(lastSeen).inSeconds < dedupeWindowSeconds) {
          duplicates++;
          continue; // Skip duplicate
        }

        stmt.execute([
          type,
          level,
          event['message'] ?? '',
          event['timestamp'] ?? DateTime.now().toIso8601String(),
          event['stackTrace'], // Can be null
          event['metadata'] != null ? jsonEncode(event['metadata']) : null,
          event['device'] != null ? jsonEncode(event['device']) : null,
          DateTime.now().toIso8601String(),
          event['userId'], // Can be null
          event['userName'], // Can be null
          event['userEmail'], // Can be null
          event['sessionId'], // Can be null
        ]);
        
        _recentLogs[hash] = now;
        saved++;
      }
    }
    stmt.dispose();

    print('Saved $saved logs, dropped $duplicates duplicates');
    return Response.ok(
      jsonEncode({
        'status': 'success',
        'saved': saved,
        'duplicates': duplicates,
        'total': events.length,
      }),
    );
  } catch (e) {
    print('Error processing logs: $e');
    return Response.internalServerError(body: 'Error processing logs');
  }
}

// ===== User Analytics Handlers =====

// Get all unique users
Response _getUsersHandler(Request req) {
  try {
    final results = _db.select('''
      SELECT DISTINCT user_id, user_name, user_email, MAX(received_at) as last_seen, COUNT(*) as log_count
      FROM logs
      WHERE user_id IS NOT NULL
      GROUP BY user_id
      ORDER BY last_seen DESC
    ''');

    final users = results
        .map(
          (row) => {
            'userId': row['user_id'],
            'userName': row['user_name'],
            'userEmail': row['user_email'],
            'lastSeen': row['last_seen'],
            'logCount': row['log_count'],
          },
        )
        .toList();

    return Response.ok(jsonEncode(users));
  } catch (e) {
    print('Error fetching users: $e');
    return Response.internalServerError(body: 'Error fetching users');
  }
}

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

// Generate hash for log event deduplication
String _hashLogEvent(Map<String, dynamic> event) {
  final key = '${event['message']}_${event['level']}_${event['stackTrace']}';
  return key.hashCode.toString();
}

// Start periodic cleanup timer
void _startCleanupTimer() {
  Timer.periodic(const Duration(minutes: 1), (_) {
    final now = DateTime.now();

    // Clean request timestamps
    _requestTimestamps.removeWhere((ip, timestamps) {
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
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token, x-api-key',
        });
      }
      final response = await handler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token, x-api-key',
      });
    };
  };
}

void main(List<String> args) async {
  // Initialize Database
  _db = sqlite3.open('telling.db');

  // Create table if not exists
  _db.execute('''
    CREATE TABLE IF NOT EXISTS logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
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
      session_id TEXT
    );
  ''');
  
  // Migrate existing table if columns don't exist
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
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests and adds CORS headers.
  // Start cleanup timer for rate limiting caches
  _startCleanupTimer();
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
