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
