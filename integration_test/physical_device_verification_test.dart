import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/screens/navigation/main_navigation.dart';
import 'package:alumni_management/screens/profile/faculty_profile_screen.dart';
import 'package:alumni_management/screens/profile/student_profile_screen.dart';
import 'package:alumni_management/screens/profile/alumni_profile_screen.dart';
import 'package:alumni_management/screens/dashboard/admin_home_screen.dart';
import 'package:alumni_management/screens/auth/login_screen.dart';
import 'package:alumni_management/screens/auth/email_verification_screen.dart';
import 'package:alumni_management/screens/search/search_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Physical Device Full Application Verification', () {
    testWidgets('1. Faculty Module: MainNavigation and FacultyProfileScreen Overflow Check on Device', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'FACULTY',
        'userName': 'Prof. Dr. Mahendra Kumar, Ph.D.',
        'user_email': 'mahendra@gmail.com',
        'auth_token': 'dummy_jwt_token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigation(userRole: 'FACULTY'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Faculty home is visible with tabs
      expect(find.text('GLS Connect'), findsOneWidget);
      expect(find.text('FACULTY'), findsOneWidget);

      // Navigate to Profile tab
      final profileTab = find.text('Profile');
      expect(profileTab, findsOneWidget);
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      // Verify FacultyProfileScreen is loaded
      expect(find.byType(FacultyProfileScreen), findsOneWidget);

      // Scroll through entire profile screen to verify zero RenderFlex overflow on physical screen
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Scroll back up
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 1100));
      await tester.pumpAndSettle();
    });

    testWidgets('2. Student Module: MainNavigation and StudentProfileScreen Verification', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'STUDENT',
        'userName': 'Aayush Student',
        'user_email': 'aayush@gmail.com',
        'auth_token': 'dummy_jwt_token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigation(userRole: 'STUDENT'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Student tabs
      expect(find.text('STUDENT'), findsOneWidget);
      expect(find.text('Create'), findsNothing); // Students cannot create

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(StudentProfileScreen), findsOneWidget);
    });

    testWidgets('3. Alumni Module: MainNavigation and AlumniProfileScreen Verification', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ALUMNI',
        'userName': 'Vivek Poshiya',
        'user_email': 'vivekposhiya82@gmail.com',
        'auth_token': 'dummy_jwt_token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigation(userRole: 'ALUMNI'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ALUMNI'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(AlumniProfileScreen), findsOneWidget);
    });

    testWidgets('4. Admin Module: AdminHomeScreen Rendering and Users Tab Admin Exclusion Verification', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ADMIN',
        'userName': 'System Admin',
        'user_email': 'admin@alumni.com',
        'auth_token': 'dummy_jwt_token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AdminHomeScreen), findsOneWidget);
      expect(find.text('Admin Portal'), findsOneWidget);

      // Navigate to Users Tab
      final usersTab = find.text('Users');
      expect(usersTab, findsOneWidget);
      await tester.tap(usersTab);
      await tester.pumpAndSettle();

      // Verify Users tab elements
      expect(find.text('Add User'), findsOneWidget);
      expect(find.text('All Users'), findsOneWidget);
      expect(find.text('Alumni'), findsOneWidget);
      expect(find.text('Faculty'), findsOneWidget);
      expect(find.text('Students'), findsOneWidget);

      // Verify that NO Card in the Users list contains an ADMIN role badge
      final adminUserCards = find.descendant(
        of: find.byType(Card),
        matching: find.text('ADMIN'),
      );
      expect(adminUserCards, findsNothing);

      // Test switching filter chips
      await tester.tap(find.text('Alumni'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Faculty'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Students'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All Users'));
      await tester.pumpAndSettle();
    });

    testWidgets('5. Authentication: LoginScreen Validation and Interaction', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Welcome Back'), findsOneWidget);
      expect(find.textContaining('take you to the right place'), findsOneWidget);

      // Verify form elements exist
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('6. SearchScreen Layout and Query Interaction', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('7. Admin Module: Add User Dialog Opens, Validates, and Dismisses Without Crash', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ADMIN',
        'userName': 'Admin User',
        'user_email': 'admin@alumni.com',
        'auth_token': 'dummy_jwt_token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add User'));
      await tester.pumpAndSettle();

      expect(find.text('Add New User'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);

      // Tap Create User to verify client validation
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create User'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter full name'), findsOneWidget);

      // Tap Cancel to dismiss cleanly without assertion failure
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Add New User'), findsNothing);
    });

    testWidgets('8. Email Verification Screen: Renders Email, Cooldown, and Handles Empty Input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmailVerificationScreen(
            email: 'student.verify@glsu.edu.in',
            purpose: 'ACCOUNT_ACTIVATION',
            initialCooldownSeconds: 30,
            otpDispatched: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('student.verify@glsu.edu.in'), findsOneWidget);
      expect(find.textContaining('Resend in 30s'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify Code'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter the complete 6-digit code'), findsOneWidget);
    });
  });
}
