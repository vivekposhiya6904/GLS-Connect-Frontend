import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alumni_management/config/api_config.dart';
import 'package:alumni_management/services/profile_image_service.dart';
import 'package:alumni_management/utils/storage_service.dart';
import 'package:alumni_management/widgets/profile_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiConfig.resolveUrl Tests', () {
    test('Returns null for null or empty string', () {
      expect(ApiConfig.resolveUrl(null), isNull);
      expect(ApiConfig.resolveUrl(''), isNull);
      expect(ApiConfig.resolveUrl('   '), isNull);
    });

    test('Preserves absolute URLs', () {
      const url = 'https://example.com/avatar.jpg';
      expect(ApiConfig.resolveUrl(url), equals(url));
    });

    test('Prepends baseUrl to relative paths with leading slash', () {
      const path = '/uploads/profiles/user_1_photo.jpg';
      final resolved = ApiConfig.resolveUrl(path);
      expect(resolved, equals('${ApiConfig.baseUrl}$path'));
    });

    test('Prepends baseUrl to relative paths without leading slash', () {
      const path = 'uploads/profiles/user_1_photo.jpg';
      final resolved = ApiConfig.resolveUrl(path);
      expect(resolved, equals('${ApiConfig.baseUrl}/$path'));
    });

    test('Normalizes Windows backslashes into forward slashes', () {
      const path = r'uploads\profiles\user_1_photo.jpg';
      final resolved = ApiConfig.resolveUrl(path);
      expect(resolved, equals('${ApiConfig.baseUrl}/uploads/profiles/user_1_photo.jpg'));
    });

    test('Appends cache-busting query parameter when requested', () {
      const path = '/uploads/profiles/user_1_photo.jpg';
      final resolved = ApiConfig.resolveUrl(path, cacheBust: true);
      expect(resolved, isNotNull);
      expect(resolved, contains('?t='));
    });

    test('Appends cache-busting with ampersand if URL already has query parameters', () {
      const url = 'https://example.com/avatar.jpg?version=1';
      final resolved = ApiConfig.resolveUrl(url, cacheBust: true);
      expect(resolved, contains('&t='));
    });
  });

  group('ProfileImageService MediaType and Validation Tests', () {
    test('Resolves correct MediaTypes for standard image extensions', () {
      expect(ProfileImageService.getMediaType('photo.jpg').mimeType, equals('image/jpeg'));
      expect(ProfileImageService.getMediaType('photo.jpeg').mimeType, equals('image/jpeg'));
      expect(ProfileImageService.getMediaType('photo.png').mimeType, equals('image/png'));
      expect(ProfileImageService.getMediaType('photo.webp').mimeType, equals('image/webp'));
      expect(ProfileImageService.getMediaType('photo.gif').mimeType, equals('image/gif'));
    });

    test('Uses explicit mimeType if provided and valid', () {
      final mediaType = ProfileImageService.getMediaType('temp_file', mimeType: 'image/png');
      expect(mediaType.mimeType, equals('image/png'));
    });

    test('Throws ArgumentError for unsupported file types', () {
      expect(() => ProfileImageService.getMediaType('document.pdf'), throwsArgumentError);
      expect(() => ProfileImageService.getMediaType('script.sh'), throwsArgumentError);
      expect(() => ProfileImageService.getMediaType('app.exe'), throwsArgumentError);
    });
  });

  group('StorageService Profile Picture Persistence Tests', () {
    test('Saves, retrieves, and clears user profile picture', () async {
      expect(await StorageService.getUserProfilePicture(), isNull);

      const testUrl = '/uploads/profiles/user_42_pic.jpg';
      await StorageService.saveUserProfilePicture(testUrl);
      expect(await StorageService.getUserProfilePicture(), equals(testUrl));

      await StorageService.clearUserProfilePicture();
      expect(await StorageService.getUserProfilePicture(), isNull);
    });
  });

  group('ProfileImageService Upload Tests', () {
    test('Throws ProfileImageUploadException when unauthenticated', () async {
      // SharedPreferences is empty -> token is null
      final file = XFile.fromData(
        utf8.encode('dummy image data'),
        name: 'test.jpg',
      );

      expect(
        () => ProfileImageService.uploadProfileImage(file),
        throwsA(isA<ProfileImageUploadException>()),
      );
    });

    test('Uploads successfully and updates StorageService with mock client', () async {
      await StorageService.saveToken('mock_jwt_token');

      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/api/users/profile-image'));
        expect(request.headers['authorization'] ?? request.headers['Authorization'], equals('Bearer mock_jwt_token'));
        expect(request.headers['content-type'], contains('multipart/form-data'));
        expect(utf8.decode(request.bodyBytes), contains('mock jpeg image bytes'));

        return http.Response(
          jsonEncode({'url': '/uploads/profiles/student_101.jpg'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final file = XFile.fromData(
        utf8.encode('mock jpeg image bytes'),
        name: 'student_avatar.jpg',
      );

      final resultUrl = await ProfileImageService.uploadProfileImage(file, client: mockClient);
      expect(resultUrl, equals('/uploads/profiles/student_101.jpg'));
      expect(await StorageService.getUserProfilePicture(), equals('/uploads/profiles/student_101.jpg'));
    });
  });

  group('ProfileAvatar Widget Tests', () {
    test('Generates correct initials', () {
      expect(ProfileAvatar.getInitials('John Doe'), equals('JD'));
      expect(ProfileAvatar.getInitials('Alice'), equals('AL'));
      expect(ProfileAvatar.getInitials('   Bob  Smith  '), equals('BS'));
      expect(ProfileAvatar.getInitials(''), equals(''));
      expect(ProfileAvatar.getInitials(null), equals(''));
    });

    test('Generates deterministic color for names', () {
      final color1 = ProfileAvatar.getDeterministicColor('John Doe');
      final color2 = ProfileAvatar.getDeterministicColor('John Doe');
      expect(color1, equals(color2));
    });

    testWidgets('Renders initials when no image URL is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(
              name: 'John Doe',
              radius: 30,
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('Renders fallback icon when name is empty and no image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(
              name: '',
              radius: 30,
              fallbackIcon: Icons.person,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Supports custom rectangular borderRadius layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(
              name: 'Jane Doe',
              isCircle: false,
              borderRadius: BorderRadius.circular(12),
              width: 80,
              height: 80,
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });
}
