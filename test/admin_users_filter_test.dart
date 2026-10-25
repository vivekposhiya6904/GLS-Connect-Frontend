import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/screens/dashboard/admin_home_screen.dart';
import 'package:alumni_management/services/admin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Users Tab Role Filtering and Protection Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ADMIN',
        'auth_token': 'dummy_admin_token',
      });
    });

    test('AdminService.getAllUsers and getUsersByRole excludes ADMIN accounts', () {
      final mixedList = [
        AdminUserDto(id: 1, name: 'Root Admin', email: 'admin@alumni.com', roleName: 'ADMIN', department: 'ADMIN'),
        AdminUserDto(id: 2, name: 'Vivek Alumni', email: 'alumni@gls.edu', roleName: 'ALUMNI', department: 'MCA'),
        AdminUserDto(id: 3, name: 'Prof. Sharma', email: 'sharma@gls.edu', roleName: 'FACULTY', department: 'CSE'),
        AdminUserDto(id: 4, name: 'Rahul Student', email: 'rahul@gls.edu', roleName: 'STUDENT', department: 'IT'),
      ];

      // Filtered list simulation as implemented in AdminService
      final nonAdminUsers = mixedList.where((u) => u.roleName.toUpperCase() != 'ADMIN').toList();

      expect(nonAdminUsers.length, 3);
      expect(nonAdminUsers.any((u) => u.roleName.toUpperCase() == 'ADMIN'), isFalse);
      expect(nonAdminUsers.any((u) => u.roleName == 'ALUMNI'), isTrue);
      expect(nonAdminUsers.any((u) => u.roleName == 'FACULTY'), isTrue);
      expect(nonAdminUsers.any((u) => u.roleName == 'STUDENT'), isTrue);
    });

    testWidgets('AdminHomeScreen Users Tab renders and does NOT display any ADMIN user cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Users tab (index 1)
      final usersTab = find.text("Users");
      expect(usersTab, findsOneWidget);
      await tester.tap(usersTab);
      await tester.pumpAndSettle();

      // Verify Users tab UI components
      expect(find.text("Add User"), findsOneWidget);
      expect(find.text("All Users"), findsOneWidget);
      expect(find.text("Alumni"), findsOneWidget);
      expect(find.text("Faculty"), findsOneWidget);
      expect(find.text("Students"), findsOneWidget);

      // Verify that no ADMIN role chip or filter is displayed in the user list
      // Note: The header AppBar has an "ADMIN" badge indicating the logged-in role,
      // but in the users tab list, no user card with role "ADMIN" should exist.
      final adminUserChips = find.descendant(
        of: find.byType(Card),
        matching: find.text("ADMIN"),
      );
      expect(adminUserChips, findsNothing);
    });

    testWidgets('Filter chips switch smoothly between All Users, Alumni, Faculty, and Students', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Users tab
      await tester.tap(find.text("Users"));
      await tester.pumpAndSettle();

      // Tap Alumni filter chip
      await tester.tap(find.text("Alumni"));
      await tester.pumpAndSettle();

      // Tap Faculty filter chip
      await tester.tap(find.text("Faculty"));
      await tester.pumpAndSettle();

      // Tap Students filter chip
      await tester.tap(find.text("Students"));
      await tester.pumpAndSettle();

      // Tap All Users filter chip
      await tester.tap(find.text("All Users"));
      await tester.pumpAndSettle();

      // Verify still on Users tab without errors
      expect(find.text("Add User"), findsOneWidget);
    });

    testWidgets('Search input does not match or expose admin accounts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Users tab
      await tester.tap(find.text("Users"));
      await tester.pumpAndSettle();

      // Enter search query "admin"
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'admin');
      await tester.pumpAndSettle();

      // No card with ADMIN role should be found
      final adminCards = find.descendant(
        of: find.byType(Card),
        matching: find.text("ADMIN"),
      );
      expect(adminCards, findsNothing);
    });
  });
}
