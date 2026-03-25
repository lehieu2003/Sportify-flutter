import '../../../../core/config/api_config.dart';
import '../../../../core/network/authorized_http_client.dart';
import '../../../../core/network/json_utils.dart';
import '../models/catalog_models.dart';

class CatalogApiService {
  CatalogApiService(this._client);

  final AuthorizedHttpClient _client;

  Future<CatalogTracksPage> listTracks({
    String? query,
    String? genre,
    int limit = 20,
    String? cursor,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/tracks',
    ).replace(
      queryParameters: <String, String>{
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        if (genre != null && genre.trim().isNotEmpty) 'genre': genre.trim(),
        'limit': '$limit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch tracks.',
      );
    }

    final items =
        (payload['items'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(CatalogTrack.fromJson)
            .toList(growable: false);
    return CatalogTracksPage(
      items: items,
      nextCursor: payload['nextCursor'] as String?,
    );
  }

  Future<CatalogTrack> getTrackById(String trackId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/tracks/$trackId');
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch track detail.',
      );
    }
    return CatalogTrack.fromJson(payload);
  }

  Future<CatalogArtist> getArtistById(String artistId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/tracks/artists/$artistId');
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch artist detail.',
      );
    }
    return CatalogArtist.fromJson(payload);
  }

  Future<CatalogAlbum> getAlbumById(String albumId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/tracks/albums/$albumId');
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch album detail.',
      );
    }
    return CatalogAlbum.fromJson(payload);
  }
}
