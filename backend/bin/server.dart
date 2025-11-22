import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Simple in-memory store for MVP
final List<Map<String, dynamic>> _logs = [];

// Configure routes
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/api/v1/logs', _getLogsHandler)
  ..post('/api/v1/logs', _postLogsHandler);

Response _rootHandler(Request req) {
  return Response.ok('Telling Backend API v1.0.0\n');
}

Response _getLogsHandler(Request req) {
  // Return logs in reverse chronological order (newest first)
  final reversedLogs = _logs.reversed.toList();
  return Response.ok(
    jsonEncode(reversedLogs),
    headers: {'content-type': 'application/json'},
  );
}

Future<Response> _postLogsHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final List<dynamic> events = jsonDecode(payload);

    for (var event in events) {
      if (event is Map<String, dynamic>) {
        // Add server-side timestamp if needed, or trust client
        // event['received_at'] = DateTime.now().toIso8601String();
        _logs.add(event);
      }
    }

    print('Received ${events.length} logs. Total logs: ${_logs.length}');
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
