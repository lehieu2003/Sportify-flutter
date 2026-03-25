import '../../../../core/config/api_config.dart';
import '../../../../core/network/authorized_http_client.dart';
import '../../../../core/network/json_utils.dart';

class SongApiService {
  SongApiService(this._client);

  final AuthorizedHttpClient _client;

  Future<List<Map<String, dynamic>>> getNews({int limit = 16}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/songs/news',
    ).replace(queryParameters: <String, String>{'limit': '$limit'});
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch songs news.',
      );
    }
    return decodeJsonObjectList(response.body);
  }

  Future<List<Map<String, dynamic>>> getPlaylist() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/songs/playlist');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch songs playlist.',
      );
    }
    return decodeJsonObjectList(response.body);
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/songs/favorites');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch favorite songs.',
      );
    }
    return decodeJsonObjectList(response.body);
  }

  Future<bool> isFavorite(String songId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/songs/$songId/is-favorite');
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to check favorite song state.',
      );
    }
    return (payload['isFavorite'] ?? false) as bool;
  }

  Future<Map<String, dynamic>> toggleFavorite(String songId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/songs/$songId/favorite-toggle');
    final response = await _client.post(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to toggle favorite song.',
      );
    }
    return payload;
  }
}
