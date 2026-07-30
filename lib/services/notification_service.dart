import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification_model.dart';
import '../utils/storage_service.dart';

class NotificationService {
  static Future<List<NotificationModel>> getNotifications() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/notifications"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<void> markAllAsRead() async {
    final token = await StorageService.getToken();
    await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/notifications/mark-read"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
  }

  static Future<int> getUnreadCount() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/notifications/unread-count"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return int.tryParse(response.body) ?? 0;
    }
    return 0;
  }
}
