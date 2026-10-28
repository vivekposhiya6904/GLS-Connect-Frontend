import 'package:flutter/foundation.dart';

class ApiConfig {
  // Optional override:
  // flutter run --dart-define=API_BASE_URL=http://192.168.0.16:8080
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
    return "http://192.168.0.16:8080";
  }

  /// Resolves an image URL or resource path against the configured backend baseUrl.
  /// Handles:
  /// - Full URLs (http:// or https://) returned as-is
  /// - Windows backslashes normalized to forward slashes
  /// - Missing leading slashes
  /// - Optional cache-busting timestamp
  static String? resolveUrl(String? rawUrl, {bool cacheBust = false}) {
    if (rawUrl == null) return null;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (cacheBust) {
        final sep = trimmed.contains('?') ? '&' : '?';
        return '$trimmed${sep}t=${DateTime.now().millisecondsSinceEpoch}';
      }
      return trimmed;
    }

    String path = trimmed.replaceAll(r'\', '/');
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final fullUrl = '$base$path';

    if (cacheBust) {
      final sep = fullUrl.contains('?') ? '&' : '?';
      return '$fullUrl${sep}t=${DateTime.now().millisecondsSinceEpoch}';
    }
    return fullUrl;
  }
}
