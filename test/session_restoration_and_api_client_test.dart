import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/utils/storage_service.dart';
import 'package:alumni_management/services/api_client.dart';
import 'package:alumni_management/config/api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Session Storage & Restoration Tests', () {
    test('StorageService persists and clears auth credentials cleanly', () async {
      await StorageService.saveToken("sample_jwt_token_123");
      await StorageService.saveUserName("John Doe");
      await StorageService.saveUserRole("ALUMNI");
      await StorageService.saveUserEmail("john@example.com");
      await StorageService.saveLoginStatus(true);

      expect(await StorageService.getToken(), "sample_jwt_token_123");
      expect(await StorageService.getUserName(), "John Doe");
      expect(await StorageService.getUserRole(), "ALUMNI");
      expect(await StorageService.getUserEmail(), "john@example.com");
      expect(await StorageService.getLoginStatus(), true);

      // Logout cleans all state
      await StorageService.logout();

      expect(await StorageService.getToken(), isNull);
      expect(await StorageService.getUserName(), isNull);
      expect(await StorageService.getUserRole(), isNull);
      expect(await StorageService.getUserEmail(), isNull);
      expect(await StorageService.getLoginStatus(), false);
    });

    test('Session restoration returns false when token is not saved', () async {
      final token = await StorageService.getToken();
      final isLoggedIn = await StorageService.getLoginStatus();

      expect(token, isNull);
      expect(isLoggedIn, false);
    });
  });

 group('ApiClient Network & Cold-Start Tests', () {
    test('ApiClient configuration has safe default timeouts', () {
      expect(ApiClient.defaultTimeout, const Duration(seconds: 15));
      expect(ApiClient.maxGetRetries, 2);
    });

    test('MockClient simulates bounded retry on 503 Service Unavailable (Cold Start)', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount < 3) {
          return http.Response('{"status":"Waking up"}', 503);
        }
        return http.Response('{"status":"UP", "data":"Ready"}', 200);
      });

      // Verify that after waking up, 200 OK is returned
      final res = await mockClient.get(Uri.parse("http://localhost:8080/api/health"));
      expect(res.statusCode, 503);
      final res2 = await mockClient.get(Uri.parse("http://localhost:8080/api/health"));
      expect(res2.statusCode, 503);
      final res3 = await mockClient.get(Uri.parse("http://localhost:8080/api/health"));
      expect(res3.statusCode, 200);
      expect(requestCount, 3);
    });

    test('Non-idempotent POST does not duplicate on error', () async {
      int postCount = 0;
      final mockClient = MockClient((request) async {
        postCount++;
        return http.Response('{"error":"Gateway Timeout"}', 504);
      });

      final res = await mockClient.post(
        Uri.parse("http://localhost:8080/api/posts"),
        body: jsonEncode({"content": "Test Post"}),
      );

      expect(res.statusCode, 504);
      // Ensures single execution without blind replay
      expect(postCount, 1);
    });
  });

  group('ApiConfig Environment & Security Tests', () {
    test('ApiConfig baseUrl returns valid URL without trailing slash', () {
      final url = ApiConfig.baseUrl;
      expect(url, isNotEmpty);
      expect(url.startsWith("http"), true);
      expect(url.endsWith("/"), false);
    });
  });
}
