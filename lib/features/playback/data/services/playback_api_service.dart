import 'dart:convert';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/authorized_http_client.dart';
import '../../../../core/network/json_utils.dart';

class PlaybackApiService {
  PlaybackApiService(this._client);

  final AuthorizedHttpClient _client;

  Future<Map<String, dynamic>> getState() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playback/state');
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to get playback state.',
      );
    }
    return payload;
  }

  Future<Map<String, dynamic>> updateState({
    String? currentTrackId,
    int? queueIndex,
    bool? isPlaying,
    int? positionMs,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playback/state');
    final response = await _client.patch(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, dynamic>{
        if (currentTrackId != null) 'currentTrackId': currentTrackId,
        if (queueIndex != null) 'queueIndex': queueIndex,
        if (isPlaying != null) 'isPlaying': isPlaying,
        if (positionMs != null) 'positionMs': positionMs,
      }),
    );
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to update playback state.',
      );
    }
    return payload;
  }

  Future<Map<String, dynamic>> getQueue() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playback/queue');
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to get playback queue.',
      );
    }
    return payload;
  }

  Future<Map<String, dynamic>> setQueue({
    required List<String> trackIds,
    required int currentIndex,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playback/queue');
    final response = await _client.put(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, dynamic>{
        'trackIds': trackIds,
        'currentIndex': currentIndex,
      }),
    );
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to set playback queue.',
      );
    }
    return payload;
  }

  Future<Map<String, dynamic>> next() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playback/next');
    final response = await _client.post(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to go to next track.',
      );
    }
    return payload;
  }

  Future<Map<String, dynamic>> previous() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playback/previous');
    final response = await _client.post(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to go to previous track.',
      );
    }
    return payload;
  }
}
