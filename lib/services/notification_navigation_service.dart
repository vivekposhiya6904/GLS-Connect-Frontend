import 'package:flutter/material.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../utils/storage_service.dart';

class NotificationNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Currently open chat partner email (to avoid duplicate notifications and screens)
  static String? activeChatPartnerEmail;

  /// Holds payload if notification was tapped before navigator or session was ready
  static Map<String, dynamic>? pendingNotificationData;

  /// Set the active chat partner when entering ChatDetailScreen
  static void setActiveChat(String? email) {
    activeChatPartnerEmail = email?.trim().toLowerCase();
    debugPrint("📱 Active chat set to: $activeChatPartnerEmail");
  }

  /// Clear the active chat partner when leaving ChatDetailScreen
  static void clearActiveChat() {
    debugPrint("📱 Active chat cleared (was: $activeChatPartnerEmail)");
    activeChatPartnerEmail = null;
  }

  /// Determines if a chat with given partner is currently being viewed
  static bool isChatActiveWith(String? email) {
    if (email == null || activeChatPartnerEmail == null) return false;
    return activeChatPartnerEmail == email.trim().toLowerCase();
  }

  /// Centralized notification payload routing
  static Future<void> handleNotificationPayload(
      Map<String, dynamic> data) async {
    debugPrint("🔥 NOTIFICATION NAVIGATION FUNCTION CALLED");
    debugPrint("🔥 NAVIGATOR STATE: ${navigatorKey.currentState}");

    final notificationType = data['notificationType']?.toString();
    if (notificationType != 'CHAT_MESSAGE') {
      debugPrint("ℹ️ Non-chat notification type: $notificationType");
      return;
    }

    final senderEmail =
        data['senderEmail']?.toString().trim().toLowerCase() ?? '';
    final senderName = data['senderName']?.toString().trim() ??
        data['title']?.toString().trim() ??
        senderEmail;

    if (senderEmail.isEmpty) {
      debugPrint("⚠️ Cannot navigate: senderEmail is empty in payload");
      return;
    }

    final isLoggedIn = await StorageService.getLoginStatus();
    final token = await StorageService.getToken();

    if (!isLoggedIn || token == null || token.trim().isEmpty) {
      debugPrint("🔒 User not logged in, queueing notification navigation for after authentication");
      pendingNotificationData = data;
      return;
    }

    // If user is already on the exact conversation, do not push duplicate screen
    if (isChatActiveWith(senderEmail)) {
      debugPrint("👀 Conversation already active with $senderEmail, skipping duplicate push");
      return;
    }

    final navState = navigatorKey.currentState;
    if (navState == null) {
      debugPrint("⏳ NavigatorState not ready yet, saving pending notification payload");
      pendingNotificationData = data;
      return;
    }

    debugPrint("🚀 Navigating directly to chat with $senderName ($senderEmail)");
    navState.push(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          name: senderName,
          receiverEmail: senderEmail,
        ),
      ),
    );
  }

  /// Process any pending notification tap after app finishes loading/authenticating
  static void processPendingNavigation() {
    if (pendingNotificationData != null) {
      final data = pendingNotificationData!;
      pendingNotificationData = null;
      debugPrint("📬 Processing deferred notification navigation: $data");
      handleNotificationPayload(data);
    }
  }
}

