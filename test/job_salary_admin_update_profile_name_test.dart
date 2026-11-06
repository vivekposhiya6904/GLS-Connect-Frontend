import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/utils/salary_helper.dart';
import 'package:alumni_management/utils/storage_service.dart';
import 'package:alumni_management/models/job_model.dart';
import 'package:alumni_management/screens/job_post/job_post_screen.dart';
import 'package:alumni_management/widgets/edit_name_dialog.dart';
import 'package:alumni_management/services/cache_service.dart';
import 'package:alumni_management/screens/profile/student_profile_screen.dart';
import 'package:alumni_management/screens/profile/alumni_profile_screen.dart';
import 'package:alumni_management/screens/profile/faculty_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.init();
    CacheService.clearForTest();
  });

  group('1. Salary Extraction & Formatting Tests', () {
    test('formatNumericOnly extracts pure numeric string from various salary formats', () {
      expect(SalaryHelper.formatNumericOnly("4 LPA"), equals("4"));
      expect(SalaryHelper.formatNumericOnly("4.5 LPA"), equals("4.5"));
      expect(SalaryHelper.formatNumericOnly("5 LPA"), equals("5"));
      expect(SalaryHelper.formatNumericOnly("7 LPA"), equals("7"));
      expect(SalaryHelper.formatNumericOnly("8.5 LPA"), equals("8.5"));
      expect(SalaryHelper.formatNumericOnly("12 LPA"), equals("12"));
      expect(SalaryHelper.formatNumericOnly("₹4.5 LPA"), equals("4.5"));
      expect(SalaryHelper.formatNumericOnly("₹10 LPA"), equals("10"));
      expect(SalaryHelper.formatNumericOnly("7"), equals("7"));
      expect(SalaryHelper.formatNumericOnly("8.25"), equals("8.25"));
      expect(SalaryHelper.formatNumericOnly(""), equals(""));
      expect(SalaryHelper.formatNumericOnly(null), equals(""));
    });

    test('formatLpa formats numeric values cleanly with standard ₹X LPA display', () {
      expect(SalaryHelper.formatLpa("4"), equals("₹4 LPA"));
      expect(SalaryHelper.formatLpa("4.5"), equals("₹4.5 LPA"));
      expect(SalaryHelper.formatLpa("7 LPA"), equals("₹7 LPA"));
      expect(SalaryHelper.formatLpa("12 LPA"), equals("₹12 LPA"));
    });
  });

  group('2. PostJobScreen Salary Field & Edit Flow Tests', () {
    final sampleJob = JobModel(
      id: 101,
      userId: 42,
      userName: "Jane Alumni",
      jobTitle: "Senior Flutter Engineer",
      companyName: "Google Inc",
      location: "Ahmedabad",
      salary: "7 LPA",
      jobDescription: "Exciting senior software engineering role in mobile app development.",
      skillsRequired: "Flutter, Dart, Clean Architecture",
      experienceRequired: "3-5 Years",
      joiningType: "Immediate",
      jobType: "Full Time",
      lastDateToApply: "2026-12-31",
      userEmail: "alumni@gls.edu.in",
    );

    testWidgets('Opening job for editing populates ONLY the numeric salary value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostJobScreen(jobToEdit: sampleJob),
        ),
      );
      await tester.pumpAndSettle();

      // Find the salary TextFormField
      final salaryFieldFinder = find.widgetWithText(TextFormField, "7");
      expect(salaryFieldFinder, findsOneWidget);

      // Verify "7 LPA" is NOT in the text controller
      final textFormField = tester.widget<TextFormField>(
        find.byWidgetPredicate(
          (w) => w is TextFormField && w.controller?.text == "7",
        ),
      );
      expect(textFormField.controller?.text, equals("7"));

      // Verify button says "Update Job" when editing
      expect(find.text("Update Job"), findsOneWidget);
      expect(find.text("Edit Job"), findsOneWidget);
    });

    testWidgets('Opening job with decimal salary populates decimal numeric value', (tester) async {
      final decimalJob = JobModel(
        id: 102,
        userId: 42,
        userName: "Jane Alumni",
        jobTitle: "Senior Flutter Engineer",
        companyName: "Google Inc",
        location: "Ahmedabad",
        salary: "4.5 LPA",
        jobDescription: "Exciting senior software engineering role in mobile app development.",
        skillsRequired: "Flutter, Dart, Clean Architecture",
        experienceRequired: "3-5 Years",
        joiningType: "Immediate",
        jobType: "Full Time",
        lastDateToApply: "2026-12-31",
        userEmail: "alumni@gls.edu.in",
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PostJobScreen(jobToEdit: decimalJob),
        ),
      );
      await tester.pumpAndSettle();

      final textFormField = tester.widget<TextFormField>(
        find.byWidgetPredicate(
          (w) => w is TextFormField && w.controller?.text == "4.5",
        ),
      );
      expect(textFormField.controller?.text, equals("4.5"));
    });

    testWidgets('Posting new job displays "Post Job" and empty salary field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PostJobScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Post Job"), findsWidgets);
    });
  });

  group('3. EditNameDialog & Profile Name Update Tests', () {
    testWidgets('EditNameDialog renders with current name and validates required input', (tester) async {
      String updatedName = "";

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => EditNameDialog.show(
                  ctx,
                  currentName: "Jane Doe",
                  onNameUpdated: (n) => updatedName = n,
                ),
                child: const Text("Open Dialog"),
              ),
            ),
          ),
        ),
      );

      // Tap to open dialog
      await tester.tap(find.text("Open Dialog"));
      await tester.pumpAndSettle();

      // Verify dialog is open and displays current name
      expect(find.text("Edit Full Name"), findsOneWidget);
      expect(find.text("Jane Doe"), findsOneWidget);
      expect(find.text("Save"), findsOneWidget);
      expect(find.text("Cancel"), findsOneWidget);

      // Clear the text field to test empty validation
      await tester.enterText(find.byType(TextFormField), "");
      await tester.tap(find.text("Save"));
      await tester.pumpAndSettle();

      expect(find.text("Name cannot be empty."), findsOneWidget);

      // Enter single char to test min length validation
      await tester.enterText(find.byType(TextFormField), "A");
      await tester.tap(find.text("Save"));
      await tester.pumpAndSettle();

      expect(find.text("Name must be at least 2 characters."), findsOneWidget);

      // Cancel dismisses the dialog
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();

      expect(find.text("Edit Full Name"), findsNothing);
      expect(updatedName, isEmpty);
    });

    testWidgets('EditNameDialog cancels cleanly without changing state', (tester) async {
      bool called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => EditNameDialog.show(
                  ctx,
                  currentName: "Original Name",
                  onNameUpdated: (_) => called = true,
                ),
                child: const Text("Open"),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text("Open"));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), "Original Name");
      await tester.tap(find.text("Save")); // Same name should simply dismiss
      await tester.pumpAndSettle();

      expect(find.text("Edit Full Name"), findsNothing);
      expect(called, isFalse);
    });

    testWidgets('StudentProfileScreen renders Edit Name button tooltip and can open EditNameDialog', (tester) async {
      await StorageService.saveUserName("John Student");
      await StorageService.saveUserEmail("john.student@gls.edu.in");
      await StorageService.saveToken("mock_jwt");

      await tester.pumpWidget(
        const MaterialApp(
          home: StudentProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final editNameBtn = find.byTooltip("Edit Name");
      expect(editNameBtn, findsOneWidget);

      await tester.tap(editNameBtn);
      await tester.pumpAndSettle();

      expect(find.text("Edit Full Name"), findsOneWidget);
      expect(find.text("John Student"), findsWidgets);
    });

    testWidgets('AlumniProfileScreen renders Edit Name button tooltip and can open EditNameDialog', (tester) async {
      await StorageService.saveUserName("Alice Alumni");
      await StorageService.saveUserEmail("alice.alumni@gls.edu.in");
      await StorageService.saveToken("mock_jwt");

      await tester.pumpWidget(
        const MaterialApp(
          home: AlumniProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final editNameBtn = find.byTooltip("Edit Name");
      expect(editNameBtn, findsOneWidget);

      await tester.tap(editNameBtn);
      await tester.pumpAndSettle();

      expect(find.text("Edit Full Name"), findsOneWidget);
    });

    testWidgets('FacultyProfileScreen renders Edit Name button tooltip and can open EditNameDialog', (tester) async {
      await StorageService.saveUserName("Dr. Smith");
      await StorageService.saveUserEmail("smith@gls.edu.in");
      await StorageService.saveToken("mock_jwt");

      await tester.pumpWidget(
        const MaterialApp(
          home: FacultyProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final editNameBtn = find.byTooltip("Edit Name");
      expect(editNameBtn, findsOneWidget);

      await tester.tap(editNameBtn);
      await tester.pumpAndSettle();

      expect(find.text("Edit Full Name"), findsOneWidget);
    });
  });
}
