import 'dart:convert';

import 'api_exception.dart';

Map<String, dynamic> decodeJsonObject(String body) {
  if (body.trim().isEmpty) {
    return <String, dynamic>{};
  }
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> decodeJsonObjectList(String body) {
  if (body.trim().isEmpty) {
    return const <Map<String, dynamic>>[];
  }
  final decoded = jsonDecode(body);
  if (decoded is List) {
    return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

String extractErrorMessage(
  Map<String, dynamic> payload, {
  required String fallback,
}) {
  final message = payload['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message;
  }
  return fallback;
}

Never throwApiException({
  required int statusCode,
  required Map<String, dynamic> payload,
  required String fallback,
}) {
  throw ApiException(
    message: extractErrorMessage(payload, fallback: fallback),
    statusCode: statusCode,
    code: payload['code'] as String?,
  );
}
