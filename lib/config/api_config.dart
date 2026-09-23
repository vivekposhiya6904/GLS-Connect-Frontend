import 'package:flutter/foundation.dart';

class ApiConfig {
  // Optional override:
  // flutter run --dart-define=API_BASE_URL=http://10.76.161.155:8080
  static const String _customBaseUrl =
  String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }

    // Android Emulator and physical Android device
    return "http://192.168.0.32:8080";
  }
}