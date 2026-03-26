import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/network/json_utils.dart';
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
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Signin failed.',
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
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 201) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Signup failed.',
      );
    }
    return AuthSession.fromJson(payload);
  }

  Future<AuthSession> refresh({required String refreshToken}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/refresh');
    final response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'refreshToken': refreshToken}),
    );
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Refresh token failed.',
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
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Load profile failed.',
      );
    }
    return AuthUser.fromJson(payload);
  }

  Future<AuthUser> updateMe({
    required String accessToken,
    String? fullName,
    String? imageUrl,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me');
    final response = await _client.patch(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        if (fullName != null) 'fullName': fullName,
        if (imageUrl != null) 'imageUrl': imageUrl,
      }),
    );
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Update profile failed.',
      );
    }
    return AuthUser.fromJson(payload);
  }

  Future<void> signout({required String refreshToken}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/signout');
    final response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'refreshToken': refreshToken}),
    );
    if (response.statusCode == 200) {
      return;
    }

    final payload = decodeJsonObject(response.body);
    throwApiException(
      statusCode: response.statusCode,
      payload: payload,
      fallback: 'Sign out failed.',
    );
  }

  Future<void> signoutAll({required String accessToken}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/signout-all');
    final response = await _client.post(
      uri,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      return;
    }

    final payload = decodeJsonObject(response.body);
    throwApiException(
      statusCode: response.statusCode,
      payload: payload,
      fallback: 'Sign out all failed.',
    );
  }
}
