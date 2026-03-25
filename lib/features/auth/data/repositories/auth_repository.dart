import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../services/auth_api_service.dart';

class AuthBootstrapResult {
  const AuthBootstrapResult({
    required this.isAuthenticated,
    this.user,
    this.accessToken,
    this.refreshToken,
  });

  final bool isAuthenticated;
  final AuthUser? user;
  final String? accessToken;
  final String? refreshToken;
}

class AuthRepository {
  AuthRepository({
    required AuthApiService service,
    required SharedPreferences prefs,
  }) : _service = service,
       _prefs = prefs;

  static const _accessTokenKey = 'auth.access_token.v2';
  static const _refreshTokenKey = 'auth.refresh_token.v2';
  static const _userKey = 'auth.user.v1';

  final AuthApiService _service;
  final SharedPreferences _prefs;

  Future<AuthBootstrapResult> bootstrapSession() async {
    final accessToken = readAccessToken();
    final refreshToken = readRefreshToken();
    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      return const AuthBootstrapResult(isAuthenticated: false);
    }

    try {
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Missing access token');
      }
      final freshUser = await _service.getMe(token: accessToken);
      await _persistSession(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
        user: freshUser,
      );
      return AuthBootstrapResult(
        isAuthenticated: true,
        user: freshUser,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (_) {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final session = await _service.refresh(refreshToken: refreshToken);
          await _persistSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            user: session.user,
          );
          return AuthBootstrapResult(
            isAuthenticated: true,
            user: session.user,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          );
        } catch (_) {}
      }
      await clearSession();
      return const AuthBootstrapResult(isAuthenticated: false);
    }
  }

  Future<AuthSession> signin({
    required String email,
    required String password,
  }) async {
    final session = await _service.signin(email: email, password: password);
    await _persistSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      user: session.user,
    );
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
    await _persistSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      user: session.user,
    );
    return session;
  }

  Future<bool> tryRefreshAccessToken() async {
    final refreshToken = readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearSession();
      return false;
    }

    try {
      final session = await _service.refresh(refreshToken: refreshToken);
      await _persistSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        user: session.user,
      );
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<void> signoutRemote() async {
    final refreshToken = readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _service.signout(refreshToken: refreshToken);
      } catch (_) {}
    }
    await clearSession();
  }

  Future<void> signoutAllRemote() async {
    final accessToken = readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        await _service.signoutAll(accessToken: accessToken);
      } catch (_) {}
    }
    await clearSession();
  }

  Future<void> clearSession() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userKey);
  }

  String? readAccessToken() {
    return _prefs.getString(_accessTokenKey);
  }

  String? readRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<void> _persistSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
