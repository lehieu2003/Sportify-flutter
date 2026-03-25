import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../services/auth_api_service.dart';

class AuthBootstrapResult {
  const AuthBootstrapResult({
    required this.isAuthenticated,
    this.user,
    this.token,
  });

  final bool isAuthenticated;
  final AuthUser? user;
  final String? token;
}

class AuthRepository {
  AuthRepository({
    required AuthApiService service,
    required SharedPreferences prefs,
  }) : _service = service,
       _prefs = prefs;

  static const _tokenKey = 'auth.access_token.v1';
  static const _userKey = 'auth.user.v1';

  final AuthApiService _service;
  final SharedPreferences _prefs;

  Future<AuthBootstrapResult> bootstrapSession() async {
    final token = _prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return const AuthBootstrapResult(isAuthenticated: false);
    }

    try {
      final freshUser = await _service.getMe(token: token);
      await _persistSession(token: token, user: freshUser);
      return AuthBootstrapResult(
        isAuthenticated: true,
        user: freshUser,
        token: token,
      );
    } catch (_) {
      await clearSession();
      return const AuthBootstrapResult(isAuthenticated: false);
    }
  }

  Future<AuthSession> signin({
    required String email,
    required String password,
  }) async {
    final session = await _service.signin(email: email, password: password);
    await _persistSession(token: session.token, user: session.user);
    return session;
  }

  Future<AuthSession> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final session = await _service.signup(
      fullName: fullName,
      email: email,
      password: password,
    );
    await _persistSession(token: session.token, user: session.user);
    return session;
  }

  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  String? readAccessToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> _persistSession({
    required String token,
    required AuthUser user,
  }) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
