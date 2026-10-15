import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/screens/dashboard/alumni_home_screen.dart' as alumni;
import 'package:alumni_management/screens/dashboard/student_home_screen.dart' as student;
import 'package:alumni_management/screens/navigation/main_navigation.dart';
import 'package:alumni_management/widgets/job_card.dart';
import 'package:alumni_management/widgets/event_card.dart';
import 'package:alumni_management/models/job_model.dart';
import 'package:alumni_management/models/event_model.dart';

// Sample mock event JSON
final _mockEventsJson = jsonEncode([
  {
    'id': 1,
    'title': 'Alumni Annual Meet 2026',
    'description': 'Annual gathering of alumni and graduating students.',
    'location': 'GLS University Campus, Ahmedabad',
    'eventDate': '2026-12-31',
    'targetDepartment': 'Computer Science',
    'createdBy': {'name': 'Admin', 'email': 'admin@gls.edu'}
  }
]);

// Sample mock job JSON
final _mockJobsJson = jsonEncode([
  {
    'id': 101,
    'userId': 10,
    'userName': 'Recruiter',
    'userEmail': 'recruiter@tech.com',
    'companyName': 'Google India',
    'jobTitle': 'Senior Flutter Engineer',
    'location': 'Bengaluru, Karnataka',
    'salary': '15 LPA',
    'jobDescription': 'Build cross-platform applications.',
    'skillsRequired': 'Flutter, Dart, Android',
    'experienceRequired': '3+ years',
    'joiningType': 'Full-time',
    'jobType': 'In-office',
    'lastDateToApply': '2026-12-31'
  }
]);

// Mock HTTP client to deliver responses without network
class _MockHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, List<String>> _data = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _data[name.toLowerCase()] = [value.toString()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _data.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void remove(String name, Object value) {
    _data.remove(name.toLowerCase());
  }

  @override
  void removeAll(String name) {
    _data.remove(name.toLowerCase());
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _data.forEach(action);
  }

  @override
  List<String>? operator [](String name) => _data[name.toLowerCase()];

  @override
  String? value(String name) {
    final list = _data[name.toLowerCase()];
    return (list != null && list.isNotEmpty) ? list.last : null;
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  final Uri url;
  final _headers = _MockHttpHeaders();

  _MockHttpClientRequest(this.url);

  @override
  HttpHeaders get headers => _headers;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = 0;

  @override
  bool persistentConnection = true;

  @override
  void add(List<int> data) {}

  @override
  Future addStream(Stream<List<int>> stream) async {
    await stream.drain();
  }

  @override
  Future<HttpClientResponse> close() async {
    final path = url.path;
    String responseBody = '[]';
    if (path.contains('/api/events')) {
      responseBody = _mockEventsJson;
    } else if (path.contains('/api/jobs')) {
      responseBody = _mockJobsJson;
    } else if (path.contains('/api/user')) {
      responseBody = '[]';
    } else if (path.contains('/api/chat/unread')) {
      responseBody = '{}';
    }
    return _MockHttpClientResponse(responseBody);
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest(url);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest(url);
  }

  @override
  void close({bool force = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  final String responseBody;
  final _headers = _MockHttpHeaders();
  _MockHttpClientResponse(this.responseBody);

  @override
  HttpHeaders get headers => _headers;

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  int get contentLength => utf8.encode(responseBody).length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([utf8.encode(responseBody)]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _MockTestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HttpOverrides.global = _MockTestHttpOverrides();
    SharedPreferences.setMockInitialValues({
      'userRole': 'STUDENT',
      'auth_token': 'test_mock_jwt_token',
      'user_email': 'student@gls.edu',
    });
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('Phase Two & Three: Jobs and Events Overflow Repair Verification', () {
    testWidgets('EventList handles search with no results and keyboard open without overflow', (tester) async {
      // Small phone screen with keyboard open (height: 580, bottom inset: 290)
      tester.view.physicalSize = const Size(360, 580);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 580),
            viewInsets: EdgeInsets.only(bottom: 290),
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: alumni.EventList(),
            ),
          ),
        ),
      );

      // Let future complete
      await tester.pumpAndSettle();

      // Verify event is loaded
      expect(find.text("Alumni Annual Meet 2026"), findsOneWidget);

      // Enter search query that yields no results
      await tester.enterText(find.byType(TextField), "NonExistentEventQueryXYZ");
      await tester.pumpAndSettle();

      // Verify empty search state renders
      expect(find.text("No events match your search or filters"), findsOneWidget);
      expect(find.text("Reset Search & Filters"), findsOneWidget);

      // Verify NO overflow exception occurred (tester.takeException() is null)
      expect(tester.takeException(), isNull);

      // Scroll to ensure visible in the keyboard-adapted viewport and tap
      await tester.ensureVisible(find.text("Reset Search & Filters"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Reset Search & Filters"));
      await tester.pumpAndSettle();

      // Verify search query cleared and events restored
      expect(find.text("Alumni Annual Meet 2026"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Student JobList handles search with no results and keyboard open without overflow', (tester) async {
      // Simulate narrow and short device with active keyboard
      tester.view.physicalSize = const Size(360, 580);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 580),
            viewInsets: EdgeInsets.only(bottom: 290),
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: student.JobList(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify job loaded
      expect(find.text("Senior Flutter Engineer"), findsOneWidget);

      // Search for non-existent job
      await tester.enterText(find.byType(TextField), "UnmatchedJobQueryXYZ");
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text("No jobs match your search or filters"), findsOneWidget);
      expect(find.text("Reset Search & Filters"), findsOneWidget);

      // Crucial: verify zero layout overflows occurred
      expect(tester.takeException(), isNull);

      // Tap Reset Search & Filters button
      await tester.tap(find.text("Reset Search & Filters"));
      await tester.pumpAndSettle();

      // Verify jobs restored
      expect(find.text("Senior Flutter Engineer"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Alumni JobList handles search with no results and keyboard open without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 580);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 580),
            viewInsets: EdgeInsets.only(bottom: 290),
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: alumni.JobList(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Senior Flutter Engineer"), findsOneWidget);

      await tester.enterText(find.byType(TextField), "UnmatchedJobQueryXYZ");
      await tester.pumpAndSettle();

      expect(find.text("No jobs match your search or filters"), findsOneWidget);
      expect(find.text("Reset Search & Filters"), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text("Reset Search & Filters"));
      await tester.pumpAndSettle();

      expect(find.text("Senior Flutter Engineer"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase Five: Responsive Card Layout & Narrow Viewport (320px) Tests', () {
    testWidgets('JobCard renders without horizontal overflow on 320px width with 1.4x text scaling', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final job = JobModel(
        id: 99,
        userId: 1,
        userName: "Tata Consultancy Services Talent Acquisition Team",
        userEmail: "recruiter@tcs.com",
        companyName: "Tata Consultancy Services Limited India",
        jobTitle: "Lead Distributed Cloud Architecture & Mobile Infrastructure Specialist",
        location: "Ahmedabad, Gujarat / Bengaluru / Remote",
        salary: "24-30 LPA",
        jobDescription: "Very extensive job description detailing full architectural responsibilities.",
        skillsRequired: "Flutter, Dart, Spring Boot, Microservices, Kubernetes, GCP, System Design",
        experienceRequired: "5+ years",
        joiningType: "Full-time",
        jobType: "In-office",
        lastDateToApply: "2026-12-31",
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.4),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  JobCard(job: job, myEmail: "student@gls.edu"),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("Tata Consultancy Services Limited India"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EventCard renders without overflow on 320px width with 1.4x text scaling', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final event = EventModel(
        id: 77,
        title: "International Conference on Artificial Intelligence and Next-Gen Computing",
        description: "Join industry leaders and academic researchers for groundbreaking discussions.",
        location: "Main Auditorium, GLS University Campus, Ellisbridge, Ahmedabad",
        eventDate: "2026-11-25",
        targetDepartment: "Computer Applications",
        createdByName: "Faculty Convener",
        createdByEmail: "convener@gls.edu",
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.4),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  EventCard(event: event, myEmail: "student@gls.edu"),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("International Conference on Artificial Intelligence and Next-Gen Computing"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MainNavigation renders without overflow on 320px narrow screens', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 600),
          ),
          child: MaterialApp(
            home: MainNavigation(userRole: 'ALUMNI'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("Home"), findsOneWidget);
      expect(find.text("Create"), findsOneWidget);
      expect(find.text("Chat"), findsOneWidget);
      expect(find.text("Profile"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase Three: Directory and Activity Empty State Adaptability', () {
    testWidgets('Alumni ProfileList handles empty search under constrained viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(360, 500),
            viewInsets: EdgeInsets.only(bottom: 250),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: alumni.ProfileList(role: 'ALUMNI'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
