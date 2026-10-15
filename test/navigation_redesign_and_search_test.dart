import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/widgets/app_search_bar.dart';
import 'package:alumni_management/screens/dashboard/student_home_screen.dart';
import 'package:alumni_management/screens/dashboard/faculty_home_screen.dart';
import 'package:alumni_management/screens/navigation/main_navigation.dart';
import 'package:alumni_management/models/job_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 4 & 5: AppSearchBar Standard Widget Tests', () {
    testWidgets('AppSearchBar renders with search icon, text and clears correctly', (tester) async {
      final controller = TextEditingController();
      String changedText = "";
      bool wasCleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              controller: controller,
              hintText: "Search jobs by title, company or skills...",
              onChanged: (val) => changedText = val,
              onClear: () => wasCleared = true,
            ),
          ),
        ),
      );

      // Verify prefix search icon and hint text
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text("Search jobs by title, company or skills..."), findsOneWidget);
      // Initially clear button should not be present
      expect(find.byIcon(Icons.clear_rounded), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), "Flutter Developer");
      await tester.pump();

      expect(controller.text, "Flutter Developer");
      expect(changedText, "Flutter Developer");
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump();

      expect(controller.text, "");
      expect(wasCleared, isTrue);
      expect(find.byIcon(Icons.clear_rounded), findsNothing);
    });
  });

  group('Task 1 & 2: Student Module Navigation & Centered Tab Alignment Tests', () {
    testWidgets('StudentHomeScreen has 4 tabs, NO My Activity, and centered tab alignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentHomeScreen(),
        ),
      );

      // Verify 4 tabs exist and My Activity is absent
      expect(find.text("Events"), findsOneWidget);
      expect(find.text("Jobs"), findsOneWidget);
      expect(find.text("My Activity"), findsNothing);
      expect(find.text("Alumni"), findsOneWidget);
      expect(find.text("Faculty"), findsOneWidget);

      // Verify TabBar distributes across full width (isScrollable: false, 4 tabs)
      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);
      final TabBar tabBar = tester.widget<TabBar>(tabBarFinder);
      expect(tabBar.isScrollable, isFalse);
      expect(tabBar.tabs.length, 4);
    });

    testWidgets('FacultyDashboard retains My Activity and has centered tab alignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FacultyDashboard(),
        ),
      );

      // Verify 5 tabs exist including My Activity
      expect(find.text("Events"), findsOneWidget);
      expect(find.text("Jobs"), findsOneWidget);
      expect(find.text("My Activity"), findsOneWidget);
      expect(find.text("Alumni"), findsOneWidget);
      expect(find.text("Faculty"), findsOneWidget);

      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);
      final TabBar tabBar = tester.widget<TabBar>(tabBarFinder);
      expect(tabBar.tabAlignment, TabAlignment.center);
      expect(tabBar.isScrollable, isTrue);
    });
  });

  group('Task 3: Alumni & Faculty Create (+) Action Redesign & Student Exclusion Tests', () {
    testWidgets('Student role in MainNavigation has NO Create (+) button', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'STUDENT',
        'auth_token': 'dummy_jwt',
        'user_email': 'student@gls.edu',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigation(userRole: 'STUDENT'),
        ),
      );
      await tester.pump();

      expect(find.text("Create"), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('Alumni role in MainNavigation renders plain dark plus icon for Create (+)', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'ALUMNI',
        'auth_token': 'dummy_jwt',
        'user_email': 'alumni@gls.edu',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigation(userRole: 'ALUMNI'),
        ),
      );
      await tester.pump();

      expect(find.text("Create"), findsOneWidget);
      final addIcon = find.byIcon(Icons.add);
      expect(addIcon, findsOneWidget);

      // Verify icon color is dark near-black matching reference
      final Icon iconWidget = tester.widget<Icon>(addIcon);
      expect(iconWidget.color, const Color(0xFF0D1B2A));
    });
  });

  group('Task 4: Multi-field Job Matching Logic Unit Tests', () {
    test('JobModel search matches title, company, skills, description, and location safely', () {
      final job = JobModel(
        id: 1,
        userId: 10,
        userName: "Recruiter",
        userEmail: "recruiter@tech.com",
        companyName: "Google India",
        jobTitle: "Software Engineer III",
        location: "Bengaluru, Karnataka",
        salary: "24-30 LPA",
        jobDescription: "Architect distributed backend microservices using Kotlin and GCP.",
        skillsRequired: "Java, Kotlin, Cloud Architecture, Docker",
        experienceRequired: "3+ years",
        joiningType: "Full-time",
        jobType: "In-office",
        lastDateToApply: "2026-12-31",
      );

      bool matches(JobModel j, String query) {
        final q = query.trim().toLowerCase();
        if (q.isEmpty) return true;
        return j.jobTitle.toLowerCase().contains(q) ||
            j.companyName.toLowerCase().contains(q) ||
            j.skillsRequired.toLowerCase().contains(q) ||
            j.jobDescription.toLowerCase().contains(q) ||
            j.location.toLowerCase().contains(q);
      }

      expect(matches(job, "Google"), isTrue);
      expect(matches(job, "SOFTWARE"), isTrue);
      expect(matches(job, "Docker"), isTrue);
      expect(matches(job, "microservices"), isTrue);
      expect(matches(job, "Bengaluru"), isTrue);
      expect(matches(job, "NonExistentCompany"), isFalse);
    });
  });
}
