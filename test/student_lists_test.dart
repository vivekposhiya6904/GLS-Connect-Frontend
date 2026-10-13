import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/screens/dashboard/student_home_screen.dart';


// 1x1 transparent GIF
final List<int> _kTransparentImage = <int>[
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
  0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x21, 0xf9, 0x04, 0x01, 0x00,
  0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
  0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3b,
];

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

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
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _MockImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HttpOverrides.global = _MockImageHttpOverrides();
    SharedPreferences.setMockInitialValues({
      'userRole': 'STUDENT',
      'auth_token': 'mock_token',
      'user_email': 'student@test.com',
    });
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('Student Module Alumni & Faculty List Verification Tests', () {
    testWidgets('StudentHomeScreen renders Alumni and Faculty tabs correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentHomeScreen(),
        ),
      );

      // Verify the 5 tabs exist in StudentHomeScreen
      expect(find.text("Events"), findsOneWidget);
      expect(find.text("Jobs"), findsOneWidget);
      expect(find.text("My Activity"), findsOneWidget);
      expect(find.text("Alumni"), findsOneWidget);
      expect(find.text("Faculty"), findsOneWidget);

      // Verify global search button is removed from Student AppBar
      expect(find.byIcon(Icons.search_rounded), findsNothing);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('AlumniPage renders ProfileList with ALUMNI role', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AlumniPage()),
        ),
      );

      expect(find.byType(ProfileList), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text("Search alumni by name, department, role..."), findsOneWidget);
    });

    testWidgets('FacultyPage renders ProfileList with FACULTY role', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FacultyPage()),
        ),
      );

      expect(find.byType(ProfileList), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text("Search faculty by name, department, role..."), findsOneWidget);
    });

    testWidgets('ProfileCard renders real profile data safely with avatar, subtitle, and department', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ProfileCard(
                  name: "Ramesh Sharma",
                  role: "Senior Software Engineer at Tata Consultancy Services",
                  department: "Computer Applications",
                  userId: 50,
                  userRole: "ALUMNI",
                  profilePictureUrl: "https://example.com/avatar.jpg",
                ),
                ProfileCard(
                  name: "Prof. Mahendra Patel",
                  role: "Professor & Head of Department • Computer Applications",
                  department: "Data Science",
                  userId: 80,
                  userRole: "FACULTY",
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text("Ramesh Sharma"), findsOneWidget);
      expect(find.text("Senior Software Engineer at Tata Consultancy Services"), findsOneWidget);
      expect(find.text("Prof. Mahendra Patel"), findsOneWidget);
      expect(find.text("Professor & Head of Department • Computer Applications"), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    });

    testWidgets('ProfileCard handles null and optional fields without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              name: "Alumni Member",
              role: "",
              userId: 0,
              userRole: "ALUMNI",
              profilePictureUrl: null,
              department: null,
            ),
          ),
        ),
      );

      expect(find.text("Alumni Member"), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });
  });
}
