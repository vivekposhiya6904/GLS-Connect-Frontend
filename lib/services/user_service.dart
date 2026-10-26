import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class UserService {

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
}