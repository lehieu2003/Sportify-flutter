import '../../../../core/config/api_config.dart';
import '../../../../core/network/authorized_http_client.dart';
import '../../../../core/network/json_utils.dart';
import '../models/library_models.dart';

class LibraryApiService {
  LibraryApiService(this._client);

  final AuthorizedHttpClient _client;

  Future<List<LibraryTrack>> getSavedTracks({int limit = 50}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/library/tracks',
    ).replace(queryParameters: <String, String>{'limit': '$limit'});
    final response = await _client.get(uri);
    final payload = decodeJsonObjectList(response.body);
    if (response.statusCode != 200) {
      throw Exception('Failed to load saved tracks.');
    }
    return payload.map(LibraryTrack.fromJson).toList(growable: false);
  }

  Future<CursorPage<LibraryAlbum>> getSavedAlbums({int limit = 20, String? cursor}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/library/albums',
    ).replace(queryParameters: <String, String>{
      'limit': '$limit',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    });
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to load saved albums.',
      );
    }
    final items = (payload['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(LibraryAlbum.fromJson)
        .toList(growable: false);
    return CursorPage(items: items, nextCursor: payload['nextCursor'] as String?);
  }

  Future<CursorPage<LibraryArtist>> getFollowedArtists({int limit = 20, String? cursor}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/library/artists',
    ).replace(queryParameters: <String, String>{
      'limit': '$limit',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    });
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to load followed artists.',
      );
    }
    final items = (payload['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(LibraryArtist.fromJson)
        .toList(growable: false);
    return CursorPage(items: items, nextCursor: payload['nextCursor'] as String?);
  }

  Future<CursorPage<LibraryPlaylist>> getOwnedPlaylists({int limit = 20, String? cursor}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/library/playlists',
    ).replace(queryParameters: <String, String>{
      'limit': '$limit',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    });
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to load library playlists.',
      );
    }
    final items = (payload['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(LibraryPlaylist.fromJson)
        .toList(growable: false);
    return CursorPage(items: items, nextCursor: payload['nextCursor'] as String?);
  }

  Future<void> saveTrack(String trackId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/library/tracks/$trackId/save');
    final response = await _client.post(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to save track.',
      );
    }
  }

  Future<void> unsaveTrack(String trackId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/library/tracks/$trackId/save');
    final response = await _client.delete(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to unsave track.',
      );
    }
  }

  Future<void> saveAlbum(String albumId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/library/albums/$albumId/save');
    final response = await _client.post(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to save album.',
      );
    }
  }

  Future<void> unsaveAlbum(String albumId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/library/albums/$albumId/save');
    final response = await _client.delete(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to unsave album.',
      );
    }
  }

  Future<void> followArtist(String artistId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/library/artists/$artistId/follow');
    final response = await _client.post(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to follow artist.',
      );
    }
  }

  Future<void> unfollowArtist(String artistId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/library/artists/$artistId/follow');
    final response = await _client.delete(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to unfollow artist.',
      );
    }
  }
}
