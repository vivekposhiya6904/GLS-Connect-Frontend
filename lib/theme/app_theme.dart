import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1A3A8F);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryBlue,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, brightness: Brightness.light).copyWith(
      primary: primaryBlue,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black87,
      secondary: primaryBlue,
    ),
    scaffoldBackgroundColor: Colors.white,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A3A8F),
      foregroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
    ),

    // Cards
    // Use default CardTheme to keep compatibility with the project's Flutter SDK.
    // Individual Card widgets will inherit white background and can set shape where needed.

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryBlue),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF1A3A8F),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 4,
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF1A3A8F),
      foregroundColor: Colors.white,
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
      hintStyle: const TextStyle(color: Colors.black54),
      labelStyle: const TextStyle(color: Colors.black54),
    ),

    // Dialogs
    // Keep default DialogTheme to ensure compatibility; dialogs will still use white surfaces and themed buttons.

    // ListTile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: Colors.white,
      iconColor: Color(0xFF1A3A8F),
      textColor: Colors.black87,
      selectedColor: Color(0xFF1A3A8F),
    ),

    // Icons & Progress
    iconTheme: const IconThemeData(color: primaryBlue),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primaryBlue),

    // Text
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
      titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      labelLarge: TextStyle(color: primaryBlue),
    ),
  );
}

