import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_profile_model.dart';
import '../utils/storage_service.dart';
import '../config/api_config.dart';
import 'package:image_picker/image_picker.dart';

class StudentProfileService {
  static Future<StudentProfileModel?> getProfile() async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/student/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return StudentProfileModel.fromJson(
          jsonDecode(response.body),
        );
      }

      if (response.statusCode == 404) {
        return StudentProfileModel(
          department: "MCA",
          degree: "Master of Computer Applications",
          semester: "Semester 4",
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<StudentProfileModel?> getProfileByUserId(int userId) async {
    try {
      final token = await StorageService.getToken();

      final headers = {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      };

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/student/user/$userId"),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return StudentProfileModel.fromJson(
          jsonDecode(response.body),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveProfile(StudentProfileModel profile) async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/student/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(profile.toJson()),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      final token = await StorageService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConfig.baseUrl}/api/users/profile-image"),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
