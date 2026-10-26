import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/screens/profile/alumni_profile_screen.dart';
import 'package:alumni_management/screens/profile/student_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Test User',
      'user_email': 'test@gls.edu.in',
      'user_role': 'ALUMNI',
      'auth_token': 'mock_token',
      'login_status': true,
    });
  });

  group('Academic Dropdowns Verification Tests', () {
    testWidgets('AlumniProfileScreen renders dropdowns in edit mode and cancels cleanly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AlumniProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find "Edit Profile" button and tap it
      final editBtn = find.text("Edit Profile");
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verify the three dropdowns are present
      final batchDropdown = find.byKey(const Key('alumni_batch_year_dropdown'));
      final degreeDropdown = find.byKey(const Key('alumni_degree_dropdown'));
      final deptDropdown = find.byKey(const Key('alumni_department_dropdown'));

      expect(batchDropdown, findsOneWidget);
      expect(degreeDropdown, findsOneWidget);
      expect(deptDropdown, findsOneWidget);

      // Verify Cancel and Save buttons exist
      final cancelBtn = find.text("Cancel");
      final saveBtn = find.text("Save");

      expect(cancelBtn, findsOneWidget);
      expect(saveBtn, findsOneWidget);

      // Tap Cancel to ensure edit mode exits cleanly
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Back to Edit Profile button
      expect(find.text("Edit Profile"), findsOneWidget);
    });

    testWidgets('StudentProfileScreen renders dropdowns in edit mode and allows selection',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: StudentProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit Profile icon in AppBar
      final editIcon = find.byTooltip("Edit Profile");
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Verify the three dropdowns are present
      final degreeDropdown = find.byKey(const Key('student_degree_dropdown'));
      final deptDropdown = find.byKey(const Key('student_department_dropdown'));
      final batchDropdown = find.byKey(const Key('student_batch_year_dropdown'));

      expect(degreeDropdown, findsOneWidget);
      expect(deptDropdown, findsOneWidget);
      expect(batchDropdown, findsOneWidget);

      // Verify cancel icon in AppBar
      expect(find.byTooltip("Cancel"), findsOneWidget);

      // Verify bottom buttons exist
      final saveBtn = find.text("Save Changes");
      final cancelBtn = find.widgetWithText(OutlinedButton, "Cancel");

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(cancelBtn, findsOneWidget);
      expect(saveBtn, findsOneWidget);

      // Tap Cancel in AppBar
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip("Cancel"));
      await tester.pumpAndSettle();

      // Back to view mode
      expect(find.byTooltip("Edit Profile"), findsOneWidget);
    });

    testWidgets('Degree change updates department options safely',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: StudentProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip("Edit Profile"));
      await tester.pumpAndSettle();

      // Degree dropdown is visible
      final degreeFinder = find.byKey(const Key('student_degree_dropdown'));
      expect(degreeFinder, findsOneWidget);
      await tester.ensureVisible(degreeFinder);

      // Tap degree dropdown
      await tester.tap(degreeFinder);
      await tester.pumpAndSettle();

      // Select MBA
      final mbaItem = find.widgetWithText(DropdownMenuItem<String>, "MBA").last;
      await tester.tap(mbaItem, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Open Department dropdown
      final deptFinder = find.byKey(const Key('student_department_dropdown'));
      await tester.ensureVisible(deptFinder);
      await tester.tap(deptFinder);
      await tester.pumpAndSettle();

      // Verify Management / MBA options are present
      expect(find.widgetWithText(DropdownMenuItem<String>, "Management"), findsWidgets);
    });

    testWidgets('Selecting Other in Degree and Department reveals custom input fields in StudentProfileScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: StudentProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip("Edit Profile"));
      await tester.pumpAndSettle();

      // Degree dropdown is visible
      final degreeFinder = find.byKey(const Key('student_degree_dropdown'));
      await tester.ensureVisible(degreeFinder);

      // Custom degree field should NOT exist initially
      expect(find.byKey(const Key('student_custom_degree_field')), findsNothing);

      // Tap Degree dropdown and select "Other"
      await tester.tap(degreeFinder);
      await tester.pumpAndSettle();
      final otherDegreeItem = find.widgetWithText(DropdownMenuItem<String>, "Other").last;
      await tester.tap(otherDegreeItem, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Now custom degree field MUST be visible
      final customDegreeFinder = find.byKey(const Key('student_custom_degree_field'));
      expect(customDegreeFinder, findsOneWidget);

      // Enter a custom degree name
      await tester.enterText(customDegreeFinder, "B.Arch");
      await tester.pumpAndSettle();

      // Department dropdown is visible
      final deptFinder = find.byKey(const Key('student_department_dropdown'));
      await tester.ensureVisible(deptFinder);

      // Custom department field should NOT exist initially
      expect(find.byKey(const Key('student_custom_department_field')), findsNothing);

      // Tap Department dropdown and select "Other"
      await tester.tap(deptFinder);
      await tester.pumpAndSettle();
      final otherDeptItem = find.widgetWithText(DropdownMenuItem<String>, "Other").last;
      await tester.tap(otherDeptItem, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Now custom department field MUST be visible
      final customDeptFinder = find.byKey(const Key('student_custom_department_field'));
      expect(customDeptFinder, findsOneWidget);

      // Enter a custom department name
      await tester.enterText(customDeptFinder, "Architecture & Urban Planning");
      await tester.pumpAndSettle();

      // Now switch Degree back to a predefined one e.g. "MCA"
      await tester.tap(degreeFinder);
      await tester.pumpAndSettle();
      final mcaItem = find.widgetWithText(DropdownMenuItem<String>, "MCA").last;
      await tester.tap(mcaItem, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Custom degree field should now be hidden
      expect(find.byKey(const Key('student_custom_degree_field')), findsNothing);
    });

    testWidgets('AlumniProfileScreen displays custom fields when Other is selected',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AlumniProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final editBtn = find.text("Edit Profile");
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      final degreeDropdown = find.byKey(const Key('alumni_degree_dropdown'));
      expect(degreeDropdown, findsOneWidget);

      // Custom degree field should NOT exist initially
      expect(find.byKey(const Key('alumni_custom_degree_field')), findsNothing);

      // Select Other in degree
      await tester.tap(degreeDropdown);
      await tester.pumpAndSettle();
      final otherDegree = find.widgetWithText(DropdownMenuItem<String>, "Other").last;
      await tester.tap(otherDegree, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Custom degree field is now displayed
      expect(find.byKey(const Key('alumni_custom_degree_field')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('alumni_custom_degree_field')), "Ph.D Bioinformatics");
      await tester.pumpAndSettle();

      // Select Other in department
      final deptDropdown = find.byKey(const Key('alumni_department_dropdown'));
      expect(find.byKey(const Key('alumni_custom_department_field')), findsNothing);

      await tester.tap(deptDropdown);
      await tester.pumpAndSettle();
      final otherDept = find.widgetWithText(DropdownMenuItem<String>, "Other").last;
      await tester.tap(otherDept, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Custom department field is now displayed
      expect(find.byKey(const Key('alumni_custom_department_field')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('alumni_custom_department_field')), "Computational Biology");
      await tester.pumpAndSettle();
    });
  });
}
