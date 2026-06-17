import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/job_model.dart';
import '../utils/storage_service.dart';

class JobService {
  /// Get all jobs from backend
  static Future<List<JobModel>?> getAllJobs() async {
    try {
      final token = await StorageService.getToken();

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/jobs"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => JobModel.fromJson(json)).toList();
      }

      return null;
    } catch (e) {
      print("❌ Error fetching jobs: $e");
      return null;
    }
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
  }) async {
    try {
      final token = await StorageService.getToken();

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/jobs"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
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
  }) async {
    try {
      final token = await StorageService.getToken();

      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/api/jobs/$jobId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
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
          "Authorization": "Bearer $token"
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

