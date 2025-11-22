import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

// Database instance
late final Database _db;

// Configure routes
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/api/v1/logs', _getLogsHandler)
  ..post('/api/v1/logs', _postLogsHandler)
  ..get('/api/v1/stats', _getStatsHandler);

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

    // Return logs in reverse chronological order (newest first)
    final ResultSet results = _db.select(
      'SELECT * FROM logs ORDER BY id DESC LIMIT ? OFFSET ?',
      [limit, offset],
    );

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
      "SELECT COUNT(*) as count FROM logs WHERE type = 'event'",
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
      'INSERT INTO logs (type, level, message, timestamp, stack_trace, metadata, device, received_at, user_id, user_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );

    for (var event in events) {
      if (event is Map<String, dynamic>) {
        stmt.execute([
          event['type'] ?? 'log',
          event['level'] ?? 'info',
          event['message'] ?? '',
          event['timestamp'] ?? DateTime.now().toIso8601String(),
          event['stackTrace'], // Can be null
          event['metadata'] != null ? jsonEncode(event['metadata']) : null,
          event['device'] != null ? jsonEncode(event['device']) : null,
          DateTime.now().toIso8601String(),
          event['userId'], // Can be null
          event['userName'], // Can be null
        ]);
      }
    }
    stmt.dispose();

    print('Received and saved ${events.length} logs.');
    return Response.ok(jsonEncode({'status': 'success', 'count': events.length}));
  } catch (e) {
    print('Error processing logs: $e');
    return Response.internalServerError(body: 'Error processing logs');
  }
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
      user_name TEXT
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
  
  print('Database initialized: telling.db');

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests and adds CORS headers.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
