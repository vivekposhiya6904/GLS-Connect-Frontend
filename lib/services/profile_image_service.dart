import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../utils/storage_service.dart';

class ProfileImageUploadException implements Exception {
  final String message;
  final int? statusCode;
  ProfileImageUploadException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ProfileImageService {
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  static MediaType getMediaType(String pathOrName, {String? mimeType}) {
    if (mimeType != null && mimeType.startsWith('image/')) {
      final parts = mimeType.split('/');
      if (parts.length == 2 && parts[1].isNotEmpty) {
        return MediaType('image', parts[1].toLowerCase());
      }
    }

    final lower = pathOrName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (lower.endsWith('.gif')) {
      return MediaType('image', 'gif');
    }
    if (pathOrName.trim().isEmpty) {
      return MediaType('image', 'jpeg');
    }

    throw ArgumentError(
      'Unsupported image format. Allowed formats: JPG, PNG, WEBP, GIF.',
    );
  }

  /// Uploads a profile image file to the backend, returns the relative URL on success.
  /// Throws [ProfileImageUploadException] on validation or HTTP error.
  static Future<String?> uploadProfileImage(
    XFile imageFile, {
    http.Client? client,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw ProfileImageUploadException("User is not authenticated");
      }

      final mediaType = getMediaType(
        imageFile.name.isNotEmpty ? imageFile.name : imageFile.path,
        mimeType: imageFile.mimeType,
      );

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/profile-image');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Read as bytes for cross-platform reliability (mobile, desktop, web)
      try {
        final bytes = await imageFile.readAsBytes();
        if (bytes.isEmpty) {
          throw ProfileImageUploadException("Selected image file is empty");
        }
        if (bytes.length > maxFileSizeBytes) {
          throw ProfileImageUploadException("Image exceeds the maximum allowed size of 5MB");
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name.isNotEmpty ? imageFile.name : 'profile_photo.jpg',
            contentType: mediaType,
          ),
        );
      } catch (readError) {
        if (readError is ProfileImageUploadException) rethrow;
        // Fallback to fromPath if readAsBytes fails
        final length = await imageFile.length();
        if (length == 0) {
          throw ProfileImageUploadException("Selected image file is empty");
        }
        if (length > maxFileSizeBytes) {
          throw ProfileImageUploadException("Image exceeds the maximum allowed size of 5MB");
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: mediaType,
          ),
        );
      }

      final httpClient = client ?? http.Client();
      final shouldClose = client == null;

      try {
        final streamedResponse = await httpClient.send(request).timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final uploadedUrl = data['url'] as String?;
          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
            // Save to local session cache as well
            await StorageService.saveUserProfilePicture(uploadedUrl);
            return uploadedUrl;
          }
          throw ProfileImageUploadException("Server returned an invalid photo reference");
        }

        String errorMessage = "Upload failed with status ${response.statusCode}";
        try {
          final errBody = jsonDecode(response.body);
          if (errBody is Map && errBody['message'] != null) {
            errorMessage = errBody['message'].toString();
          }
        } catch (_) {}

        throw ProfileImageUploadException(errorMessage, response.statusCode);
      } finally {
        if (shouldClose) httpClient.close();
      }
    } catch (e) {
      debugPrint("🔥 Error in ProfileImageService.uploadProfileImage(): $e");
      if (e is ProfileImageUploadException) rethrow;
      throw ProfileImageUploadException("Failed to upload image: ${e.toString()}");
    }
  }
}
