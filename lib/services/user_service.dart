import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/storage_service.dart';
import 'api_client.dart';
import 'cache_service.dart';

class UserService {
  static String? lastErrorMessage;

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await ApiClient.get(
        Uri.parse("${ApiConfig.baseUrl}/api/users/me"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    return null;
  }

  /// Update the current user's profile display name across the system.
  static Future<bool> updateUserName(String newName) async {
    lastErrorMessage = null;
    try {
      final cleanName = newName.trim();
      if (cleanName.isEmpty) {
        lastErrorMessage = "Name cannot be empty";
        return false;
      }
      if (cleanName.length < 2) {
        lastErrorMessage = "Name must be at least 2 characters";
        return false;
      }

      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/api/users/profile/name"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"name": cleanName}),
      );

      if (response.statusCode == 200) {
        // 1. Update persisted user name in local storage
        await StorageService.saveUserName(cleanName);

        // 2. Clear user-scoped caches so fresh profile is fetched
        final email = await StorageService.getUserEmail();
        if (email != null && email.isNotEmpty) {
          await CacheService.clearUserCache(email);
        }

        return true;
      }

      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) {
          lastErrorMessage = data['message'].toString();
        } else if (response.body.isNotEmpty && !response.body.startsWith("<")) {
          lastErrorMessage = response.body;
        }
      } catch (_) {
        lastErrorMessage = "Failed to update name (Status ${response.statusCode})";
      }
      return false;
    } catch (e) {
      lastErrorMessage = e.toString();
      return false;
    }
  }
}
