/// Generic API exception for HTTP errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Exception thrown when rate limit is exceeded (HTTP 429)
class RateLimitException implements Exception {
  final String message;
  final int retryAfterSeconds;

  RateLimitException({
    required this.message,
    required this.retryAfterSeconds,
  });

  /// Returns a user-friendly formatted retry time
  String get retryAfterFormatted {
    if (retryAfterSeconds < 60) {
      return '$retryAfterSeconds seconds';
    }
    final minutes = (retryAfterSeconds / 60).ceil();
    return '$minutes minute${minutes > 1 ? 's' : ''}';
  }

  @override
  String toString() => message;
}

/// Exception thrown when authentication token is invalid or expired (HTTP 401)
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException({
    this.message = 'Session expired. Please login again.',
  });

  @override
  String toString() => message;
}
