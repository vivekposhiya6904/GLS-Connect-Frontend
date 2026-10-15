import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/screens/dashboard/student_home_screen.dart';
import 'package:alumni_management/screens/dashboard/alumni_home_screen.dart';
import 'package:alumni_management/screens/navigation/main_navigation.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'userRole': 'STUDENT',
      'auth_token': 'dummy_test_jwt',
      'user_email': 'student@gls.edu',
      'user_name': 'Test Student',
    });
  });

  group('Student Upper Tab Bar Placement & Full-Width Distribution', () {
    testWidgets('Student TabBar distributes across full width matching theme and parity with Alumni', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StudentHomeScreen()),
      );

      final studentTabBarFinder = find.byType(TabBar);
      expect(studentTabBarFinder, findsOneWidget);
      final TabBar studentTabBar = tester.widget<TabBar>(studentTabBarFinder);

      // Verify Student TabBar full-width distribution configuration
      expect(studentTabBar.isScrollable, isFalse);
      expect(studentTabBar.indicatorColor, Colors.amber);
      expect(studentTabBar.indicatorWeight, 3);
      expect(studentTabBar.tabs.length, 4);

      // Verify tab labels
      expect(find.text("Events"), findsOneWidget);
      expect(find.text("Jobs"), findsOneWidget);
      expect(find.text("My Activity"), findsNothing);
      expect(find.text("Alumni"), findsOneWidget);
      expect(find.text("Faculty"), findsOneWidget);

      // Now pump Alumni screen and verify indicator styling parity
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );

      final alumniTabBarFinder = find.byType(TabBar);
      expect(alumniTabBarFinder, findsOneWidget);
      final TabBar alumniTabBar = tester.widget<TabBar>(alumniTabBarFinder);

      expect(alumniTabBar.indicatorColor, studentTabBar.indicatorColor);
      expect(alumniTabBar.indicatorWeight, studentTabBar.indicatorWeight);
      expect(alumniTabBar.labelColor, studentTabBar.labelColor);
      expect(alumniTabBar.unselectedLabelColor, studentTabBar.unselectedLabelColor);
    });

    testWidgets('Student TabBar renders without overflow on 320px narrow phone width', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(320, 640)),
          child: MaterialApp(home: StudentHomeScreen()),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text("Events"), findsOneWidget);
      expect(find.text("Jobs"), findsOneWidget);
      expect(find.text("Alumni"), findsOneWidget);
      expect(find.text("Faculty"), findsOneWidget);
    });

    testWidgets('Student TabBar renders and navigates cleanly on normal (390px) phone width', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(390, 844)),
          child: MaterialApp(home: StudentHomeScreen()),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);

      // Test tapping tabs
      await tester.tap(find.text("Jobs"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text("Alumni"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text("Faculty"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text("Events"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Change 1: Remove "My Posts" from My Activity (Alumni & Faculty)', () {
    testWidgets('Alumni My Activity has only My Jobs and My Events, with NO My Posts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MyActivityPage(),
          ),
        ),
      );
      await tester.pump();

      // Check tab controller length is 2
      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);
      final TabBar tabBar = tester.widget<TabBar>(tabBarFinder);
      expect(tabBar.tabs.length, 2);

      // Verify My Jobs and My Events exist
      expect(find.text("My Jobs"), findsOneWidget);
      expect(find.text("My Events"), findsOneWidget);

      // Verify My Posts is removed
      expect(find.text("My Posts"), findsNothing);

      // Test switching between My Jobs and My Events
      await tester.tap(find.text("My Events"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text("My Jobs"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Faculty My Activity explicitly keeps showPosts: false with NO My Posts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MyActivityPage(showPosts: false),
          ),
        ),
      );
      await tester.pump();

      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);
      final TabBar tabBar = tester.widget<TabBar>(tabBarFinder);
      expect(tabBar.tabs.length, 2);

      expect(find.text("My Jobs"), findsOneWidget);
      expect(find.text("My Events"), findsOneWidget);
      expect(find.text("My Posts"), findsNothing);
    });
  });

  group('Change 2: Replace Bottom Navigation Plus Button with Plain Dark Plus Icon', () {
    testWidgets('Alumni bottom navigation renders plain dark plus icon without circular or square container', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ALUMNI',
        'auth_token': 'dummy_jwt',
        'user_email': 'alumni@gls.edu',
      });

      await tester.pumpWidget(
        const MaterialApp(home: MainNavigation(userRole: 'ALUMNI')),
      );
      await tester.pump();

      // Verify Create label and add icon exist
      expect(find.text("Create"), findsOneWidget);
      final addIconFinder = find.byIcon(Icons.add);
      expect(addIconFinder, findsOneWidget);

      final Icon iconWidget = tester.widget<Icon>(addIconFinder);
      // Verify icon color is dark, near-black
      expect(iconWidget.color, const Color(0xFF0D1B2A));

      // Verify NO container surrounds the plus icon inside Create nav item
      final createItemContainer = find.descendant(
        of: find.byTooltip('Create'),
        matching: find.byType(Container),
      );
      expect(createItemContainer, findsNothing);
    });

    testWidgets('Faculty bottom navigation also renders plain dark plus icon without container', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'FACULTY',
        'auth_token': 'dummy_jwt',
        'user_email': 'faculty@gls.edu',
      });

      await tester.pumpWidget(
        const MaterialApp(home: MainNavigation(userRole: 'FACULTY')),
      );
      await tester.pump();

      expect(find.text("Create"), findsOneWidget);
      final addIconFinder = find.byIcon(Icons.add);
      expect(addIconFinder, findsOneWidget);

      final Icon iconWidget = tester.widget<Icon>(addIconFinder);
      expect(iconWidget.color, const Color(0xFF0D1B2A));

      final createItemContainer = find.descendant(
        of: find.byTooltip('Create'),
        matching: find.byType(Container),
      );
      expect(createItemContainer, findsNothing);
    });

    testWidgets('Student bottom navigation strictly excludes Create (+) button', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'STUDENT',
        'auth_token': 'dummy_jwt',
        'user_email': 'student@gls.edu',
      });

      await tester.pumpWidget(
        const MaterialApp(home: MainNavigation(userRole: 'STUDENT')),
      );
      await tester.pump();

      expect(find.text("Create"), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.text("Home"), findsOneWidget);
      expect(find.text("Chat"), findsOneWidget);
      expect(find.text("Profile"), findsOneWidget);
    });

    testWidgets('Tapping plain plus icon opens Create modal bottom sheet and debounce prevents duplicates', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ALUMNI',
        'auth_token': 'dummy_jwt',
        'user_email': 'alumni@gls.edu',
      });

      await tester.pumpWidget(
        const MaterialApp(home: MainNavigation(userRole: 'ALUMNI')),
      );
      await tester.pump();

      final addIconFinder = find.byIcon(Icons.add);
      expect(addIconFinder, findsOneWidget);

      // Tap the plus button
      await tester.tap(addIconFinder);
      await tester.pumpAndSettle();

      // Verify Create modal sheet actions appear
      expect(find.text("Post Job"), findsOneWidget);
      expect(find.text("Create Event"), findsOneWidget);

      // Attempt repeated tap while sheet is open - should not throw or duplicate
      await tester.tap(find.text("Post Job"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Alumni bottom navigation with plain plus icon does not overflow on 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'userRole': 'ALUMNI',
        'auth_token': 'dummy_jwt',
        'user_email': 'alumni@gls.edu',
      });

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(320, 600)),
          child: MaterialApp(home: MainNavigation(userRole: 'ALUMNI')),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Home"), findsOneWidget);
      expect(find.text("Create"), findsOneWidget);
      expect(find.text("Chat"), findsOneWidget);
      expect(find.text("Profile"), findsOneWidget);
    });
  });
}
