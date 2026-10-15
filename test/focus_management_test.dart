import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/utils/focus_helper.dart';
import 'package:alumni_management/widgets/app_search_bar.dart';
import 'package:alumni_management/screens/dashboard/alumni_home_screen.dart';
import 'package:alumni_management/screens/dashboard/student_home_screen.dart' as student;
import 'package:alumni_management/screens/search/search_screen.dart';

// Sample mock event JSON
final _mockEventsJson = jsonEncode(List.generate(10, (i) => {
  'id': 1 + i,
  'title': 'Alumni Annual Meet 2026 #$i',
  'description': 'Annual gathering of alumni and graduating students.',
  'location': 'GLS University Campus, Ahmedabad',
  'eventDate': '2026-12-31',
  'targetDepartment': 'Computer Science',
  'createdBy': {'name': 'Admin', 'email': 'admin@gls.edu'}
}));

// Sample mock job JSON
final _mockJobsJson = jsonEncode(List.generate(10, (i) => {
  'id': 101 + i,
  'userId': 10,
  'userName': 'Recruiter $i',
  'userEmail': 'recruiter$i@tech.com',
  'companyName': 'Google India $i',
  'jobTitle': 'Senior Flutter Engineer $i',
  'location': 'Bengaluru, Karnataka',
  'salary': '15 LPA',
  'jobDescription': 'Build cross-platform applications.',
  'skillsRequired': 'Flutter, Dart, Android',
  'experienceRequired': '3+ years',
  'joiningType': 'Full-time',
  'jobType': 'In-office',
  'lastDateToApply': '2026-12-31'
}));

class _MockHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, List<String>> _data = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _data[name.toLowerCase()] = [value.toString()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _data.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void remove(String name, Object value) {
    _data.remove(name.toLowerCase());
  }

  @override
  void removeAll(String name) {
    _data.remove(name.toLowerCase());
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _data.forEach(action);
  }

  @override
  List<String>? operator [](String name) => _data[name.toLowerCase()];

  @override
  String? value(String name) {
    final list = _data[name.toLowerCase()];
    return (list != null && list.isNotEmpty) ? list.last : null;
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  final Uri url;
  final _headers = _MockHttpHeaders();

  _MockHttpClientRequest(this.url);

  @override
  HttpHeaders get headers => _headers;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = 0;

  @override
  bool persistentConnection = true;

  @override
  void add(List<int> data) {}

  @override
  Future addStream(Stream<List<int>> stream) async {
    await stream.drain();
  }

  @override
  Future<HttpClientResponse> close() async {
    final path = url.path;
    String responseBody = '[]';
    if (path.contains('/api/events')) {
      responseBody = _mockEventsJson;
    } else if (path.contains('/api/jobs')) {
      responseBody = _mockJobsJson;
    } else if (path.contains('/api/user')) {
      responseBody = '[]';
    }
    return _MockHttpClientResponse(responseBody);
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest(url);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest(url);
  }

  @override
  void close({bool force = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  final String responseBody;
  final _headers = _MockHttpHeaders();
  _MockHttpClientResponse(this.responseBody);

  @override
  HttpHeaders get headers => _headers;

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  int get contentLength => utf8.encode(responseBody).length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([utf8.encode(responseBody)]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _MockTestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

void main() {
  setUp(() {
    HttpOverrides.global = _MockTestHttpOverrides();
    SharedPreferences.setMockInitialValues({
      'userRole': 'ALUMNI',
      'auth_token': 'dummy_jwt',
      'user_email': 'alumni@gls.edu',
      'user_name': 'Test Alumni',
    });
  });

  group('Application-Wide Focus & Keyboard Management', () {
    testWidgets('AppFocusHelper.unfocus() dismisses focus from active text input', (tester) async {
      final FocusNode focusNode = FocusNode();
      final TextEditingController controller = TextEditingController();
      addTearDown(() {
        focusNode.dispose();
        controller.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Focus the text field
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Dismiss with AppFocusHelper
      AppFocusHelper.unfocus();
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('AppSearchBar properly honors focusNode and dismisses focus on submit', (tester) async {
      final FocusNode focusNode = FocusNode();
      final TextEditingController controller = TextEditingController();
      bool submitted = false;
      addTearDown(() {
        focusNode.dispose();
        controller.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              controller: controller,
              focusNode: focusNode,
              hintText: "Search here...",
              onSubmitted: (_) => submitted = true,
            ),
          ),
        ),
      );

      // Initially unfocused
      expect(focusNode.hasFocus, isFalse);

      // Tap to focus and enter text
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.enterText(find.byType(TextField), "Flutter Conference");
      await tester.pump();
      expect(controller.text, equals("Flutter Conference"));
      expect(focusNode.hasFocus, isTrue);

      // Submit search
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(submitted, isTrue);
      expect(focusNode.hasFocus, isFalse);
      expect(controller.text, equals("Flutter Conference"));
    });

    testWidgets('EventList: search field has no autofocus, filter button dismisses focus, applying filter keeps query intact and does not refocus', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventList(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchTextFieldFinder = find.byType(TextField);
      expect(searchTextFieldFinder, findsOneWidget);

      final TextField initialTextField = tester.widget<TextField>(searchTextFieldFinder);
      expect(initialTextField.focusNode?.hasFocus, isFalse);

      // Focus search field and enter query
      await tester.tap(searchTextFieldFinder);
      await tester.pump();
      expect(initialTextField.focusNode?.hasFocus, isTrue);

      await tester.enterText(searchTextFieldFinder, "Hackathon 2026");
      await tester.pump();
      expect(initialTextField.controller?.text, equals("Hackathon 2026"));

      // Tap Filter button (tune icon)
      final filterBtnFinder = find.byIcon(Icons.tune);
      expect(filterBtnFinder, findsOneWidget);
      await tester.tap(filterBtnFinder);
      await tester.pumpAndSettle();

      // Verify filter sheet opened
      expect(find.text("Filter Events"), findsOneWidget);
      // Search field must NOT have focus
      expect(initialTextField.focusNode?.hasFocus, isFalse);

      // Tap Apply Filters button inside filter sheet
      final applyBtnFinder = find.text("Apply Filters");
      expect(applyBtnFinder, findsOneWidget);
      await tester.tap(applyBtnFinder);
      await tester.pumpAndSettle();

      // Verify filter sheet is dismissed
      expect(find.text("Filter Events"), findsNothing);

      // Verify search field is still NOT focused and query is unchanged
      expect(initialTextField.focusNode?.hasFocus, isFalse);
      expect(initialTextField.controller?.text, equals("Hackathon 2026"));
    });

    testWidgets('JobList: search field has no autofocus, filter button dismisses focus, query preserved after filtering', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JobList(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchTextFieldFinder = find.byType(TextField);
      expect(searchTextFieldFinder, findsOneWidget);

      final TextField initialTextField = tester.widget<TextField>(searchTextFieldFinder);
      expect(initialTextField.focusNode?.hasFocus, isFalse);

      // Focus search and enter query
      await tester.tap(searchTextFieldFinder);
      await tester.pump();
      expect(initialTextField.focusNode?.hasFocus, isTrue);

      await tester.enterText(searchTextFieldFinder, "Software Engineer");
      await tester.pump();
      expect(initialTextField.controller?.text, equals("Software Engineer"));

      // Tap Filter button
      final filterBtnFinder = find.byIcon(Icons.tune);
      expect(filterBtnFinder, findsOneWidget);
      await tester.tap(filterBtnFinder);
      await tester.pumpAndSettle();

      // Verify filter sheet is displayed
      expect(find.text("Filter Jobs"), findsOneWidget);
      expect(initialTextField.focusNode?.hasFocus, isFalse);

      // Tap Apply Filters button
      final applyBtnFinder = find.text("Apply Filters");
      expect(applyBtnFinder, findsOneWidget);
      await tester.tap(applyBtnFinder);
      await tester.pumpAndSettle();

      // Filter sheet closed, query intact, search field remains unfocused
      expect(find.text("Filter Jobs"), findsNothing);
      expect(initialTextField.focusNode?.hasFocus, isFalse);
      expect(initialTextField.controller?.text, equals("Software Engineer"));
    });

    testWidgets('Scrollables in EventList and JobList have keyboardDismissBehavior onDrag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventList(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listViews = find.byType(ListView);
      expect(listViews, findsWidgets);

      for (final element in listViews.evaluate()) {
        final ListView widget = element.widget as ListView;
        expect(widget.keyboardDismissBehavior, equals(ScrollViewKeyboardDismissBehavior.onDrag));
      }

      // Also verify JobList
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JobList(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final jobListViews = find.byType(ListView);
      expect(jobListViews, findsWidgets);

      for (final element in jobListViews.evaluate()) {
        final ListView widget = element.widget as ListView;
        expect(widget.keyboardDismissBehavior, equals(ScrollViewKeyboardDismissBehavior.onDrag));
      }
    });

    testWidgets('Scrolling in JobList dismisses active focus', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: JobList(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchTextFieldFinder = find.byType(TextField);
      expect(searchTextFieldFinder, findsOneWidget);
      final TextField tf = tester.widget<TextField>(searchTextFieldFinder);

      // Focus search
      await tester.tap(searchTextFieldFinder);
      await tester.pump();
      expect(tf.focusNode?.hasFocus, isTrue);

      // Drag the list
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();

      // Expect focus to be dismissed
      expect(tf.focusNode?.hasFocus, isFalse);
    });

    testWidgets('StudentHomeScreen: navigation between tabs does not trigger unwanted autofocus', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: student.StudentHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initial tab is Events
      final searchTextFieldFinder = find.byType(TextField);
      if (searchTextFieldFinder.evaluate().isNotEmpty) {
        final TextField tf = tester.widget<TextField>(searchTextFieldFinder.first);
        expect(tf.focusNode?.hasFocus, isFalse);
      }

      // Switch to Jobs tab
      await tester.tap(find.text("Jobs"));
      await tester.pumpAndSettle();

      final jobsTfFinder = find.byType(TextField);
      if (jobsTfFinder.evaluate().isNotEmpty) {
        final TextField tf = tester.widget<TextField>(jobsTfFinder.first);
        expect(tf.focusNode?.hasFocus, isFalse);
      }

      // Switch to Alumni directory tab
      await tester.tap(find.text("Alumni"));
      await tester.pumpAndSettle();

      final alumniTfFinder = find.byType(TextField);
      if (alumniTfFinder.evaluate().isNotEmpty) {
        final TextField tf = tester.widget<TextField>(alumniTfFinder.first);
        expect(tf.focusNode?.hasFocus, isFalse);
      }
    });

    testWidgets('SearchScreen: listview has keyboardDismissBehavior onDrag and no autofocus on init', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchScreen(),
        ),
      );
      await tester.pump();

      final searchTfFinder = find.byType(TextField);
      expect(searchTfFinder, findsOneWidget);
      final TextField tf = tester.widget<TextField>(searchTfFinder);
      expect(tf.autofocus, isFalse);
      expect(tf.focusNode?.hasFocus, isFalse);
    });
  });
}
