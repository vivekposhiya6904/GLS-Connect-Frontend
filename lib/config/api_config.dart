import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _customBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const bool isEmulator = bool.fromEnvironment('IS_EMULATOR', defaultValue: false);

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }
    if (isEmulator) {
      return "http://10.0.2.2:8080";
    }
    if (kIsWeb) {
      return "http://localhost:8080";
    }
    return "http://localhost:8080";
  }
}

