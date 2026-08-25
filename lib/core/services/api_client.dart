import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:telling_logger/telling_logger.dart';
import '../exceptions/api_exceptions.dart';
import '../providers/auth_provider.dart';

class ApiClient {
  final http.Client _client;
  final Ref _ref;

  ApiClient(this._ref) : _client = http.Client();

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = _ref.read(authProvider).token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _printInDebug(String message) {
    if (kDebugMode) {
      debugPrint('🔵 API CLIENT: $message');
    }
  }

  Future<http.Response> _send(
    Future<http.Response> Function() requestFn,
    String method,
    Uri url, {
    Object? body,
    Map<String, String>? additionalHeaders,
  }) async {
    final startTime = DateTime.now();
    
    // Print request details
    _printInDebug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _printInDebug('📤 REQUEST: $method ${url.toString()}');
    _printInDebug('Headers: ${{..._headers, ...?additionalHeaders}}');
    if (body != null) {
      _printInDebug('Body: $body');
    }
    
    try {
      final response = await requestFn();
      final duration = DateTime.now().difference(startTime);
      
      // Print response details
      _printInDebug(
        '📥 RESPONSE: ${response.statusCode} (${duration.inMilliseconds}ms)',
      );
      _printInDebug('Headers: ${response.headers}');
      _printInDebug('Body: ${response.body}');
      _printInDebug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Check for rate limiting (HTTP 429)
      if (response.statusCode == 429) {
        try {
          final data = jsonDecode(response.body);
          throw RateLimitException(
            message:
                data['message'] ?? 'Too many requests. Please try again later.',
            retryAfterSeconds: data['retryAfter'] ?? 60,
          );
        } catch (e) {
          if (e is RateLimitException) rethrow;
          // If JSON parsing fails, throw generic rate limit exception
          throw RateLimitException(
            message: 'Too many requests. Please try again later.',
            retryAfterSeconds: 60,
          );
        }
      }

      // Check for unauthorized (HTTP 401) - invalid/expired token
      if (response.statusCode == 401) {
        _printInDebug(
          '⚠️ 401 Unauthorized - Token invalid/expired, logging out...',
        );

        // Trigger logout
        try {
          _ref.read(authProvider.notifier).logout();
        } catch (e) {
          _printInDebug('⚠️ Failed to trigger logout: $e');
        }

        throw UnauthorizedException(
          message: 'Session expired. Please login again.',
        );
      }

      if (response.statusCode >= 400) {
        Telling.instance.log(
          'API Error: $method ${url.path}',
          type: LogType.crash,
          metadata: {
            'method': method,
            'url': url.toString(),
            'statusCode': response.statusCode,
            'durationMs': duration.inMilliseconds,
            'responseSize': response.bodyBytes.length,
            'responseBody': response.body,
          },
          level: LogLevel.error,
        );
      }

      return response;
    } catch (e, stack) {
      final duration = DateTime.now().difference(startTime);
      Telling.instance.log(
        'API Error: $method ${url.path}',
        type: LogType.crash,
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
        metadata: {
          'method': method,
          'url': url.toString(),
          'durationMs': duration.inMilliseconds,
        },
      );
      rethrow;
    }
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _send(
      () => _client.get(url, headers: {..._headers, ...?headers}),
      'GET',
      url,
      additionalHeaders: headers,
    );
  }

  Future<http.Response> post(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _send(
      () => _client.post(url, headers: {..._headers, ...?headers}, body: body),
      'POST',
      url,
      body: body,
      additionalHeaders: headers,
    );
  }

  Future<http.Response> put(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _send(
      () => _client.put(url, headers: {..._headers, ...?headers}, body: body),
      'PUT',
      url,
      body: body,
      additionalHeaders: headers,
    );
  }

  Future<http.Response> patch(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _send(
      () => _client.patch(url, headers: {..._headers, ...?headers}, body: body),
      'PATCH',
      url,
      body: body,
      additionalHeaders: headers,
    );
  }

  Future<http.Response> delete(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _send(
      () =>
          _client.delete(url, headers: {..._headers, ...?headers}, body: body),
      'DELETE',
      url,
      body: body,
      additionalHeaders: headers,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});
