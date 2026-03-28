import 'dart:convert';

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
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/tracks').replace(
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

    final items = (payload['items'] as List<dynamic>? ?? const <dynamic>[])
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
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/tracks/artists/$artistId',
    );
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

  Future<List<CatalogTrack>> getAlbumTracks(String albumId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/tracks/albums/$albumId/tracks',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch album tracks.',
      );
    }
    return decodeJsonObjectList(
      response.body,
    ).map(CatalogTrack.fromJson).toList(growable: false);
  }

  Future<List<CatalogTrack>> getArtistTopTracks(
    String artistId, {
    int limit = 10,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/tracks/artists/$artistId/top-tracks',
    ).replace(queryParameters: <String, String>{'limit': '$limit'});
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch artist top tracks.',
      );
    }
    return decodeJsonObjectList(
      response.body,
    ).map(CatalogTrack.fromJson).toList(growable: false);
  }

  Future<CatalogTracksPage> getArtistAlbums({
    required String artistId,
    int limit = 20,
    String? cursor,
  }) async {
    final uri =
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/tracks/artists/$artistId/albums',
        ).replace(
          queryParameters: <String, String>{
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
        fallback: 'Failed to fetch artist albums.',
      );
    }
    final items = (payload['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (album) => CatalogTrack(
            id: (album['id'] ?? '').toString(),
            title: (album['title'] ?? '').toString(),
            artist: (album['artist'] ?? '').toString(),
            artistId: (album['artistId'] ?? '').toString(),
            albumId: (album['id'] ?? '').toString(),
            albumTitle: (album['title'] ?? '').toString(),
            coverUrl: ApiConfig.resolveUrl(album['coverUrl']?.toString()),
            audioUrl: '',
          ),
        )
        .toList(growable: false);
    return CatalogTracksPage(
      items: items,
      nextCursor: payload['nextCursor'] as String?,
    );
  }

  Future<SearchBrowsePayload> getSearchBrowse() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/search/browse');
    final response = await _client.get(uri);
    final payload = decodeJsonObject(response.body);
    if (response.statusCode != 200) {
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch search browse payload.',
      );
    }
    final discover =
        (payload['discoverCards'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(SearchBrowseCard.fromJson)
            .toList(growable: false);
    final categories =
        (payload['browseCategories'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(SearchBrowseCard.fromJson)
            .toList(growable: false);
    return SearchBrowsePayload(
      discoverCards: discover,
      browseCategories: categories,
    );
  }

  Future<List<SearchRecentItem>> getRecentSearches({int limit = 20}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/search/recent',
    ).replace(queryParameters: <String, String>{'limit': '$limit'});
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to fetch recent searches.',
      );
    }
    final payload = decodeJsonObjectList(response.body);
    return payload.map(SearchRecentItem.fromJson).toList(growable: false);
  }

  Future<void> upsertRecentSearch({
    required String type,
    required String itemId,
    required String title,
    String? subtitle,
    String? imageUrl,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/search/recent');
    final response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'type': type,
        'itemId': itemId,
        'title': title,
        if (subtitle != null && subtitle.trim().isNotEmpty)
          'subtitle': subtitle,
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'imageUrl': imageUrl,
      }),
    );
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to save recent search.',
      );
    }
  }

  Future<void> deleteRecentSearch(String recentId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/search/recent/$recentId',
    );
    final response = await _client.delete(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to delete recent search.',
      );
    }
  }
}
