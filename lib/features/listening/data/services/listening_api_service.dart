import 'dart:convert';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/authorized_http_client.dart';
import '../../../../core/network/json_utils.dart';

class ListeningApiService {
  ListeningApiService(this._client);

  final AuthorizedHttpClient _client;

  Future<void> sendEvent({
    required String trackId,
    required String eventType,
    int? progressMs,
    DateTime? clientTs,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/listening/events');
    final response = await _client.post(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, dynamic>{
        'trackId': trackId,
        'eventType': eventType,
        if (progressMs != null) 'progressMs': progressMs,
        if (clientTs != null) 'clientTs': clientTs.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) return;
    final payload = decodeJsonObject(response.body);
    throwApiException(
      statusCode: response.statusCode,
      payload: payload,
      fallback: 'Failed to send listening event.',
    );
  }

  Future<List<Map<String, dynamic>>> getRecent({int limit = 20}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/listening/recent',
    ).replace(queryParameters: <String, String>{'limit': '$limit'});
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final payload = decodeJsonObject(response.body);
      throwApiException(
        statusCode: response.statusCode,
        payload: payload,
        fallback: 'Failed to load recent listening.',
      );
    }
    return decodeJsonObjectList(response.body);
  }
}
