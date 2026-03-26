import 'dart:convert';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/authorized_http_client.dart';
import '../../../../core/network/json_utils.dart';
import '../models/playlist_models.dart';

class PlaylistApiService {
  PlaylistApiService(this._client);

  final AuthorizedHttpClient _client;

  Future<List<Map<String, dynamic>>> listPlaylists({int limit = 50}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/playlists',
    ).replace(queryParameters: <String, String>{'limit': '$limit'});
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to list playlists.',
      );
    }
    return decodeJsonObjectList(response.body);
  }

  Future<PlaylistDetail> getPlaylistById(String playlistId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playlists/$playlistId');
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to get playlist detail.',
      );
    }
    return PlaylistDetail.fromJson(payload);
  }

  Future<Map<String, dynamic>> createPlaylist({
    required String title,
    String? description,
    String? coverUrl,
    bool isPublic = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playlists');
    final response = await _client.post(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, dynamic>{
        'title': title,
        if (description != null) 'description': description,
        if (coverUrl != null) 'coverUrl': coverUrl,
        'isPublic': isPublic,
      }),
    );
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 201) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to create playlist.',
      );
    }
    return payload;
  }

  Future<Map<String, dynamic>> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    String? coverUrl,
    bool? isPublic,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playlists/$playlistId');
    final response = await _client.patch(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (coverUrl != null) 'coverUrl': coverUrl,
        if (isPublic != null) 'isPublic': isPublic,
      }),
    );
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to update playlist.',
      );
    }
    return payload;
  }

  Future<void> deletePlaylist(String playlistId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playlists/$playlistId');
    final response = await _client.delete(uri);
    if (response.statusCode == 200) return;
    final payload = decodeJsonObject(response.body);
    throwApiException(
      statusCode: response.statusCode,
      payload: payload,
      fallback: 'Failed to delete playlist.',
    );
  }

  Future<List<PlaylistTrack>> getPlaylistTracks(String playlistId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/tracks');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to get playlist tracks.',
      );
    }
    return decodeJsonObjectList(response.body)
        .map(PlaylistTrack.fromJson)
        .toList(growable: false);
  }

  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
    int? position,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/tracks');
    final response = await _client.post(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, dynamic>{
        'trackId': trackId,
        if (position != null) 'position': position,
      }),
    );
    if (response.statusCode == 200) return;
    final payload = decodeJsonObject(response.body);
    throwApiException(
      statusCode: response.statusCode,
      payload: payload,
      fallback: 'Failed to add track to playlist.',
    );
  }

  Future<void> reorderTrack({
    required String playlistId,
    required String trackId,
    required int newPosition,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/tracks/reorder');
    final response = await _client.patch(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, dynamic>{'trackId': trackId, 'newPosition': newPosition}),
    );
    if (response.statusCode == 200) return;
    final payload = decodeJsonObject(response.body);
    throwApiException(
      statusCode: response.statusCode,
      payload: payload,
      fallback: 'Failed to reorder playlist track.',
    );
  }

  Future<void> removeTrack({
    required String playlistId,
    required String trackId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/tracks/$trackId');
    final response = await _client.delete(uri);
    if (response.statusCode == 200) return;
    final payload = decodeJsonObject(response.body);
    throwApiException(
      statusCode: response.statusCode,
      payload: payload,
      fallback: 'Failed to remove track from playlist.',
    );
  }
}
