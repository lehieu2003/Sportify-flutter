import 'package:http/http.dart' as http;

class AuthorizedHttpClient {
  AuthorizedHttpClient({
    required http.Client baseClient,
    required String? Function() tokenProvider,
    Future<bool> Function()? onUnauthorized,
  }) : _baseClient = baseClient,
       _tokenProvider = tokenProvider,
       _onUnauthorized = onUnauthorized;

  final http.Client _baseClient;
  final String? Function() _tokenProvider;
  final Future<bool> Function()? _onUnauthorized;

  bool _handlingUnauthorized = false;

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    return _send((requestHeaders) => _baseClient.get(uri, headers: requestHeaders), headers);
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _send(
      (requestHeaders) => _baseClient.post(uri, headers: requestHeaders, body: body),
      headers,
    );
  }

  Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _send(
      (requestHeaders) => _baseClient.patch(uri, headers: requestHeaders, body: body),
      headers,
    );
  }

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _send(
      (requestHeaders) => _baseClient.put(uri, headers: requestHeaders, body: body),
      headers,
    );
  }

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _send(
      (requestHeaders) => _baseClient.delete(uri, headers: requestHeaders, body: body),
      headers,
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) sender,
    Map<String, String>? headers,
  ) async {
    final firstResponse = await sender(_withAuthorization(headers));
    if (firstResponse.statusCode != 401) {
      return firstResponse;
    }

    final refreshed = await _handleUnauthorized();
    if (!refreshed) {
      return firstResponse;
    }

    return sender(_withAuthorization(headers));
  }

  Map<String, String> _withAuthorization(Map<String, String>? headers) {
    final token = _tokenProvider();
    final merged = <String, String>{...?headers};
    if (token != null && token.isNotEmpty) {
      merged['Authorization'] = 'Bearer $token';
    }
    return merged;
  }

  Future<bool> _handleUnauthorized() async {
    if (_onUnauthorized == null || _handlingUnauthorized) {
      return false;
    }
    _handlingUnauthorized = true;
    try {
      return await _onUnauthorized.call();
    } finally {
      _handlingUnauthorized = false;
    }
  }
}
