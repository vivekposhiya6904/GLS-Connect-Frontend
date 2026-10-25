import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/job_model.dart';
import '../utils/storage_service.dart';
import 'cache_service.dart';

class JobService {
  static const String _allJobsKey = "jobs_all";
  static const String _myJobsKey = "jobs_my";

  /// Get all jobs from backend with offline caching & fallback
  static Future<List<JobModel>?> getAllJobs({
    http.Client? client,
    bool forceRefresh = false,
  }) async {
    final userEmail = await StorageService.getUserEmail() ?? "";

    return CacheService.deduplicate("jobs_all_$userEmail", () async {
      final startTime = DateTime.now();
      final httpClient = client ?? http.Client();
      final shouldClose = client == null;

      try {
        final token = await StorageService.getToken();

        final response = await httpClient
            .get(
              Uri.parse("${ApiConfig.baseUrl}/api/jobs"),
              headers: {
                "Content-Type": "application/json",
                if (token != null) "Authorization": "Bearer $token",
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          if (userEmail.isNotEmpty) {
            await CacheService.saveData(
              key: _allJobsKey,
              userEmail: userEmail,
              data: jsonList,
              isSensitive: false,
              requestStartTime: startTime,
            );
          }
          final jobs = jsonList.map((json) => JobModel.fromJson(json)).toList();
          jobs.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
          return jobs;
        }
      } catch (e) {
        print("❌ Error fetching jobs from network: $e");
      } finally {
        if (shouldClose) {
          httpClient.close();
        }
      }

      // Fallback to cached jobs
      if (userEmail.isNotEmpty) {
        final cached = await getCachedAllJobs(email: userEmail);
        if (cached != null) {
          print("📦 Returning ${cached.data.length} cached jobs for $userEmail");
          return cached.data;
        }
      }

      return null;
    });
  }

  static Future<CacheResult<List<JobModel>>?> getCachedAllJobs({String? email}) async {
    final userEmail = email ?? await StorageService.getUserEmail() ?? "";
    if (userEmail.isEmpty) return null;

    return CacheService.loadData<List<JobModel>>(
      key: _allJobsKey,
      userEmail: userEmail,
      parser: (data) {
        final jobs = (data as List).map((json) => JobModel.fromJson(json)).toList();
        jobs.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        return jobs;
      },
      isSensitive: false,
    );
  }

  static Future<bool> saveJobsToCache(List<Map<String, dynamic>> rawJobs, {String? email}) async {
    final userEmail = email ?? await StorageService.getUserEmail() ?? "";
    if (userEmail.isEmpty) return false;
    return CacheService.saveData(
      key: _allJobsKey,
      userEmail: userEmail,
      data: rawJobs,
      isSensitive: false,
    );
  }

  static Future<bool> saveMyJobsToCache(List<Map<String, dynamic>> rawJobs, {String? email}) async {
    final userEmail = email ?? await StorageService.getUserEmail() ?? "";
    if (userEmail.isEmpty) return false;
    return CacheService.saveData(
      key: _myJobsKey,
      userEmail: userEmail,
      data: rawJobs,
      isSensitive: false,
    );
  }

  /// Get current user's posted jobs from backend with offline caching & fallback
  static Future<List<JobModel>?> getMyJobs({
    http.Client? client,
    bool forceRefresh = false,
  }) async {
    final userEmail = await StorageService.getUserEmail() ?? "";

    return CacheService.deduplicate("jobs_my_$userEmail", () async {
      final startTime = DateTime.now();
      final httpClient = client ?? http.Client();
      final shouldClose = client == null;

      try {
        final token = await StorageService.getToken();

        final response = await httpClient
            .get(
              Uri.parse("${ApiConfig.baseUrl}/api/jobs/my"),
              headers: {
                "Content-Type": "application/json",
                if (token != null) "Authorization": "Bearer $token",
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          if (userEmail.isNotEmpty) {
            await CacheService.saveData(
              key: _myJobsKey,
              userEmail: userEmail,
              data: jsonList,
              isSensitive: false,
              requestStartTime: startTime,
            );
          }
          final jobs = jsonList.map((json) => JobModel.fromJson(json)).toList();
          jobs.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
          return jobs;
        }

        if (response.statusCode == 401 || response.statusCode == 403) {
          debugPrint(
            "🔒 Authentication failure fetching my jobs (${response.statusCode}): ${response.body}",
          );
          return null;
        }

        if (response.statusCode == 404) {
          debugPrint(
            "⚠️ /api/jobs/my endpoint not found (404). Falling back to filtered getAllJobs().",
          );
          final email = await StorageService.getUserEmail();
          if (email != null && email.trim().isNotEmpty) {
            final all = await getAllJobs(client: httpClient);
            return all
                ?.where(
                  (j) =>
                      j.userEmail.trim().toLowerCase() ==
                      email.trim().toLowerCase(),
                )
                .toList();
          }
          return null;
        }

        if (response.statusCode >= 500) {
          debugPrint(
            "❌ Server error fetching my jobs (${response.statusCode}): ${response.body}",
          );
          return null;
        }
      } on TimeoutException catch (e) {
        debugPrint("⏱️ Timeout fetching my jobs: $e");
      } on SocketException catch (e) {
        debugPrint("📡 Network error fetching my jobs: $e");
      } catch (e) {
        debugPrint("❌ Error fetching my jobs: $e");
      } finally {
        if (shouldClose) {
          httpClient.close();
        }
      }

      // Fallback to cached my-jobs
      if (userEmail.isNotEmpty) {
        final cached = await getCachedMyJobs(email: userEmail);
        if (cached != null) {
          print("📦 Returning ${cached.data.length} cached my-jobs for $userEmail");
          return cached.data;
        }
      }

      return null;
    });
  }

  static Future<CacheResult<List<JobModel>>?> getCachedMyJobs({String? email}) async {
    final userEmail = email ?? await StorageService.getUserEmail() ?? "";
    if (userEmail.isEmpty) return null;

    return CacheService.loadData<List<JobModel>>(
      key: _myJobsKey,
      userEmail: userEmail,
      parser: (data) {
        final jobs = (data as List).map((json) => JobModel.fromJson(json)).toList();
        jobs.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        return jobs;
      },
      isSensitive: false,
    );
  }

  /// Create a new job
  static Future<bool> createJob({
    required String companyName,
    required String jobTitle,
    required String location,
    required String salary,
    required String jobDescription,
    required String skillsRequired,
    required String experienceRequired,
    required String joiningType,
    required String jobType,
    required String lastDateToApply,
    String? companyLink,
    String? companyEmail,
  }) async {
    try {
      final token = await StorageService.getToken();

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/jobs"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "companyName": companyName,
          "jobTitle": jobTitle,
          "location": location,
          "salary": salary,
          "jobDescription": jobDescription,
          "skillsRequired": skillsRequired,
          "experienceRequired": experienceRequired,
          "joiningType": joiningType,
          "jobType": jobType,
          "lastDateToApply": lastDateToApply,
          "companyLink": companyLink,
          "companyEmail": companyEmail,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Job created successfully");
        return true;
      }

      print("❌ Failed to create job: ${response.statusCode}");
      return false;
    } catch (e) {
      print("❌ Error creating job: $e");
      return false;
    }
  }

  /// Update an existing job
  static Future<bool> updateJob({
    required int jobId,
    required String companyName,
    required String jobTitle,
    required String location,
    required String salary,
    required String jobDescription,
    required String skillsRequired,
    required String experienceRequired,
    required String joiningType,
    required String jobType,
    required String lastDateToApply,
    String? companyLink,
    String? companyEmail,
  }) async {
    try {
      final token = await StorageService.getToken();

      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/api/jobs/$jobId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "companyName": companyName,
          "jobTitle": jobTitle,
          "location": location,
          "salary": salary,
          "jobDescription": jobDescription,
          "skillsRequired": skillsRequired,
          "experienceRequired": experienceRequired,
          "joiningType": joiningType,
          "jobType": jobType,
          "lastDateToApply": lastDateToApply,
          "companyLink": companyLink,
          "companyEmail": companyEmail,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Job updated successfully");
        return true;
      }

      print("❌ Failed to update job: ${response.statusCode}");
      return false;
    } catch (e) {
      print("❌ Error updating job: $e");
      return false;
    }
  }

  /// Delete a job
  static Future<bool> deleteJob(int jobId) async {
    try {
      final token = await StorageService.getToken();

      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/api/jobs/$jobId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ Job deleted successfully");
        return true;
      }

      print("❌ Failed to delete job: ${response.statusCode}");
      return false;
    } catch (e) {
      print("❌ Error deleting job: $e");
      return false;
    }
  }
}
