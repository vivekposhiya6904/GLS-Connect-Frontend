import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/event_model.dart';
import '../utils/storage_service.dart';
import 'cache_service.dart';
import 'package:http_parser/http_parser.dart';

class EventService {
  static const String _allEventsKey = "events_all";
  static const String _myEventsKey = "events_my";

  static MediaType _getImageMediaType(XFile file) {
    final name = file.name.toLowerCase();

    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.webp')) return MediaType('image', 'webp');
    if (name.endsWith('.gif')) return MediaType('image', 'gif');
    if (name.endsWith('.jpg') || name.endsWith('.jpeg'))
      return MediaType('image', '');

    return MediaType('image', 'jpeg');
  }

  static Future<List<EventModel>?> getAllEvents({
    http.Client? client,
    bool forceRefresh = false,
  }) async {
    final userEmail = await StorageService.getUserEmail() ?? "";

    return CacheService.deduplicate("events_all_$userEmail", () async {
      final startTime = DateTime.now();
      final httpClient = client ?? http.Client();
      final shouldClose = client == null;

      try {
        final token = await StorageService.getToken();
        final response = await httpClient
            .get(
              Uri.parse("${ApiConfig.baseUrl}/api/events"),
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
              key: _allEventsKey,
              userEmail: userEmail,
              data: jsonList,
              isSensitive: false,
              requestStartTime: startTime,
            );
          }
          return jsonList.map((json) => EventModel.fromJson(json)).toList();
        }
      } catch (e) {
        print("❌ Error fetching events from network: $e");
      } finally {
        if (shouldClose) {
          httpClient.close();
        }
      }

      // Network request failed or returned non-200: fallback to cached data
      if (userEmail.isNotEmpty) {
        final cached = await getCachedAllEvents(email: userEmail);
        if (cached != null) {
          print(
            "📦 Returning ${cached.data.length} cached events for $userEmail",
          );
          return cached.data;
        }
      }

      return null;
    });
  }

  static Future<CacheResult<List<EventModel>>?> getCachedAllEvents({
    String? email,
  }) async {
    final userEmail = email ?? await StorageService.getUserEmail() ?? "";
    if (userEmail.isEmpty) return null;

    return CacheService.loadData<List<EventModel>>(
      key: _allEventsKey,
      userEmail: userEmail,
      parser: (data) =>
          (data as List).map((json) => EventModel.fromJson(json)).toList(),
      isSensitive: false,
    );
  }

  static Future<bool> saveEventsToCache(
    List<Map<String, dynamic>> rawEvents, {
    String? email,
  }) async {
    final userEmail = email ?? await StorageService.getUserEmail() ?? "";
    if (userEmail.isEmpty) return false;
    return CacheService.saveData(
      key: _allEventsKey,
      userEmail: userEmail,
      data: rawEvents,
      isSensitive: false,
    );
  }

  static Future<List<EventModel>?> getMyEvents({
    http.Client? client,
    bool forceRefresh = false,
  }) async {
    final userEmail = await StorageService.getUserEmail() ?? "";

    return CacheService.deduplicate("events_my_$userEmail", () async {
      final startTime = DateTime.now();
      final httpClient = client ?? http.Client();
      final shouldClose = client == null;

      try {
        final token = await StorageService.getToken();
        final response = await httpClient
            .get(
              Uri.parse("${ApiConfig.baseUrl}/api/events/my"),
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
              key: _myEventsKey,
              userEmail: userEmail,
              data: jsonList,
              isSensitive: false,
              requestStartTime: startTime,
            );
          }
          return jsonList.map((json) => EventModel.fromJson(json)).toList();
        }
      } catch (e) {
        print("❌ Error fetching my events from network: $e");
      } finally {
        if (shouldClose) {
          httpClient.close();
        }
      }

      // Network request failed: fallback to cached data
      if (userEmail.isNotEmpty) {
        final cached = await getCachedMyEvents(email: userEmail);
        if (cached != null) {
          print(
            "📦 Returning ${cached.data.length} cached my-events for $userEmail",
          );
          return cached.data;
        }
      }

      return null;
    });
  }

  static Future<CacheResult<List<EventModel>>?> getCachedMyEvents({
    String? email,
  }) async {
    final userEmail = email ?? await StorageService.getUserEmail() ?? "";
    if (userEmail.isEmpty) return null;

    return CacheService.loadData<List<EventModel>>(
      key: _myEventsKey,
      userEmail: userEmail,
      parser: (data) =>
          (data as List).map((json) => EventModel.fromJson(json)).toList(),
      isSensitive: false,
    );
  }

  static Future<bool> registerForEvent(int eventId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/api/events/$eventId/register"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      debugPrint(
        "Failed to register: ${response.statusCode} - ${response.body}",
      );
      return false;
    } catch (e) {
      debugPrint("Error register for event: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>?> getEventRegistrations(
    int eventId,
  ) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return null;

      final response = await http
          .get(
            Uri.parse("${ApiConfig.baseUrl}/api/events/$eventId/registrations"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        return decoded
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      debugPrint(
        "Failed to load registrations:"
        "${response.statusCode} - ${response.body}",
      );
      return null;
    } catch (e) {
      debugPrint("Error loading event registrations: $e");
      return null;
    }
  }

  static Future<bool?> isRegisteredForEvent(int eventId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return null;

      final response = await http
          .get(
            Uri.parse(
              "${ApiConfig.baseUrl}/api/events/$eventId/registration-status",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as bool;
      }

      debugPrint(
        "Failed to check registration status:"
        "${response.statusCode} - ${response.body}",
      );
      return null;
    } catch (e) {
      debugPrint("Error checking registration status: $e");
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
        final mediaType = _getImageMediaType(imageFile);

        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: imageFile.name,
              contentType: mediaType,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
              contentType: mediaType,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Event created successfully");
        return true;
      }
      print(
        "❌ Failed to create event: ${response.statusCode} - ${response.body}",
      );
      return false;
    } catch (e) {
      print("❌ Error creating event: $e");
      return false;
    }
  }

  static Future<bool> updateEvent({
    required int eventId,
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
        'PUT',
        Uri.parse("${ApiConfig.baseUrl}/api/events/$eventId"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['location'] = location;
      request.fields['eventDate'] = eventDate;
      request.fields['targetDepartment'] = targetDepartment;
      request.fields['note'] = note ?? '';

      if (imageFile != null) {
        final mediaType = _getImageMediaType(imageFile);

        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: imageFile.name,
              contentType: mediaType,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
              contentType: mediaType,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Event updated successfully");
        return true;
      }
      print(
        "❌ Failed to update event: ${response.statusCode}-${response.body}",
      );
      return false;
    } catch (e) {
      print("❌ Error updating event: $e");
      return false;
    }
  }
}
