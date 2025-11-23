import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:backend/db/database.dart';
import 'package:backend/utils/constants.dart';
import 'package:backend/middleware/cors_middleware.dart';
import 'package:backend/middleware/auth_middleware.dart';
import 'package:backend/handlers/auth_handler.dart';
import 'package:backend/handlers/project_handler.dart';
import 'package:backend/handlers/log_handler.dart';
import 'package:backend/handlers/analytics_handler.dart';
import 'package:backend/handlers/user_handler.dart';

// Handlers
final _authHandler = AuthHandler();
final _projectHandler = ProjectHandler();
final _logHandler = LogHandler();
final _analyticsHandler = AnalyticsHandler();
final _userHandler = UserHandler();

// Configure routes
final _router = Router()
  ..get('/', _rootHandler)
  // Auth Routes
  ..post('/api/v1/auth/register', _authHandler.registerHandler)
  ..post('/api/v1/auth/login', _authHandler.loginHandler)
  // Project Routes
  ..get('/api/v1/projects', _projectHandler.getUserProjectsHandler)
  ..post('/api/v1/projects', _projectHandler.createProjectHandler)
  ..delete('/api/v1/projects/<projectId>', _projectHandler.deleteProjectHandler)
  ..post(
    '/api/v1/projects/<projectId>/keys',
    _projectHandler.regenerateApiKeyHandler,
  )
  // Log Ingestion (Secured by API Key)
  ..post('/api/v1/logs', _logHandler.postLogsHandler)
  // Analytics Routes (Secured by User Auth - TODO: Add middleware)
  ..get('/api/v1/logs', _logHandler.getLogsHandler)
  ..get('/api/v1/stats', _analyticsHandler.getStatsHandler)
  ..get('/api/v1/users', _userHandler.getActiveUsersHandler)
  ..get('/api/v1/users/<userId>/logs', _userHandler.getUserLogsHandler)
  ..get('/api/v1/users/<userId>/stats', _userHandler.getUserStatsHandler)
  ..get('/api/v1/users/<userId>/sessions', _userHandler.getUserSessionsHandler)
  ..get('/api/v1/sessions', _userHandler.getSessionsHandler)
  ..get('/api/v1/sessions/<sessionId>/logs', _userHandler.getSessionLogsHandler)
  ..get(
    '/api/v1/analytics/summary',
    _analyticsHandler.getAnalyticsSummaryHandler,
  )
  ..get('/api/v1/analytics/timeline', _analyticsHandler.getLogsTimelineHandler)
  ..get('/api/v1/analytics/levels', _analyticsHandler.getLogLevelsHandler)
  ..get('/api/v1/analytics/errors', _analyticsHandler.getTopErrorsHandler)
  ..get('/api/v1/analytics/users', _userHandler.getActiveUsersHandler);

Response _rootHandler(Request req) {
  return Response.ok('Telling Backend API v2.0.0 (Secured)\n');
}

// Start periodic cleanup timer
void startCleanupTimer() {
  Timer.periodic(const Duration(minutes: 1), (_) {
    // We might want to expose cleanup methods in handlers if they maintain state
    // For now, _logHandler has a cleanup method
    _logHandler.cleanup();
    
    // Note: _requestTimestamps was removed from server.dart as it wasn't being used in the extracted handlers yet
    // If rate limiting is needed, it should be moved to a middleware or handler
  });
}

void main(List<String> args) async {
  // Initialize Database
  final dbPath = Platform.environment['DB_PATH'] ?? 'dramatic-alb.db';
  await DatabaseService().init(dbPath);
  
  print('Database initialized: $dbPath');

  // Start cleanup timer
  startCleanupTimer();
  print(
    'Rate limiting enabled: $maxRequestsPerMinute req/min, ${dedupeWindowSeconds}s deduplication',
  );

  // Create the server handler with CORS and Auth middleware
  // Create the server handler with CORS, Auth, and Logging middleware
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(authMiddleware())
      .addHandler(_router.call);

  // Start the server
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('Serving at http://${server.address.host}:${server.port}');
}
