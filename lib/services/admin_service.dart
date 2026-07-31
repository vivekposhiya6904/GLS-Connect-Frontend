import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/event_model.dart';
import '../models/post_model.dart';
import '../utils/storage_service.dart';

class AdminUserDto {
  final int id;
  final String name;
  final String email;
  final String roleName;
  final String department;

  AdminUserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.roleName,
    required this.department,
  });

  factory AdminUserDto.fromJson(Map<String, dynamic> json) {
    return AdminUserDto(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roleName: json['roleName'] ?? json['role'] ?? 'USER',
      department: json['department'] ?? 'MCA',
    );
  }
}

class AdminService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // Get all users
  static Future<List<AdminUserDto>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/admin/users"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => AdminUserDto.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error in getAllUsers: $e");
      return [];
    }
  }

  // Get users by role (ALUMNI, FACULTY, USER, ADMIN)
  static Future<List<AdminUserDto>> getUsersByRole(String roleName) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/admin/role/$roleName"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => AdminUserDto.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error in getUsersByRole: $e");
      return [];
    }
  }

  // Create User by Admin
  static Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    required String roleName,
    required String department,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/admin/users"),
        headers: headers,
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "roleName": roleName,
          "department": department,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Error in createUser: $e");
      return false;
    }
  }

  // Delete User
  static Future<bool> deleteUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/api/admin/users/$userId"),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error in deleteUser: $e");
      return false;
    }
  }

  // Get Pending Events
  static Future<List<EventModel>> getPendingEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/events/admin/pending"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => EventModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error in getPendingEvents: $e");
      return [];
    }
  }

  // Approve Event
  static Future<bool> approveEvent(int eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/api/events/admin/approve/$eventId"),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error in approveEvent: $e");
      return false;
    }
  }

  // Reject Event
  static Future<bool> rejectEvent(int eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/api/events/admin/reject/$eventId"),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error in rejectEvent: $e");
      return false;
    }
  }

  // Delete Event
  static Future<bool> deleteEvent(int eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/api/events/admin/delete/$eventId"),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error in deleteEvent: $e");
      return false;
    }
  }

  // Delete Post
  static Future<bool> deletePost(int postId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/api/posts/$postId"),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error in deletePost: $e");
      return false;
    }
  }
}
