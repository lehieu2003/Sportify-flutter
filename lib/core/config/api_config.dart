import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const int backendPort = 3000;

  static String get baseUrl {
    final envValue = dotenv.env['API_BASE_URL']?.trim();
    if (envValue != null && envValue.isNotEmpty) {
      return envValue.endsWith('/')
          ? envValue.substring(0, envValue.length - 1)
          : envValue;
    }

    if (kIsWeb) {
      return 'http://localhost:$backendPort';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$backendPort';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:$backendPort';
      case TargetPlatform.fuchsia:
        return 'http://localhost:$backendPort';
    }
  }

  static String resolveUrl(String? rawUrl) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty) return '';
    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$baseUrl$value';
    }
    return '$baseUrl/$value';
  }
}
