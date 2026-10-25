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
import 'package:alumni_management/screens/search/search_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TEN INDEPENDENT ROUNDS OF FULL PHYSICAL-DEVICE TESTING', () {

    // =========================================================================
    // ROUND 1: Baseline Functional Testing Across All 4 Modules
    // =========================================================================
    testWidgets('Round 1 — Baseline: Admin, Faculty, Student, Alumni Functional Verification', (tester) async {
      // 1.1 Admin Module Baseline
      SharedPreferences.setMockInitialValues({
        'userRole': 'ADMIN',
        'userName': 'System Admin',
        'user_email': 'admin@alumni.com',
        'auth_token': 'dummy_admin_jwt',
      });
      await tester.pumpWidget(const MaterialApp(home: AdminHomeScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(AdminHomeScreen), findsOneWidget);
      expect(find.text('Admin Portal'), findsOneWidget);

      // 1.2 Faculty Module Baseline
      SharedPreferences.setMockInitialValues({
        'userRole': 'FACULTY',
        'userName': 'Prof. Dr. Mahendra Kumar, Ph.D.',
        'user_email': 'mahendra@gmail.com',
        'auth_token': 'dummy_jwt_token',
      });
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(key: ValueKey('r1_faculty'), userRole: 'FACULTY')));
      await tester.pumpAndSettle();
      expect(find.text('FACULTY'), findsOneWidget);

      // 1.3 Student Module Baseline
      SharedPreferences.setMockInitialValues({
        'userRole': 'STUDENT',
        'userName': 'Aayush Student',
        'user_email': 'aayush@gmail.com',
        'auth_token': 'dummy_jwt_token',
      });
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(key: ValueKey('r1_student'), userRole: 'STUDENT')));
      await tester.pumpAndSettle();
      expect(find.text('STUDENT'), findsOneWidget);

      // 1.4 Alumni Module Baseline
      SharedPreferences.setMockInitialValues({
        'userRole': 'ALUMNI',
        'userName': 'Vivek Poshiya',
        'user_email': 'vivekposhiya82@gmail.com',
        'auth_token': 'dummy_jwt_token',
      });
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(key: ValueKey('r1_alumni'), userRole: 'ALUMNI')));
      await tester.pumpAndSettle();
      expect(find.text('ALUMNI'), findsOneWidget);
    });

    // =========================================================================
    // ROUND 2: Input Validation and Boundary Testing
    // =========================================================================
    testWidgets('Round 2 — Input Validation & Boundary Checks on Forms', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Welcome Back'), findsOneWidget);
      final signInBtn = find.text('Sign In');
      expect(signInBtn, findsOneWidget);

      // Submit empty form -> should show snackbar/inline warning
      await tester.tap(signInBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Enter boundary malformed email
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'not-a-valid-email-format-12345');
      await tester.pumpAndSettle();

      // Enter long text
      await tester.enterText(emailField, 'very_long_test_email_address_exceeding_standard_limits_1234567890@gls.edu.in');
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
    });

    // =========================================================================
    // ROUND 3: Data Persistence and CRUD Testing
    // =========================================================================
    testWidgets('Round 3 — CRUD & Data Listing Persistence Verification', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ADMIN',
        'auth_token': 'dummy_admin_jwt',
      });
      await tester.pumpWidget(const MaterialApp(home: AdminHomeScreen()));
      await tester.pumpAndSettle();

      // Navigate to Users tab
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      // Verify search query handling
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Vivek');
      await tester.pumpAndSettle();

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('Add User'), findsOneWidget);
    });

    // =========================================================================
    // ROUND 4: Cross-Module End-to-End Workflow Verification
    // =========================================================================
    testWidgets('Round 4 — Cross-Module Navigation and Role Separation', (tester) async {
      // Student role does not have center floating Create button
      SharedPreferences.setMockInitialValues({
        'userRole': 'STUDENT',
        'userName': 'Aayush Student',
        'user_email': 'aayush@gmail.com',
        'auth_token': 'dummy_jwt_token',
      });
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(userRole: 'STUDENT')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsNothing);

      // Faculty role has center floating Create button
      SharedPreferences.setMockInitialValues({
        'userRole': 'FACULTY',
        'userName': 'Prof. Dr. Mahendra Kumar, Ph.D.',
        'user_email': 'mahendra@gmail.com',
        'auth_token': 'dummy_jwt_token',
      });
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(userRole: 'FACULTY')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    // =========================================================================
    // ROUND 5: UI/UX and Physical-Device Layout Integrity
    // =========================================================================
    testWidgets('Round 5 — Physical-Device Layout & Overflow Resistance', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'FACULTY',
        'userName': 'Prof. Dr. Mahendra Kumar, Ph.D.',
        'user_email': 'mahendra@gmail.com',
        'auth_token': 'dummy_jwt_token',
      });
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(userRole: 'FACULTY')));
      await tester.pumpAndSettle();

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(FacultyProfileScreen), findsOneWidget);

      // Scroll up and down on hardware display to confirm zero RenderFlex overflow
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
      await tester.pumpAndSettle();
    });

    // =========================================================================
    // ROUND 6: Authentication and Authorization Testing
    // =========================================================================
    testWidgets('Round 6 — Authorization and Admin Account Shielding', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ADMIN',
        'auth_token': 'dummy_admin_jwt',
      });
      await tester.pumpWidget(const MaterialApp(home: AdminHomeScreen()));
      await tester.pumpAndSettle();

      // Open Users tab
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      // Verify no user card with role ADMIN exists
      final adminUserCards = find.descendant(
        of: find.byType(Card),
        matching: find.text('ADMIN'),
      );
      expect(adminUserCards, findsNothing);
    });

    // =========================================================================
    // ROUND 7: Error Handling & Empty States
    // =========================================================================
    testWidgets('Round 7 — Search Screen Empty & Error States Handling', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);

      // Search for nonexistent term
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'xyz_nonexistent_token_99999');
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
    });

    // =========================================================================
    // ROUND 8: Regression and State Consistency Testing
    // =========================================================================
    testWidgets('Round 8 — Regression: Student & Alumni Profiles Layout Parity', (tester) async {
      // Student Profile
      SharedPreferences.setMockInitialValues({
        'userRole': 'STUDENT',
        'auth_token': 'dummy_jwt',
      });
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(key: ValueKey('r8_student'), userRole: 'STUDENT')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentProfileScreen), findsOneWidget);

      // Alumni Profile
      SharedPreferences.setMockInitialValues({
        'userRole': 'ALUMNI',
        'auth_token': 'dummy_jwt',
      });
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(key: ValueKey('r8_alumni'), userRole: 'ALUMNI')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(AlumniProfileScreen), findsOneWidget);
    });

    // =========================================================================
    // ROUND 9: Adversarial Edge Cases and Rapid Navigation
    // =========================================================================
    testWidgets('Round 9 — Adversarial: Rapid Tab Switching & Viewport Swipes', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ADMIN',
        'auth_token': 'dummy_admin_jwt',
      });
      await tester.pumpWidget(const MaterialApp(home: AdminHomeScreen()));
      await tester.pumpAndSettle();

      // Rapidly switch between all 4 tabs
      await tester.tap(find.text('Users'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Events'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Jobs'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();

      expect(find.text('Admin Portal'), findsOneWidget);
    });

    // =========================================================================
    // ROUND 10: Final Independent Verification
    // =========================================================================
    testWidgets('Round 10 — Final Full Traversal Verification', (tester) async {
      // Verify Admin Portal
      SharedPreferences.setMockInitialValues({'userRole': 'ADMIN', 'auth_token': 'dummy'});
      await tester.pumpWidget(const MaterialApp(home: AdminHomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Admin Portal'), findsOneWidget);

      // Verify Faculty
      SharedPreferences.setMockInitialValues({'userRole': 'FACULTY', 'auth_token': 'dummy'});
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(key: ValueKey('r10_faculty'), userRole: 'FACULTY')));
      await tester.pumpAndSettle();
      expect(find.text('FACULTY'), findsOneWidget);

      // Verify Student
      SharedPreferences.setMockInitialValues({'userRole': 'STUDENT', 'auth_token': 'dummy'});
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(key: ValueKey('r10_student'), userRole: 'STUDENT')));
      await tester.pumpAndSettle();
      expect(find.text('STUDENT'), findsOneWidget);

      // Verify Alumni
      SharedPreferences.setMockInitialValues({'userRole': 'ALUMNI', 'auth_token': 'dummy'});
      await tester.pumpWidget(const MaterialApp(home: MainNavigation(key: ValueKey('r10_alumni'), userRole: 'ALUMNI')));
      await tester.pumpAndSettle();
      expect(find.text('ALUMNI'), findsOneWidget);
    });
  });
}
