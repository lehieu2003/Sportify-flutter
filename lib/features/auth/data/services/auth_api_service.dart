import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';

class AuthApiService {
  AuthApiService({required http.Client client}) : _client = client;

  final http.Client _client;

  Future<AuthSession> signin({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/signin');
    final response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );
    final payload = _decodePayload(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(payload, fallback: 'Signin failed.'),
      );
    }
    return AuthSession.fromJson(payload);
  }

  Future<AuthSession> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/signup');
    final response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    );
    final payload = _decodePayload(response.body);
    if (response.statusCode != 201) {
      throw Exception(
        _extractErrorMessage(payload, fallback: 'Signup failed.'),
      );
    }
    return AuthSession.fromJson(payload);
  }

  Future<AuthUser> getMe({required String token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me');
    final response = await _client.get(
      uri,
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );
    final payload = _decodePayload(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(payload, fallback: 'Load profile failed.'),
      );
    }
    return AuthUser.fromJson(payload);
  }

  Map<String, dynamic> _decodePayload(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  String _extractErrorMessage(
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    final message = payload['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }
}
