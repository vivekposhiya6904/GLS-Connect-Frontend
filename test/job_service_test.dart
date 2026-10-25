import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/services/job_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test_jwt_token',
      'user_email': 'test@example.com',
    });
  });

  group('JobService.getMyJobs Tests', () {
    test('Successful 200 response with jobs returns parsed and sorted job list', () async {
      final sampleJobs = [
        {
          "id": 1,
          "companyName": "Alpha Corp",
          "jobTitle": "Junior Dev",
          "location": "Ahmedabad",
          "salary": "6 LPA",
          "userEmail": "test@example.com",
        },
        {
          "id": 2,
          "companyName": "Beta Corp",
          "jobTitle": "Senior Dev",
          "location": "Ahmedabad",
          "salary": "12 LPA",
          "userEmail": "test@example.com",
        },
      ];

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/api/jobs/my')) {
          expect(request.headers['Authorization'], equals('Bearer test_jwt_token'));
          return http.Response(jsonEncode(sampleJobs), 200);
        }
        return http.Response('Not Found', 404);
      });

      final result = await JobService.getMyJobs(client: client);
      expect(result, isNotNull);
      expect(result!.length, equals(2));
      expect(result[0].id, equals(2)); // sorted desc by id
      expect(result[1].id, equals(1));
      expect(result[0].companyName, equals("Beta Corp"));
    });

    test('Successful 200 response with empty list returns valid empty result', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/api/jobs/my')) {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response('Not Found', 404);
      });

      final result = await JobService.getMyJobs(client: client);
      expect(result, isNotNull);
      expect(result!.isEmpty, isTrue);
    });

    test('401 Authentication failure returns null and does NOT invoke fallback', () async {
      int getAllJobsCalls = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/api/jobs/my')) {
          return http.Response('Unauthorized', 401);
        }
        if (request.url.path.endsWith('/api/jobs')) {
          getAllJobsCalls++;
          return http.Response('[]', 200);
        }
        return http.Response('Not Found', 404);
      });

      final result = await JobService.getMyJobs(client: client);
      expect(result, isNull);
      expect(getAllJobsCalls, equals(0)); // fallback must not be called
    });

    test('403 Forbidden failure returns null and does NOT invoke fallback', () async {
      int getAllJobsCalls = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/api/jobs/my')) {
          return http.Response('Forbidden', 403);
        }
        if (request.url.path.endsWith('/api/jobs')) {
          getAllJobsCalls++;
          return http.Response('[]', 200);
        }
        return http.Response('Not Found', 404);
      });

      final result = await JobService.getMyJobs(client: client);
      expect(result, isNull);
      expect(getAllJobsCalls, equals(0)); // fallback must not be called
    });

    test('500 Server error returns null and does NOT invoke fallback', () async {
      int getAllJobsCalls = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/api/jobs/my')) {
          return http.Response('Internal Server Error', 500);
        }
        if (request.url.path.endsWith('/api/jobs')) {
          getAllJobsCalls++;
          return http.Response('[]', 200);
        }
        return http.Response('Not Found', 404);
      });

      final result = await JobService.getMyJobs(client: client);
      expect(result, isNull);
      expect(getAllJobsCalls, equals(0)); // fallback must not be called
    });

    test('404 Endpoint not found falls back to getAllJobs scoped to user email', () async {
      final allJobs = [
        {
          "id": 10,
          "companyName": "Other Company",
          "jobTitle": "Dev",
          "userEmail": "other@example.com",
        },
        {
          "id": 11,
          "companyName": "My Company",
          "jobTitle": "Lead",
          "userEmail": "test@example.com",
        },
      ];

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/api/jobs/my')) {
          return http.Response('Not Found', 404);
        }
        if (request.url.path.endsWith('/api/jobs')) {
          return http.Response(jsonEncode(allJobs), 200);
        }
        return http.Response('Not Found', 404);
      });

      final result = await JobService.getMyJobs(client: client);
      expect(result, isNotNull);
      expect(result!.length, equals(1));
      expect(result[0].companyName, equals("My Company"));
      expect(result[0].userEmail, equals("test@example.com"));
    });
  });
}
