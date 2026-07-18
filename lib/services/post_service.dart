import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/post_model.dart';
import '../utils/storage_service.dart';

class PostService {
  static Future<List<PostModel>?> getAllPosts() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/posts"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => PostModel.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      print("❌ Error fetching posts: $e");
      return null;
    }
  }

  static Future<List<PostModel>?> getMyPosts() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/posts/my"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => PostModel.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      print("❌ Error fetching my posts: $e");
      return null;
    }
  }

  static Future<bool> createPost({
    required String content,
    XFile? imageFile,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConfig.baseUrl}/api/posts"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['content'] = content;

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
        print("✅ Post created successfully");
        return true;
      }
      print("❌ Failed to create post: ${response.statusCode}");
      return false;
    } catch (e) {
      print("❌ Error creating post: $e");
      return false;
    }
  }

  static Future<bool> deletePost(int id) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/api/posts/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error deleting post: $e");
      return false;
    }
  }
}
