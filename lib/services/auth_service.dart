import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alumni_management/config/api_config.dart';
import '../utils/storage_service.dart';

class LoginResult {
  final bool success;
  final bool isUnverified;
  final String? errorMessage;
  final String? email;
  final bool otpDispatched;
  final int cooldownSeconds;
  final String purpose;

  LoginResult({
    required this.success,
    this.isUnverified = false,
    this.errorMessage,
    this.email,
    this.otpDispatched = false,
    this.cooldownSeconds = 60,
    this.purpose = "ACCOUNT_ACTIVATION",
  });
}

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
  // LOGIN USER (EXTENDED)
  // ===============================

  static Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/users/login");

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

        return LoginResult(success: true);
      }

      String errorMsg = "Invalid email or password";
      bool isUnverified = false;
      String? unverifiedEmail;
      bool otpDispatched = false;
      int cooldownSeconds = 60;
      String purpose = "ACCOUNT_ACTIVATION";

      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data['message'] != null) {
            errorMsg = data['message'].toString();
          }
          if (data['email'] != null) {
            unverifiedEmail = data['email'].toString();
          }
          if (data['otpDispatched'] != null) {
            otpDispatched = data['otpDispatched'] == true;
          }
          if (data['cooldownSeconds'] != null) {
            cooldownSeconds = int.tryParse(data['cooldownSeconds'].toString()) ?? 60;
          }
          if (data['purpose'] != null) {
            purpose = data['purpose'].toString();
          }
        }
      } catch (_) {}

      if (response.statusCode == 403 || errorMsg.toLowerCase().contains("not verified")) {
        isUnverified = true;
      }

      return LoginResult(
        success: false,
        isUnverified: isUnverified,
        errorMessage: errorMsg,
        email: unverifiedEmail ?? email,
        otpDispatched: otpDispatched,
        cooldownSeconds: cooldownSeconds,
        purpose: purpose,
      );

    } catch (e) {
      throw Exception("Network Error: $e");
    }
  }

  // Backward compatible loginUser method
  static Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    final result = await login(email: email, password: password);
    return result.success;
  }

  // ===============================
  // RESTORE SESSION (STARTUP)
  // ===============================
  static Future<bool> restoreSession() async {
    final token = await StorageService.getToken();
    final isLoggedIn = await StorageService.getLoginStatus();

    if (token == null || token.trim().isEmpty || !isLoggedIn) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/users/me"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data['name'] != null) await StorageService.saveUserName(data['name'].toString());
          if (data['role'] != null || data['roleName'] != null) {
            final role = (data['role'] ?? data['roleName']).toString();
            await StorageService.saveUserRole(role);
          }
          if (data['email'] != null) await StorageService.saveUserEmail(data['email'].toString());
          await StorageService.saveLoginStatus(true);
        }
        return true;
      }

      // If token expired / 401 Unauthorized, attempt refresh
      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshResponse = await http.post(
          Uri.parse("${ApiConfig.baseUrl}/api/users/refresh-token"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ).timeout(const Duration(seconds: 8));

        if (refreshResponse.statusCode == 200) {
          final refreshData = jsonDecode(refreshResponse.body);
          if (refreshData is Map && refreshData['token'] != null) {
            await StorageService.saveToken(refreshData['token'].toString());
            if (refreshData['name'] != null) await StorageService.saveUserName(refreshData['name'].toString());
            if (refreshData['role'] != null) await StorageService.saveUserRole(refreshData['role'].toString());
            await StorageService.saveLoginStatus(true);
            return true;
          }
        }

        // If refresh failed because session was genuinely invalid/revoked:
        await StorageService.logout();
        return false;
      }

      // On server 50x or temporary error, preserve login so user can access cached data offline
      return true;
    } catch (_) {
      // Backend sleeping / cold-start / device offline: preserve session for cached dashboard
      return true;
    }
  }

  // ===============================
  // EMAIL VERIFICATION (SEND OTP)
  // ===============================

  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    String purpose = "ACCOUNT_REGISTRATION",
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/verification/send");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "purpose": purpose,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to send verification code');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ===============================
  // EMAIL VERIFICATION (VERIFY OTP)
  // ===============================

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    String purpose = "ACCOUNT_REGISTRATION",
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/verification/verify");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "purpose": purpose,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ===============================
  // EMAIL VERIFICATION (RESEND OTP)
  // ===============================

  static Future<Map<String, dynamic>> resendOtp({
    required String email,
    String purpose = "ACCOUNT_REGISTRATION",
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/verification/resend");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "purpose": purpose,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to resend code');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
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
