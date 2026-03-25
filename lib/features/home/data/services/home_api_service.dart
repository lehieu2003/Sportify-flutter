import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class HomeRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchTrendingRaw();
}

class HomeApiService implements HomeRemoteDataSource {
  HomeApiService(this._client);

  final http.Client _client;

  @override
  Future<List<Map<String, dynamic>>> fetchTrendingRaw() async {
    final uri = Uri.https(
      'jsonplaceholder.typicode.com',
      '/albums',
      <String, String>{'_limit': '16'},
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch tracks: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }
}
