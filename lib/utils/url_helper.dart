import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to safely normalize and launch external web URLs
class UrlHelper {
  UrlHelper._();

  /// Normalize a URL string by prepending https:// if scheme is missing
  static Uri? parseAndNormalizeUrl(String? rawUrl) {
    if (rawUrl == null) return null;
    var trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    if (!trimmed.startsWith(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://'))) {
      if (!trimmed.contains('.') || trimmed.contains(' ')) {
        return null;
      }
      trimmed = 'https://$trimmed';
    }

    try {
      final uri = Uri.parse(trimmed);
      if (uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.contains('.') &&
          !uri.host.contains(' ')) {
        return uri;
      }
    } catch (_) {}
    return null;
  }

  /// Launch external web URL with error handling and user feedback
  static Future<void> launchWebUrl(BuildContext context, String rawUrl) async {
    final uri = parseAndNormalizeUrl(rawUrl);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid website address."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not open link: ${uri.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unable to open browser for: $rawUrl"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
