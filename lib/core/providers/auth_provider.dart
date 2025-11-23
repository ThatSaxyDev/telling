import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telling_logger/telling_logger.dart';
import '../models/auth_user.dart';
import '../config/api_config.dart';

class AuthState {
  final AuthUser? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

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
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = AuthUser.fromJson(data['user']);
        final token = data['token'];

        await _persistSession(user, token);
        state = state.copyWith(user: user, token: token, isLoading: false);
        
        // Set user context in Telling SDK after successful login
        Telling.instance.setUser(
          userId: user.id,
          userName: user.name,
          userEmail: user.email,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid credentials');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    // Clear user context in Telling SDK before logout
    Telling.instance.clearUser();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    state = AuthState();
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = AuthUser.fromJson(data['user']);
        final token = data['token'];

        await _persistSession(user, token);
        state = AuthState(user: user, token: token, isLoading: false);
        
        // Set user context in Telling SDK after successful registration
        Telling.instance.setUser(
          userId: user.id,
          userName: user.name,
          userEmail: user.email,
        );
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Registration failed: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> _persistSession(AuthUser user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', jsonEncode(user.toJson()));
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
