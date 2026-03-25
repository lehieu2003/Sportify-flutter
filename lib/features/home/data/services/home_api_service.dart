import 'dart:convert';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/authorized_http_client.dart';
import '../../../../core/network/json_utils.dart';
import '../models/home_section_payload.dart';

abstract class HomeRemoteDataSource {
  Future<HomeSectionPayload> fetchHomePayload();
}

class HomeApiService implements HomeRemoteDataSource {
  HomeApiService(this._client);

  final AuthorizedHttpClient _client;

  @override
  Future<HomeSectionPayload> fetchHomePayload() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/home');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      final fallback = await _fetchLegacyTrending();
      return HomeSectionPayload(
        quickAccess: fallback,
        recentlyPlayed: fallback,
        madeForYou: fallback,
        trending: fallback,
        newReleases: fallback,
        genres: const <Map<String, dynamic>>[],
      );
    }

    final payload = decodeJsonObject(response.body);
    return HomeSectionPayload(
      quickAccess:
          (payload['quick_access'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList(growable: false) ??
          const <Map<String, dynamic>>[],
      recentlyPlayed:
          (payload['recently_played'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList(growable: false) ??
          const <Map<String, dynamic>>[],
      madeForYou:
          (payload['made_for_you'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList(growable: false) ??
          const <Map<String, dynamic>>[],
      trending:
          (payload['trending'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList(growable: false) ??
          const <Map<String, dynamic>>[],
      newReleases:
          (payload['new_releases'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList(growable: false) ??
          const <Map<String, dynamic>>[],
      genres:
          (payload['genres'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList(growable: false) ??
          const <Map<String, dynamic>>[],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLegacyTrending() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/songs/news?limit=16');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch home payload.');
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
