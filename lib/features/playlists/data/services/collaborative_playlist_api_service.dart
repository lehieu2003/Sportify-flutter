import 'dart:convert';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/authorized_http_client.dart';
import '../../../../core/network/json_utils.dart';
import '../models/playlist_models.dart';

class CollaborativePlaylistApiService {
  CollaborativePlaylistApiService(this._client);

  final AuthorizedHttpClient _client;

  Future<List<PlaylistMember>> listMembers(String playlistId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/members',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to load playlist members.',
      );
    }
    return decodeJsonObjectList(
      response.body,
    ).map(PlaylistMember.fromJson).toList(growable: false);
  }

  Future<PlaylistInvite> createInvite(
    String playlistId, {
    int? expiresInHours,
    int? maxUses,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/members/invite',
    );
    final response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        if (expiresInHours != null) 'expiresInHours': expiresInHours,
        if (maxUses != null) 'maxUses': maxUses,
      }),
    );
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 201) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to create invite code.',
      );
    }
    return PlaylistInvite.fromJson(payload);
  }

  Future<JoinPlaylistResult> joinByCode(String inviteCode) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/playlists/join');
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
        fallback: 'Failed to join playlist.',
      );
    }
    return JoinPlaylistResult.fromJson(payload);
  }

  Future<void> updateMemberRole({
    required String playlistId,
    required String userId,
    required String role,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/members/$userId',
    );
    final response = await _client.patch(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{'role': role}),
    );
    if (response.statusCode == 200) return;
    final payload = decodeJsonObject(response.body);
    throwApiException(
      statusCode: response.statusCode,
      payload: payload,
      fallback: 'Failed to update member role.',
    );
  }

  Future<void> removeMember({
    required String playlistId,
    required String userId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/members/$userId',
    );
    final response = await _client.delete(uri);
    if (response.statusCode == 200) return;
    final payload = decodeJsonObject(response.body);
    throwApiException(
      statusCode: response.statusCode,
      payload: payload,
      fallback: 'Failed to remove member.',
    );
  }

  Future<void> transferOwnership({
    required String playlistId,
    required String userId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/playlists/$playlistId/ownership/transfer',
    );
    final response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{'userId': userId}),
    );
    if (response.statusCode == 200) return;
    final payload = decodeJsonObject(response.body);
    throwApiException(
      statusCode: response.statusCode,
      payload: payload,
      fallback: 'Failed to transfer ownership.',
    );
  }
}
