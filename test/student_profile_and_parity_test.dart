import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/models/student_profile_model.dart';
import 'package:alumni_management/models/event_model.dart';
import 'package:alumni_management/screens/navigation/main_navigation.dart';
import 'package:alumni_management/screens/profile/student_profile_screen.dart';
import 'package:alumni_management/screens/profile/alumni_profile_screen.dart';
import 'package:alumni_management/screens/profile/faculty_profile_screen.dart';
import 'package:alumni_management/widgets/event_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Student Profile Model Tests', () {
    test('StudentProfileModel serializes and deserializes correctly', () {
      final json = {
        'userId': 55,
        'userName': 'Jane Doe',
        'email': 'jane@gls.edu',
        'universityNumber': 'GLS2024MCA01',
        'department': 'MCA',
        'degree': 'Master of Computer Applications',
        'batchYear': 2024,
        'semester': 'Semester 4',
        'skills': 'Flutter, Java, Spring Boot',
        'interests': 'Mobile Development, AI',
        'bio': 'Passionate software engineer',
        'contactNumber': '9876543210',
        'currentCity': 'Ahmedabad',
        'linkedInUrl': 'https://linkedin.com/in/janedoe',
        'githubUrl': 'https://github.com/janedoe',
        'profilePictureUrl': '/uploads/student_pic.png',
      };

      final model = StudentProfileModel.fromJson(json);

      expect(model.userId, 55);
      expect(model.userName, 'Jane Doe');
      expect(model.email, 'jane@gls.edu');
      expect(model.universityNumber, 'GLS2024MCA01');
      expect(model.department, 'MCA');
      expect(model.degree, 'Master of Computer Applications');
      expect(model.batchYear, 2024);
      expect(model.semester, 'Semester 4');
      expect(model.skills, 'Flutter, Java, Spring Boot');
      expect(model.currentCity, 'Ahmedabad');

      final serialized = model.toJson();
      expect(serialized['department'], 'MCA');
      expect(serialized['degree'], 'Master of Computer Applications');
      expect(serialized['batchYear'], 2024);
      expect(serialized['skills'], 'Flutter, Java, Spring Boot');
      expect(serialized['profilePictureUrl'], '/uploads/student_pic.png');
    });

    test('StudentProfileModel handles missing or null fields gracefully', () {
      final emptyJson = <String, dynamic>{};
      final model = StudentProfileModel.fromJson(emptyJson);

      expect(model.userId, isNull);
      expect(model.userName, isNull);
      expect(model.batchYear, isNull);
      expect(model.department, isNull);

      final serialized = model.toJson();
      expect(serialized['batchYear'], isNull);
      expect(serialized['skills'], isNull);
    });
  });

  group('MainNavigation Role Parity & Security Tests', () {
    testWidgets('STUDENT role in MainNavigation does NOT render Create button and routes to StudentProfileScreen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'STUDENT',
        'userName': 'Alice Student',
        'user_email': 'alice@gls.edu',
        'auth_token': 'dummy_jwt',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigation(userRole: 'STUDENT'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Create (+) action is NOT present for Student
      expect(find.text("Create"), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);

      // 2. Verify Home, Chat, Profile are present (3 items only)
      expect(find.text("Home"), findsOneWidget);
      expect(find.text("Chat"), findsOneWidget);
      expect(find.text("Profile"), findsOneWidget);

      // 3. Tap Profile tab (index 2 for Student)
      await tester.tap(find.text("Profile"));
      await tester.pumpAndSettle();

      // 4. Verify StudentProfileScreen is displayed, NOT AlumniProfileScreen
      expect(find.byType(StudentProfileScreen), findsOneWidget);
      expect(find.byType(AlumniProfileScreen), findsNothing);
      expect(find.byType(FacultyProfileScreen), findsNothing);
    });

    testWidgets('ALUMNI role in MainNavigation renders Create (+) button and routes to AlumniProfileScreen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ALUMNI',
        'userName': 'Bob Alumni',
        'user_email': 'bob@gls.edu',
        'auth_token': 'dummy_jwt',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigation(userRole: 'ALUMNI'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Create (+) action IS present for Alumni
      expect(find.text("Create"), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // 2. Tap Profile tab (index 3 for Alumni)
      await tester.tap(find.text("Profile"));
      await tester.pumpAndSettle();

      // 3. Verify AlumniProfileScreen is displayed
      expect(find.byType(AlumniProfileScreen), findsOneWidget);
      expect(find.byType(StudentProfileScreen), findsNothing);
    });

    testWidgets('FACULTY role in MainNavigation renders Create (+) button and routes to FacultyProfileScreen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'FACULTY',
        'userName': 'Dr. Charlie Faculty',
        'user_email': 'charlie@gls.edu',
        'auth_token': 'dummy_jwt',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigation(userRole: 'FACULTY'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Create (+) action IS present for Faculty
      expect(find.text("Create"), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // 2. Tap Profile tab (index 3 for Faculty)
      await tester.tap(find.text("Profile"));
      await tester.pumpAndSettle();

      // 3. Verify FacultyProfileScreen is displayed
      expect(find.byType(FacultyProfileScreen), findsOneWidget);
      expect(find.byType(StudentProfileScreen), findsNothing);
    });
  });

  group('EventCard Visual Parity and Branded Fallback Tests', () {
    testWidgets('EventCard displays branded gradient fallback when imageUrl is null', (tester) async {
      final dummyEvent = EventModel(
        id: 1,
        title: 'Annual Alumni Meet 2026',
        eventDate: '2026-12-15T10:00:00',
        location: 'GLS University Auditorium',
        description: 'Join us for the grand gathering of GLS Alumni.',
        targetDepartment: 'MCA',
        imageUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: dummyEvent,
              myEmail: 'student@gls.edu',
            ),
          ),
        ),
      );

      // Verify event details render properly
      expect(find.text('Annual Alumni Meet 2026'), findsOneWidget);
      expect(find.text('GLS University Auditorium'), findsOneWidget);
      expect(find.text('MCA'), findsWidgets);
      expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);
    });
  });
}
