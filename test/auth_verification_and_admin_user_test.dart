import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/screens/auth/email_verification_screen.dart';
import 'package:alumni_management/screens/auth/login_screen.dart';
import 'package:alumni_management/screens/auth/forgot_password_screen.dart';
import 'package:alumni_management/screens/dashboard/admin_home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'userRole': 'ADMIN',
      'userName': 'Admin User',
      'user_email': 'admin@alumni.com',
      'auth_token': 'dummy_jwt_token',
    });
  });

  group('A. Admin Add User Form & Lifecycle Tests', () {
    testWidgets('Add User button opens dialog and validates required fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Users tab
      final usersTabFinder = find.text('Users');
      expect(usersTabFinder, findsOneWidget);
      await tester.tap(usersTabFinder);
      await tester.pumpAndSettle();

      // Find "Add User" button
      final addUserBtn = find.text('Add User');
      expect(addUserBtn, findsOneWidget);
      await tester.tap(addUserBtn);
      await tester.pumpAndSettle();

      // Verify Dialog is open
      expect(find.text('Add New User'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Tap "Create User" with empty fields to trigger client-side validation
      final createBtn = find.widgetWithText(ElevatedButton, 'Create User');
      expect(createBtn, findsOneWidget);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Verify validation error messages
      expect(find.text('Please enter full name'), findsOneWidget);

      // Enter name only
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.tap(createBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter email address'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'notanemail');
      await tester.tap(createBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email'), findsOneWidget);

      // Enter short password
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'john@gls.edu.in');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '123');
      await tester.tap(createBtn);
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Cancel button cleanly dismisses dialog without asserting or crashing
      final cancelBtn = find.text('Cancel');
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();
      expect(find.text('Add New User'), findsNothing);
    });
  });

  group('B. Email Verification Screen Tests', () {
    testWidgets('EmailVerificationScreen renders email, cooldown, and handles invalid OTP', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmailVerificationScreen(
            email: 'unverified.user@gls.edu.in',
            purpose: 'ACCOUNT_ACTIVATION',
            initialCooldownSeconds: 45,
            otpDispatched: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify email is rendered
      expect(find.textContaining('unverified.user@gls.edu.in'), findsOneWidget);
      expect(find.text('Check Your Inbox'), findsOneWidget);

      // Verify cooldown button displays remaining time
      expect(find.textContaining('Resend in 45s'), findsOneWidget);

      // Tap Verify with empty OTP
      final verifyButton = find.widgetWithText(ElevatedButton, 'Verify Code');
      expect(verifyButton, findsOneWidget);
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();

      // Verify validation warning
      expect(find.text('Please enter the complete 6-digit code'), findsOneWidget);
    });

    testWidgets('EmailVerificationScreen displays alert banner when OTP dispatch initially failed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmailVerificationScreen(
            email: 'service.unavailable@gls.edu.in',
            purpose: 'ACCOUNT_ACTIVATION',
            initialCooldownSeconds: 0,
            otpDispatched: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify failure banner is visible
      expect(find.textContaining('If you already received a code recently'), findsOneWidget);
      expect(find.text('Resend Code'), findsOneWidget);
    });
  });

  group('C. Forgot Password Flow Integrity Tests', () {
    testWidgets('ForgotPasswordScreen renders reset instructions and validates email format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Forgot Your Password?'), findsOneWidget);

      // Submit with empty email
      final sendOtpBtn = find.widgetWithText(ElevatedButton, 'Send OTP');
      expect(sendOtpBtn, findsOneWidget);
      await tester.tap(sendOtpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your registered email'), findsOneWidget);
    });
  });

  group('D. Login Screen Architecture Tests', () {
    testWidgets('LoginScreen renders email and password fields without confirmation dialogs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Sign in — we'll take you to the right place"), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}

