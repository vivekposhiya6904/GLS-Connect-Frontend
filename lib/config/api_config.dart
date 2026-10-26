import 'package:flutter/foundation.dart';

class ApiConfig {
  // Optional override:
  // flutter run --dart-define=API_BASE_URL=http://192.168.0.23:8080
  static const String _customBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl.trim();
    }

    if (kReleaseMode) {
      // In production release builds, do not silently fallback to a developer's private LAN IP.
      throw StateError(
        "Production API_BASE_URL is not configured! Build release with --dart-define=API_BASE_URL=https://<your-remote-api>",
      );
    }

    // Android Emulator and physical Android device with adb reverse tcp:8080 tcp:8080
    return "http://192.168.0.6:8080";
  }
}