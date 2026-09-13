import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/screens/router/dashboard_router.dart';
import 'package:alumni_management/screens/navigation/main_navigation.dart';
import 'package:alumni_management/screens/dashboard/alumni_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alumni Panel Design Restoration Tests', () {
    testWidgets('Alumni screen has previous header, tabs, actions, and bottom navigation', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ALUMNI',
        'auth_token': 'dummy_token',
        'user_email': 'alumni@test.com',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardRouter(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify MainNavigation is active for Alumni
      expect(find.byType(MainNavigation), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);

      // 2. Verify Header Title and ALUMNI badge
      expect(find.text("GLS Connect"), findsOneWidget);
      expect(find.text("ALUMNI"), findsOneWidget);

      // 3. Verify Header Actions: Notifications & Search (NO Admin logout or chat in AppBar)
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsNothing);

      // 4. Verify 5 Restored Tabs
      expect(find.text("All"), findsOneWidget);
      expect(find.text("Jobs"), findsOneWidget);
      expect(find.text("My Activity"), findsOneWidget);
      expect(find.text("Alumni"), findsOneWidget);
      expect(find.text("Faculty"), findsOneWidget);

      // 5. Verify Bottom Navigation items: Home, Create (+), Chat, Profile
      expect(find.text("Home"), findsOneWidget);
      expect(find.text("Create"), findsOneWidget);
      expect(find.text("Chat"), findsOneWidget);
      expect(find.text("Profile"), findsOneWidget);

      // 6. Verify Create BottomSheet works
      final createButton = find.byIcon(Icons.add);
      expect(createButton, findsOneWidget);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text("Post Job"), findsOneWidget);
      expect(find.text("Create Event"), findsOneWidget);
    });
  });
}
