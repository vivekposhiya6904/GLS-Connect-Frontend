import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../models/student_profile_model.dart';
import '../utils/storage_service.dart';
import '../config/api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'cache_service.dart';

class StudentProfileService {
  static const String _profileKey = "profile_student";

  static Future<StudentProfileModel?> getProfile({
    http.Client? client,
    bool forceRefresh = false,
  }) async {
    final userEmail = await StorageService.getUserEmail() ?? "";

    return CacheService.deduplicate("profile_student_$userEmail", () async {
      final startTime = DateTime.now();
      final httpClient = client ?? http.Client();
      final shouldClose = client == null;

      try {
        final token = await StorageService.getToken();
        if (token == null) return null;

        final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
        final timeoutDuration = isTest ? const Duration(milliseconds: 300) : const Duration(seconds: 15);

        final response = await httpClient
            .get(
              Uri.parse("${ApiConfig.baseUrl}/api/student/profile"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
            )
            .timeout(timeoutDuration);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (userEmail.isNotEmpty) {
            await CacheService.saveData(
              key: _profileKey,
              userEmail: userEmail,
              data: decoded,
              isSensitive: true,
              requestStartTime: startTime,
            );
          }
          return StudentProfileModel.fromJson(decoded);
        }

        if (response.statusCode == 404) {
          final defaultProfile = StudentProfileModel(
            department: "MCA",
            degree: "Master of Computer Applications",
            semester: "Semester 4",
          );
          if (userEmail.isNotEmpty) {
            await CacheService.saveData(
              key: _profileKey,
              userEmail: userEmail,
              data: defaultProfile.toJson(),
              isSensitive: true,
              requestStartTime: startTime,
            );
          }
          return defaultProfile;
        }
      } catch (e) {
        print("❌ Error fetching student profile from network: $e");
      } finally {
        if (shouldClose) {
          httpClient.close();
        }
      }

      // Fallback to cached profile
      if (userEmail.isNotEmpty) {
        final cached = await getCachedProfile(email: userEmail);
        if (cached != null) {
          print("📦 Returning cached student profile for $userEmail");
          return cached.data;
        }
      }

      return null;
    });
  }

  static Future<CacheResult<StudentProfileModel>?> getCachedProfile({String? email}) async {
    final userEmail = email ?? await StorageService.getUserEmail() ?? "";
    if (userEmail.isEmpty) return null;

    return CacheService.loadData<StudentProfileModel>(
      key: _profileKey,
      userEmail: userEmail,
      parser: (data) => StudentProfileModel.fromJson(Map<String, dynamic>.from(data)),
      isSensitive: true,
    );
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

  static Future<bool> saveProfile(StudentProfileModel profile, {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    final shouldClose = client == null;

    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await httpClient
          .post(
            Uri.parse("${ApiConfig.baseUrl}/api/student/profile"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(profile.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) {
        final userEmail = await StorageService.getUserEmail() ?? "";
        if (userEmail.isNotEmpty) {
          await CacheService.saveData(
            key: _profileKey,
            userEmail: userEmail,
            data: profile.toJson(),
            isSensitive: true,
          );
        }
      }
      return success;
    } catch (e) {
      return false;
    } finally {
      if (shouldClose) {
        httpClient.close();
      }
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
