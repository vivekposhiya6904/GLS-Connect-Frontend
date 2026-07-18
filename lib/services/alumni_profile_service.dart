import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alumni_profile_model.dart';
import '../utils/storage_service.dart';
import '../config/api_config.dart';

class AlumniProfileService {

  static Future<AlumniProfileModel?> getProfile() async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        print("❌ JWT token is null");
        return null;
      }

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/alumni/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      print("GET PROFILE STATUS: ${response.statusCode}");
      print("GET PROFILE BODY: ${response.body}");

      // ✅ Normal Case (Profile exists)
      if (response.statusCode == 200) {
        return AlumniProfileModel.fromJson(
          jsonDecode(response.body),
        );
      }

      // 🔥 IMPORTANT FIX
      // First time login -> Profile row does not exist
      // Backend returns 404 -> We return empty profile instead of null
      if (response.statusCode == 404) {
        print("ℹ First time login - No profile found. Returning empty model.");

        return AlumniProfileModel(
          batchYear: null,
          degree: null,
          department: null,
          designation: null,
          companyName: null,
          industry: null,
          skills: null,
          workExperience: null,
          linkedInUrl: null,
          githubUrl: null,
          contactNumber: null,
          currentCity: null,
        );
      }

      // ❗ Only logout if 401
      if (response.statusCode == 401) {
        print("⚠ Unauthorized - Token expired or invalid");
      }

      return null;

    } catch (e) {
      print("🔥 Error in getProfile(): $e");
      return null;
    }
  }

  static Future<bool> updateProfile(
      AlumniProfileModel profile) async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        print("❌ JWT token is null");
        return false;
      }

      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/api/alumni/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(profile.toJson()),
      ).timeout(const Duration(seconds: 15));

      print("UPDATE PROFILE STATUS: ${response.statusCode}");
      print("UPDATE PROFILE BODY: ${response.body}");

      return response.statusCode == 200;

    } catch (e) {
      print("🔥 Error in updateProfile(): $e");
      return false;
    }
  }

  static Future<AlumniProfileModel?> getProfileByUserId(int userId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/alumni/user/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AlumniProfileModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("🔥 Error in getProfileByUserId(): $e");
      return null;
    }
  }

  static Future<List<AlumniProfileModel>?> getAllAlumniProfiles() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/alumni"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => AlumniProfileModel.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      print("🔥 Error in getAllAlumniProfiles(): $e");
      return null;
    }
  }
}