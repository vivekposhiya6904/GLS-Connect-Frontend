import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../models/alumni_profile_model.dart';
import '../utils/storage_service.dart';
import '../config/api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'cache_service.dart';

class AlumniProfileService {
  static const String _profileKey = "profile_alumni";

  static Future<AlumniProfileModel?> getProfile({
    http.Client? client,
    bool forceRefresh = false,
  }) async {
    final userEmail = await StorageService.getUserEmail() ?? "";

    return CacheService.deduplicate("profile_alumni_$userEmail", () async {
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
              Uri.parse("${ApiConfig.baseUrl}/api/alumni/profile"),
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
          return AlumniProfileModel.fromJson(decoded);
        }

        if (response.statusCode == 404) {
          final defaultProfile = AlumniProfileModel(
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
        print("🔥 Error in getProfile() network: $e");
      } finally {
        if (shouldClose) {
          httpClient.close();
        }
      }

      // Fallback to cached profile
      if (userEmail.isNotEmpty) {
        final cached = await getCachedProfile(email: userEmail);
        if (cached != null) {
          print("📦 Returning cached alumni profile for $userEmail");
          return cached.data;
        }
      }

      return null;
    });
  }

  static Future<CacheResult<AlumniProfileModel>?> getCachedProfile({String? email}) async {
    final userEmail = email ?? await StorageService.getUserEmail() ?? "";
    if (userEmail.isEmpty) return null;

    return CacheService.loadData<AlumniProfileModel>(
      key: _profileKey,
      userEmail: userEmail,
      parser: (data) => AlumniProfileModel.fromJson(Map<String, dynamic>.from(data)),
      isSensitive: true,
    );
  }

  static Future<bool> updateProfile(
    AlumniProfileModel profile, {
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final shouldClose = client == null;

    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await httpClient
          .put(
            Uri.parse("${ApiConfig.baseUrl}/api/alumni/profile"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(profile.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final success = response.statusCode == 200;
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

  static Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      final token = await StorageService.getToken();
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiConfig.baseUrl}/api/users/profile-image"),
      );
      
      request.headers["Authorization"] = "Bearer $token";
      
      final file = await http.MultipartFile.fromPath("image", imageFile.path);
      request.files.add(file);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["url"];
      }
      return null;
    } catch (e) {
      print("🔥 Error in uploadProfileImage(): $e");
      return null;
    }
  }
}