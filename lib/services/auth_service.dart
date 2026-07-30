import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alumni_management/config/api_config.dart';
import '../utils/storage_service.dart';

class AuthService {

  // ===============================
  // REGISTER USER
  // ===============================

  static Future<http.Response> registerUser({
    required String name,
    required String email,
    required String password,
    required String universityNo,
  }) async {

    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/users",
    );

    try {

      final response = await http.post(

        url,

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({

          "name": name,
          "email": email,
          "password": password,
          "universityNumber": universityNo,

          // DEFAULT ROLE
          "role": {
            "roleName": "ALUMNI"
          }
        }),
      );

      return response;

    } catch (e) {

      throw Exception("Network Error: $e");
    }
  }

  // ===============================
  // LOGIN USER
  // ===============================

  static Future<bool> loginUser({
    required String email,
    required String password,
  }) async {

    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/users/login",
    );

    try {

      final response = await http.post(

        url,

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        final token = data['token'];
        final name = data['name'];
        final role = data['role'];

        await StorageService.saveToken(token);
        await StorageService.saveUserName(name);
        await StorageService.saveUserRole(role);
        await StorageService.saveUserEmail(email);
        await StorageService.saveLoginStatus(true);

        return true;
      }

      return false;

    } catch (e) {

      throw Exception("Network Error: $e");
    }
  }

  // ===============================
  // FORGOT PASSWORD (REQUEST OTP)
  // ===============================

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/users/forgot-password");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'User not found');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ===============================
  // RESET PASSWORD
  // ===============================

  static Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/users/reset-password");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "newPassword": newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }
}