import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Helper to prompt users with Gallery & Camera options and safely capture images
class ImagePickerHelper {
  ImagePickerHelper._();

  static final ImagePicker _picker = ImagePicker();

  /// Shows a modal bottom sheet letting the user choose between Camera and Gallery
  static Future<XFile?> pickImageWithSourceDialog(
    BuildContext context, {
    String title = "Select Profile Photo",
    int imageQuality = 85,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ImageSource? selectedSource = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A8F).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1A3A8F)),
                  ),
                  title: Text(
                    "Take a photo",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: const Text("Use device camera to take a new picture"),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A8F).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF1A3A8F)),
                  ),
                  title: Text(
                    "Upload from gallery",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: const Text("Select existing photo from device storage"),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedSource == null) {
      return null; // User dismissed sheet
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: selectedSource,
        imageQuality: imageQuality,
      );
      return picked;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not access ${selectedSource == ImageSource.camera ? 'camera' : 'gallery'}: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return null;
    }
  }
}
