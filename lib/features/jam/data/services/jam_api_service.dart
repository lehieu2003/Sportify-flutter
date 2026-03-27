import 'dart:convert';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/authorized_http_client.dart';
import '../../../../core/network/json_utils.dart';
import '../models/jam_models.dart';

class JamApiService {
  JamApiService(this._client);

  final AuthorizedHttpClient _client;

  Future<JamSession> createSession({String? title}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/jam/sessions');
    final response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      }),
    );
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 201) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to create Jam session.',
      );
    }
    return JamSession.fromJson(payload);
  }

  Future<JamSession?> getActiveSession() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/jam/sessions/active');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to load active Jam session.',
      );
    }
    if (response.body.trim().isEmpty || response.body.trim() == 'null') {
      return null;
    }
    final payload = decodeJsonObject(response.body);
    if (payload.isEmpty) return null;
    return JamSession.fromJson(payload);
  }

  Future<JamSession> joinByCode(String inviteCode) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/jam/sessions/join');
    final response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{'inviteCode': inviteCode}),
    );
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to join Jam session.',
      );
    }
    return JamSession.fromJson(payload);
  }

  Future<JamSession> getSessionById(String sessionId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/jam/sessions/$sessionId',
    );
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to load Jam session.',
      );
    }
    return JamSession.fromJson(payload);
  }

  Future<JamSession> syncQueue({
    required String sessionId,
    required List<String> trackIds,
    required int queueIndex,
    String? currentTrackId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/jam/sessions/$sessionId/queue',
    );
    final response = await _client.patch(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'queue': trackIds
            .map((trackId) => <String, dynamic>{'trackId': trackId})
            .toList(growable: false),
        'queueIndex': queueIndex,
        if (currentTrackId != null) 'currentTrackId': currentTrackId,
      }),
    );
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to sync Jam queue.',
      );
    }
    return JamSession.fromJson(payload);
  }

  Future<Map<String, dynamic>> leaveSession(String sessionId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/jam/sessions/$sessionId/leave',
    );
    final response = await _client.post(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to leave Jam session.',
      );
    }
    return payload;
  }

  Future<Map<String, dynamic>> endSession(String sessionId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/jam/sessions/$sessionId/end',
    );
    final response = await _client.post(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to end Jam session.',
      );
    }
    return payload;
  }
}
