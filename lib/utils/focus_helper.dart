import 'package:flutter/material.dart';

/// Centralized, production-grade focus and keyboard management utility
/// for GLS Connect.
class AppFocusHelper {
  AppFocusHelper._();

  /// Safely dismisses the active keyboard and removes focus from the active text field.
  /// If [context] is provided, attempts to unfocus via [FocusScope.of(context)]
  /// if it has focus, and falls back to [FocusManager.instance.primaryFocus?.unfocus()].
  static void unfocus([BuildContext? context]) {
    if (context != null) {
      final currentScope = FocusScope.of(context);
      if (currentScope.hasFocus) {
        currentScope.unfocus();
        return;
      }
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
