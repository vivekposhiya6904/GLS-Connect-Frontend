import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/config/api_config.dart';
import 'package:alumni_management/services/cache_service.dart';
import 'package:alumni_management/services/event_service.dart';
import 'package:alumni_management/services/job_service.dart';
import 'package:alumni_management/services/student_profile_service.dart';
import 'package:alumni_management/services/alumni_profile_service.dart';
import 'package:alumni_management/services/faculty_profile_service.dart';
import 'package:alumni_management/widgets/offline_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testEmail = 'alumni.test@gls.edu';

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_email': testEmail,
      'auth_token': 'test_jwt_token',
      'user_role': 'ALUMNI',
    });
    CacheService.setDeviceKeyForTest(List<int>.generate(32, (i) => (i * 7 + 11) % 256));
    await CacheService.clearAll();
  });

  tearDown(() async {
    CacheService.clearKeyCacheForTest();
  });

  group('EventService Offline Caching & Fallback', () {
    test('getAllEvents caches successful 200 response and returns parsed models', () async {
      final mockEventsJson = [
        {
          'id': 1,
          'title': 'Annual Gala 2026',
          'description': 'Networking and dinner',
          'location': 'Auditorium A',
          'eventDate': '2026-11-15T18:00:00',
        },
      ];

      final client = MockClient((request) async {
        expect(request.url.toString(), equals("${ApiConfig.baseUrl}/api/events"));
        return http.Response(jsonEncode(mockEventsJson), 200, headers: {'content-type': 'application/json'});
      });

      final events = await EventService.getAllEvents(client: client);
      expect(events, isNotNull);
      expect(events!.length, equals(1));
      expect(events[0].title, equals('Annual Gala 2026'));

      // Check that cache was populated
      final cachedResult = await EventService.getCachedAllEvents(email: testEmail);
      expect(cachedResult, isNotNull);
      expect(cachedResult!.data.length, equals(1));
      expect(cachedResult.data[0].title, equals('Annual Gala 2026'));
      expect(cachedResult.timeAgoFormatted, equals('just now'));
    });

    test('getAllEvents falls back to cached data when network fails (offline)', () async {
      // 1. Pre-seed cache
      final seedEvents = [
        {
          'id': 42,
          'title': 'Cached Career Fair',
          'description': 'Meet employers offline',
          'location': 'Hall B',
          'eventDate': '2026-12-01T10:00:00',
        },
      ];
      await EventService.saveEventsToCache(seedEvents, email: testEmail);

      // 2. Client throws a ClientException (simulating offline/no internet)
      final client = MockClient((request) async {
        throw http.ClientException('Failed host lookup: network unreachable');
      });

      final result = await EventService.getAllEvents(client: client);
      // Result must NOT be null or throw; it must return the cached events!
      expect(result, isNotNull);
      expect(result!.length, equals(1));
      expect(result[0].title, equals('Cached Career Fair'));
    });

    test('getAllEvents distinguishes empty response from network failure', () async {
      // Pre-seed cache
      await EventService.saveEventsToCache([
        {
          'id': 1,
          'title': 'Old Event',
          'description': 'desc',
          'location': 'loc',
          'eventDate': '2026-01-01',
        },
      ], email: testEmail);

      // Successful empty response (server has no events)
      final client = MockClient((request) async {
        return http.Response('[]', 200, headers: {'content-type': 'application/json'});
      });

      final result = await EventService.getAllEvents(client: client);
      expect(result, isNotNull);
      expect(result, isEmpty);

      // Cache now reflects empty list
      final cached = await EventService.getCachedAllEvents(email: testEmail);
      expect(cached, isNotNull);
      expect(cached!.data, isEmpty);
    });
  });

  group('JobService Offline Caching & Fallback', () {
    test('getAllJobs caches successful 200 response and returns parsed models', () async {
      final mockJobsJson = [
        {
          'id': 101,
          'userId': 5,
          'userName': 'Recruiter',
          'userEmail': 'recruiter@deepmind.com',
          'companyName': 'Google DeepMind',
          'jobTitle': 'Senior Flutter Architect',
          'location': 'Bengaluru',
          'salary': '3000000',
          'jobDescription': 'Build offline-first apps',
          'skillsRequired': 'Flutter, Dart, TDD',
          'experienceRequired': '5+ years',
          'joiningType': 'Immediate',
          'jobType': 'Full Time',
          'lastDateToApply': '2026-12-31',
        },
      ];

      final client = MockClient((request) async {
        expect(request.url.toString(), equals("${ApiConfig.baseUrl}/api/jobs"));
        return http.Response(jsonEncode(mockJobsJson), 200, headers: {'content-type': 'application/json'});
      });

      final jobs = await JobService.getAllJobs(client: client);
      expect(jobs, isNotNull);
      expect(jobs!.length, equals(1));
      expect(jobs[0].jobTitle, equals('Senior Flutter Architect'));

      // Check cache
      final cached = await JobService.getCachedAllJobs(email: testEmail);
      expect(cached, isNotNull);
      expect(cached!.data.length, equals(1));
      expect(cached.data[0].jobTitle, equals('Senior Flutter Architect'));
    });

    test('getAllJobs falls back to cached jobs when server returns 500 or network fails', () async {
      final seedJobs = [
        {
          'id': 999,
          'userId': 8,
          'userName': 'HR',
          'userEmail': 'hr@acme.com',
          'companyName': 'Acme Mobile',
          'jobTitle': 'Offline Mobile Engineer',
          'location': 'Remote',
          'salary': '1800000',
          'jobDescription': 'Cached description',
          'skillsRequired': 'Mobile, SQLite, Caching',
          'experienceRequired': '3 years',
          'joiningType': 'Full Time',
          'jobType': 'Permanent',
          'lastDateToApply': '2026-11-30',
        },
      ];
      await JobService.saveJobsToCache(seedJobs, email: testEmail);

      final client = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final result = await JobService.getAllJobs(client: client);
      expect(result, isNotNull);
      expect(result!.length, equals(1));
      expect(result[0].jobTitle, equals('Offline Mobile Engineer'));
    });

    test('getMyJobs caches and falls back offline', () async {
      final mySeedJobs = [
        {
          'id': 505,
          'userId': 2,
          'userName': 'Alumni Tester',
          'userEmail': testEmail,
          'companyName': 'Test Corp',
          'jobTitle': 'Lead QA',
          'location': 'Ahmedabad',
          'salary': '1200000',
          'jobDescription': 'My posted job',
          'skillsRequired': 'Integration Testing',
          'experienceRequired': '4 years',
          'joiningType': 'Full Time',
          'jobType': 'Hybrid',
          'lastDateToApply': '2026-12-31',
        },
      ];
      await JobService.saveMyJobsToCache(mySeedJobs, email: testEmail);

      final client = MockClient((request) async {
        throw http.ClientException('Connection reset by peer');
      });

      final result = await JobService.getMyJobs(client: client);
      expect(result, isNotNull);
      expect(result!.length, equals(1));
      expect(result[0].id, equals(505));
    });
  });

  group('Profile Services Encrypted Offline Caching', () {
    test('StudentProfileService encrypts profile to cache and falls back offline', () async {
      final mockStudent = {
        'userName': 'Alice Student',
        'email': testEmail,
        'department': 'MCA',
        'degree': 'Master of Computer Applications',
        'batchYear': 2026,
        'semester': 'Semester 4',
        'skills': 'Flutter, Java',
        'contactNumber': '+91 9998887776',
        'currentCity': 'Ahmedabad',
      };

      final client200 = MockClient((request) async {
        return http.Response(jsonEncode(mockStudent), 200, headers: {'content-type': 'application/json'});
      });

      final profile = await StudentProfileService.getProfile(client: client200);
      expect(profile, isNotNull);
      expect(profile!.userName, equals('Alice Student'));

      // Check encrypted cached profile
      final cachedProfile = await StudentProfileService.getCachedProfile(email: testEmail);
      expect(cachedProfile, isNotNull);
      expect(cachedProfile!.data.userName, equals('Alice Student'));
      expect(cachedProfile.data.contactNumber, equals('+91 9998887776'));

      // Now verify offline fallback when server throws
      final clientOffline = MockClient((request) async {
        throw http.ClientException('No route to host');
      });

      final offlineResult = await StudentProfileService.getProfile(client: clientOffline);
      expect(offlineResult, isNotNull);
      expect(offlineResult!.userName, equals('Alice Student'));
    });

    test('AlumniProfileService encrypts profile to cache and falls back offline', () async {
      final mockAlumni = {
        'degree': 'MCA',
        'department': 'Computer Science',
        'batchYear': 2022,
        'designation': 'Staff Engineer',
        'companyName': 'Tech Corp',
        'skills': 'Distributed Systems',
        'contactNumber': '+91 9123456789',
        'currentCity': 'Pune',
      };

      final client200 = MockClient((request) async {
        return http.Response(jsonEncode(mockAlumni), 200, headers: {'content-type': 'application/json'});
      });

      final profile = await AlumniProfileService.getProfile(client: client200);
      expect(profile, isNotNull);
      expect(profile!.companyName, equals('Tech Corp'));

      // Offline fallback
      final clientOffline = MockClient((request) async {
        return http.Response('Internal Error', 503);
      });

      final offlineProfile = await AlumniProfileService.getProfile(client: clientOffline);
      expect(offlineProfile, isNotNull);
      expect(offlineProfile!.designation, equals('Staff Engineer'));
      expect(offlineProfile.companyName, equals('Tech Corp'));
    });

    test('FacultyProfileService encrypts profile to cache and falls back offline', () async {
      final mockFaculty = {
        'department': 'Information Technology',
        'designation': 'Head of Department',
        'qualification': 'Ph.D in AI',
        'experienceYears': 15,
        'contactNumber': '+91 9000011111',
      };

      final client200 = MockClient((request) async {
        return http.Response(jsonEncode(mockFaculty), 200, headers: {'content-type': 'application/json'});
      });

      final profile = await FacultyProfileService.getProfile(client: client200);
      expect(profile, isNotNull);
      expect(profile!.designation, equals('Head of Department'));

      // Offline fallback
      final clientOffline = MockClient((request) async {
        throw http.ClientException('Socket closed');
      });

      final offlineProfile = await FacultyProfileService.getProfile(client: clientOffline);
      expect(offlineProfile, isNotNull);
      expect(offlineProfile!.qualification, equals('Ph.D in AI'));
    });
  });

  group('OfflineIndicatorBanner Widget Test', () {
    testWidgets('Renders offline message with timestamp and triggers retry', (tester) async {
      bool retryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorBanner(
              timeAgo: '15m ago',
              onRetry: () {
                retryClicked = true;
              },
            ),
          ),
        ),
      );

      // Verify cloud_off icon and text
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Offline mode • Showing cached data (saved 15m ago)'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryClicked, isTrue);
    });

    testWidgets('Renders simple banner when no retry callback is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorBanner(timeAgo: null),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Offline mode • Showing cached data'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
