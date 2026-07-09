import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/faculty_profile_model.dart';
import '../utils/storage_service.dart';
import '../config/api_config.dart';

class FacultyProfileService {

  static Future<FacultyProfileModel?> getProfile() async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        print("❌ JWT token is null");
        return null;
      }

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/faculty/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      print("GET FACULTY PROFILE STATUS: ${response.statusCode}");
      print("GET FACULTY PROFILE BODY: ${response.body}");

      if (response.statusCode == 200) {
        return FacultyProfileModel.fromJson(
          jsonDecode(response.body),
        );
      }

      // First time login -> Profile row does not exist
      // Backend returns 404 -> We return empty profile instead of null
      if (response.statusCode == 404 || response.statusCode == 500) {
        print("ℹ No faculty profile found. Returning empty model.");
        return FacultyProfileModel(
          department: null,
          designation: null,
          qualification: null,
          specialization: null,
          experienceYears: null,
          email: null,
          contactNumber: null,
          researchInterests: null,
          bio: null,
          linkedInUrl: null,
          teachingExperience: null,
          industryExperience: null,
          publicationsCount: null,
          certifications: null,
          achievements: null,
          skills: null,
          studentsGuided: null,
          projectsSupervised: null,
        );
      }

      return null;
    } catch (e) {
      print("🔥 Error in getProfile(): $e");
      return null;
    }
  }

  static Future<bool> updateProfile(FacultyProfileModel profile, {required bool isCreate}) async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        print("❌ JWT token is null");
        return false;
      }

      // Backend: POST for create, PUT for update (or POST also handles both)
      final response = await (isCreate
          ? http.post(
              Uri.parse("${ApiConfig.baseUrl}/api/faculty/profile"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(profile.toJson()),
            )
          : http.put(
              Uri.parse("${ApiConfig.baseUrl}/api/faculty/profile"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(profile.toJson()),
            )).timeout(const Duration(seconds: 15));

      print("UPDATE FACULTY PROFILE STATUS: ${response.statusCode}");
      print("UPDATE FACULTY PROFILE BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("🔥 Error in updateProfile(): $e");
      return false;
    }
  }
}
