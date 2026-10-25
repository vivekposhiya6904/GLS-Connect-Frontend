import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/screens/profile/faculty_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'userRole': 'FACULTY',
      'userName': 'Dr. Charlie Faculty',
      'user_email': 'charlie@gls.edu',
      'auth_token': 'dummy_jwt',
    });
  });

  testWidgets('FacultyProfileScreen renders and scrolls without overflow on 360x640', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: FacultyProfileScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(FacultyProfileScreen), findsOneWidget);

    // Scroll through the entire page to verify no collapse or list overflows
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    // Scroll back up
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 700));
    await tester.pumpAndSettle();
  });

  testWidgets('FacultyProfileScreen renders on narrow 320x568 (iPhone SE / compact)', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: FacultyProfileScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(FacultyProfileScreen), findsOneWidget);

    // Scroll down
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
  });

  testWidgets('FacultyProfileScreen handles extremely long profile data without overflow', (tester) async {
    SharedPreferences.setMockInitialValues({
      'userRole': 'FACULTY',
      'userName': 'Professor Dr. Bartholomew Alexander Montgomery III, Ph.D., D.Sc.',
      'user_email': 'charlie@gls.edu',
      'auth_token': 'dummy_jwt',
    });

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: FacultyProfileScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(FacultyProfileScreen), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
  });

  testWidgets('FacultyProfileScreen toggles Edit Mode and renders form fields without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: FacultyProfileScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final editBtn = find.text("Edit Profile");
    await tester.scrollUntilVisible(
      editBtn,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(editBtn, findsOneWidget);
    await tester.tap(editBtn);
    await tester.pumpAndSettle();

    // Verify Save Changes button is visible
    expect(find.text("Save Changes"), findsOneWidget);

    // Scroll up and down in edit mode
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
  });

  testWidgets('FacultyProfileScreen renders under 1.25x accessibility text scaling without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.25),
            size: Size(360, 640),
          ),
          child: const FacultyProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(FacultyProfileScreen), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
  });
}
