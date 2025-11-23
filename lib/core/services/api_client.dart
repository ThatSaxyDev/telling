import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class ApiClient {
  final String? _token;
  final http.Client _client;

  ApiClient(this._token) : _client = http.Client();

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _client.get(
      url,
      headers: {..._headers, ...?headers},
    );
  }

  Future<http.Response> post(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _client.post(
      url,
      headers: {..._headers, ...?headers},
      body: body,
    );
  }

  Future<http.Response> put(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _client.put(
      url,
      headers: {..._headers, ...?headers},
      body: body,
    );
  }

  Future<http.Response> delete(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _client.delete(
      url,
      headers: {..._headers, ...?headers},
      body: body,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final authState = ref.watch(authProvider);
  return ApiClient(authState.token);
});
