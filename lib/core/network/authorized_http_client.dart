import 'package:http/http.dart' as http;

class AuthorizedHttpClient {
  AuthorizedHttpClient({
    required http.Client baseClient,
    required String? Function() tokenProvider,
    Future<void> Function()? onUnauthorized,
  }) : _baseClient = baseClient,
       _tokenProvider = tokenProvider,
       _onUnauthorized = onUnauthorized;

  final http.Client _baseClient;
  final String? Function() _tokenProvider;
  final Future<void> Function()? _onUnauthorized;

  bool _handlingUnauthorized = false;

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    final mergedHeaders = _withAuthorization(headers);
    final response = await _baseClient.get(uri, headers: mergedHeaders);
    await _handleUnauthorized(response.statusCode);
    return response;
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final mergedHeaders = _withAuthorization(headers);
    final response = await _baseClient.post(
      uri,
      headers: mergedHeaders,
      body: body,
    );
    await _handleUnauthorized(response.statusCode);
    return response;
  }

  Map<String, String> _withAuthorization(Map<String, String>? headers) {
    final token = _tokenProvider();
    final merged = <String, String>{...?headers};
    if (token != null && token.isNotEmpty) {
      merged['Authorization'] = 'Bearer $token';
    }
    return merged;
  }

  Future<void> _handleUnauthorized(int statusCode) async {
    if (statusCode != 401 || _onUnauthorized == null || _handlingUnauthorized) {
      return;
    }
    _handlingUnauthorized = true;
    try {
      await _onUnauthorized.call();
    } finally {
      _handlingUnauthorized = false;
    }
  }
}
