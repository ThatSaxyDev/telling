import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../utils/constants.dart';

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Allow OPTIONS requests (CORS preflight)
      if (request.method == 'OPTIONS') {
        return innerHandler(request);
      }

      // Public paths that don't require authentication
      final path = request.url.path;
      if (path == '' || path == '/' || path.startsWith('api/v1/auth/') || (path == 'api/v1/logs' && request.method == 'POST')) {
        return innerHandler(request);
      }

      // Check for Authorization header
      final authHeader = request.headers['Authorization'];
      if (authHeader == null) {
        return Response.forbidden('Missing Authorization header');
      }

      // Check for Bearer token
      if (!authHeader.startsWith('Bearer ')) {
        return Response.forbidden('Invalid Authorization header format');
      }

      final token = authHeader.substring(7);

      try {
        // Verify JWT
        final jwt = JWT.verify(token, SecretKey(jwtSecret));

        // Add user info to request context
        final payload = jwt.payload as Map<String, dynamic>;
        final userId = payload['sub'] as String; // 'sub' is standard for Subject (User ID)
        
        // We can also store other claims if needed
        final context = Map<String, Object>.from(request.context);
        context['authDetails'] = payload;
        context['userId'] = userId; // Convenience

        return innerHandler(request.change(context: context));

      } on JWTExpiredException {
        return Response.forbidden('Token expired');
      } on JWTException catch (e) {
        return Response.forbidden('Invalid token: ${e.message}');
      } catch (e) {
        return Response.internalServerError(body: 'Authentication error');
      }
    };
  };
}
