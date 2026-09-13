import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/screens/router/dashboard_router.dart';
import 'package:alumni_management/screens/dashboard/admin_home_screen.dart';
import 'package:alumni_management/screens/navigation/main_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Role Navigation Architecture Tests', () {
    testWidgets('ADMIN role navigates to AdminHomeScreen with NO bottom navigation', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ADMIN',
        'auth_token': 'dummy_token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardRouter(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // AdminHomeScreen should be present
      expect(find.byType(AdminHomeScreen), findsOneWidget);

      // MainNavigation must NOT be present
      expect(find.byType(MainNavigation), findsNothing);

      // BottomNavigationBar must NOT be present
      expect(find.byType(BottomNavigationBar), findsNothing);

      // Admin Portal header and Logout action must be present
      expect(find.text("Admin Portal"), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

      // Refresh button should NOT be present in AppBar actions
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);

      // Verify tabs are available
      expect(find.text("Overview"), findsOneWidget);
      expect(find.text("Users"), findsOneWidget);
      expect(find.text("Events"), findsOneWidget);
      expect(find.text("Jobs"), findsOneWidget);
    });

    testWidgets('ADMIN logout button displays confirmation dialog', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ADMIN',
        'auth_token': 'dummy_token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Logout icon
      final logoutButton = find.byIcon(Icons.logout_rounded);
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Verify Confirmation Dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text("Logout"), findsWidgets);
      expect(find.text("Are you sure you want to log out of the Admin Portal?"), findsOneWidget);
      expect(find.text("Cancel"), findsOneWidget);

      // Tapping Cancel dismisses dialog
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('STUDENT role routes to MainNavigation with bottom navigation', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'STUDENT',
        'auth_token': 'dummy_token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardRouter(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // MainNavigation must be present for STUDENT
      expect(find.byType(MainNavigation), findsOneWidget);
    });

    testWidgets('FACULTY role routes to MainNavigation with bottom navigation', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'FACULTY',
        'auth_token': 'dummy_token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardRouter(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // MainNavigation must be present for FACULTY
      expect(find.byType(MainNavigation), findsOneWidget);
    });

    testWidgets('ALUMNI role routes to MainNavigation with bottom navigation', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ALUMNI',
        'auth_token': 'dummy_token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardRouter(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // MainNavigation must be present for ALUMNI
      expect(find.byType(MainNavigation), findsOneWidget);
    });
  });
}
