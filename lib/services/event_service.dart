import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/event_model.dart';
import '../utils/storage_service.dart';

class EventService {
  static Future<List<EventModel>?> getAllEvents() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/events"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => EventModel.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      print("❌ Error fetching events: $e");
      return null;
    }
  }

  static Future<List<EventModel>?> getMyEvents() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/events/my"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => EventModel.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      print("❌ Error fetching my events: $e");
      return null;
    }
  }

  static Future<bool> createEvent({
    required String title,
    required String description,
    required String location,
    required String eventDate,
    required String targetDepartment,
    String? note,
    XFile? imageFile,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConfig.baseUrl}/api/events"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['location'] = location;
      request.fields['eventDate'] = eventDate;
      request.fields['targetDepartment'] = targetDepartment;
      request.fields['note'] = note ?? '';

      if (imageFile != null) {
        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: imageFile.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('image', imageFile.path),
          );
        }
      }

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Event created successfully");
        return true;
      }
      print("❌ Failed to create event: ${response.statusCode}");
      return false;
    } catch (e) {
      print("❌ Error creating event: $e");
      return false;
    }
  }
}
