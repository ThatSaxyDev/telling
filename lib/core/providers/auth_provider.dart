import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telling_logger/telling_logger.dart';
import '../models/auth_user.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../exceptions/api_exceptions.dart';

class AuthState {
  final AuthUser? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.token, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({
    AuthUser? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Error is not persisted by default unless explicitly set
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkSession();
    return AuthState();
  }

  static const _baseUrl = ApiConfig.authPath;

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');

    if (token != null && userJson != null) {
      try {
        final user = AuthUser.fromJson(jsonDecode(userJson));
        state = AuthState(user: user, token: token);

        Telling.instance.setUser(
          userId: user.id,
          userName: user.name,
          userEmail: user.email,
        );

        if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
          OneSignal.login(user.id);
        }
      } catch (e) {
        await logout();
      }
    }
  }

  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = ref.read(apiClientProvider);

      // Try demo login first (for Apple App Store review)
      // This endpoint only works if demo credentials are configured on the server
      try {
        final demoResponse = await apiClient.post(
          Uri.parse('$_baseUrl/demo-login'),
          body: jsonEncode({'email': email, 'password': password}),
        );

        if (demoResponse.statusCode == 200) {
          // Demo login succeeded - persist session directly (bypass OTP)
          final data = jsonDecode(demoResponse.body);
          final user = AuthUser.fromJson(data['user']);
          final token = data['token'];

          await _persistSession(user, token);
          state = AuthState(user: user, token: token, isLoading: false);

          Telling.instance.setUser(
            userId: user.id,
            userName: user.name,
            userEmail: user.email,
          );

          // Return null to signal: already authenticated, go to projects
          return null;
        }
      } catch (_) {
        // Demo login not available or failed, continue to normal flow
      }

      // Normal login flow - returns userId for OTP verification
      final response = await apiClient.post(
        Uri.parse('$_baseUrl/login'),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Login now returns userId for OTP verification, not token
        final userId = data['userId'];

        state = state.copyWith(isLoading: false);
        return userId;
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid credentials');
        return null;
      }
    } on RateLimitException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '${e.message} Retry in ${e.retryAfterFormatted}.',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return null;
    }
  }

  Future<void> logout() async {
    // Clear user context in Telling SDK before logout
    Telling.instance.clearUser();

    // Disassociate device from user in OneSignal
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      OneSignal.logout();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    state = AuthState();
  }

  Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        Uri.parse('$_baseUrl/register'),
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Register now returns userId for OTP verification
        state = state.copyWith(isLoading: false);
        return data;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Registration failed: ${response.body}',
        );
        return null;
      }
    } on RateLimitException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '${e.message} Retry in ${e.retryAfterFormatted}.',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return null;
    }
  }

  Future<bool> verifyOtp(String userId, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        Uri.parse('$_baseUrl/verify'),
        body: jsonEncode({'userId': userId, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = AuthUser.fromJson(data['user']);
        final token = data['token'];

        await _persistSession(user, token);
        state = AuthState(user: user, token: token, isLoading: false);

        // Set user context in Telling SDK after successful verification
        Telling.instance.setUser(
          userId: user.id,
          userName: user.name,
          userEmail: user.email,
        );

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Verification failed: ${response.body}',
        );
        return false;
      }
    } on RateLimitException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '${e.message} Retry in ${e.retryAfterFormatted}.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return false;
    }
  }

  Future<bool> resendOtp(String userId) async {
    // Don't set global loading state for resend to avoid UI flicker
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        Uri.parse('$_baseUrl/resend-otp'),
        body: jsonEncode({'userId': userId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.delete(Uri.parse('$_baseUrl/account'));

      if (response.statusCode == 200) {
        await logout();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete account: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeError(e));
      return false;
    }
  }

  Future<void> _persistSession(AuthUser user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', jsonEncode(user.toJson()));

    // Associate device with user in OneSignal
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      OneSignal.login(user.id);
    }
  }

  String _sanitizeError(Object e) {
    final message = e.toString();
    if (message.contains('ClientException') ||
        message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Failed to host lookup')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'An unexpected error occurred. Please try again later.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
