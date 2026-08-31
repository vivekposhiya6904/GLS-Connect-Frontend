import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';

class StorageService {

  // ===============================
  // LOGIN STATUS
  // ===============================
  static Future<void> saveLoginStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", value);
    print("✅ Saved login status: $value");
  }

  static Future<bool> getLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getBool("isLoggedIn") ?? false;
    print("📱 Retrieved login status: $status");
    return status;
  }

  // ===============================
  // USER NAME
  // ===============================
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("userName", name);
    print("✅ Saved user name: $name");
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString("userName");
    print("👤 Retrieved user name: $name");
    return name;
  }

  // ===============================
  // USER ROLE
  // ===============================
  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("userRole", role);
    print("✅ Saved user role: $role");
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("userRole");
    print("👔 Retrieved user role: $role");
    return role;
  }

  // ===============================
  // USER EMAIL
  // ===============================
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_email", email);
    print("📧 Saved user email: $email");
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("user_email");
    print("📧 Retrieved user email: $email");
    return email;
  }

  // ===============================
  // 🔥 JWT TOKEN STORAGE
  // ===============================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
    print("🔐 Token saved successfully");
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    print("🔐 Retrieved token: $token");
    return token;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    print("🗑️ Token cleared");
  }

  // ===============================
  // LOGOUT
  // ===============================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      ChatService().disconnect();
    } catch (_) {}
    print("🗑️ User logged out, all data cleared");
  }
}
