import 'dart:convert';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/authorized_http_client.dart';

abstract class HomeRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchTrendingRaw();
}

class HomeApiService implements HomeRemoteDataSource {
  HomeApiService(this._client);

  final AuthorizedHttpClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchTrendingRaw() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/songs/news?limit=16');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch tracks: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }
}
