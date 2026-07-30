import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/profile_view_model.dart';
import '../utils/storage_service.dart';

class ProfileViewService {
  static Future<void> logProfileView(String ownerEmail) async {
    try {
      final token = await StorageService.getToken();
      await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/profile-views/log?ownerEmail=$ownerEmail"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
    } catch (e) {
      print("🔥 Error in logProfileView(): $e");
    }
  }

  static Future<List<ProfileViewModel>> getProfileViews() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/profile-views"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProfileViewModel.fromJson(json)).toList();
      }
    } catch (e) {
      print("🔥 Error in getProfileViews(): $e");
    }
    return [];
  }
}
