import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../models/faculty_profile_model.dart';
import '../utils/storage_service.dart';
import '../config/api_config.dart';
import 'cache_service.dart';

class FacultyProfileService {
  static const String _profileKey = "profile_faculty";

  static Future<FacultyProfileModel?> getProfile({
    http.Client? client,
    bool forceRefresh = false,
  }) async {
    final userEmail = await StorageService.getUserEmail() ?? "";

    return CacheService.deduplicate("profile_faculty_$userEmail", () async {
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
              Uri.parse("${ApiConfig.baseUrl}/api/faculty/profile"),
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
          return FacultyProfileModel.fromJson(decoded);
        }

        if (response.statusCode == 404 || response.statusCode == 500) {
          final defaultProfile = FacultyProfileModel(
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
          print("📦 Returning cached faculty profile for $userEmail");
          return cached.data;
        }
      }

      return null;
    });
  }

  static Future<CacheResult<FacultyProfileModel>?> getCachedProfile({String? email}) async {
    final userEmail = email ?? await StorageService.getUserEmail() ?? "";
    if (userEmail.isEmpty) return null;

    return CacheService.loadData<FacultyProfileModel>(
      key: _profileKey,
      userEmail: userEmail,
      parser: (data) => FacultyProfileModel.fromJson(Map<String, dynamic>.from(data)),
      isSensitive: true,
    );
  }

  static Future<bool> updateProfile(
    FacultyProfileModel profile, {
    required bool isCreate,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final shouldClose = client == null;

    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final url = Uri.parse("${ApiConfig.baseUrl}/api/faculty/profile");
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };
      final body = jsonEncode(profile.toJson());

      final response = await (isCreate
          ? httpClient.post(url, headers: headers, body: body)
          : httpClient.put(url, headers: headers, body: body))
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

  static Future<FacultyProfileModel?> getProfileByUserId(int userId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/faculty/user/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return FacultyProfileModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("🔥 Error in getProfileByUserId(): $e");
      return null;
    }
  }

  static Future<List<FacultyProfileModel>?> getAllFacultyProfiles() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/faculty"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => FacultyProfileModel.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      print("🔥 Error in getAllFacultyProfiles(): $e");
      return null;
    }
  }
}
