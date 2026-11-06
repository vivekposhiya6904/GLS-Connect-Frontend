import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/services/notification_navigation_service.dart';
import 'package:alumni_management/utils/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    NotificationNavigationService.clearActiveChat();
    NotificationNavigationService.pendingNotificationData = null;
  });

  group('NotificationNavigationService Tests', () {
    test('TC-15: Tracks active chat correctly and identifies current active chat partner', () {
      expect(NotificationNavigationService.activeChatPartnerEmail, isNull);
      expect(NotificationNavigationService.isChatActiveWith('vivek@example.com'), isFalse);

      NotificationNavigationService.setActiveChat('vivek@example.com');
      expect(NotificationNavigationService.activeChatPartnerEmail, equals('vivek@example.com'));
      expect(NotificationNavigationService.isChatActiveWith('vivek@example.com'), isTrue);
      expect(NotificationNavigationService.isChatActiveWith('VIVEK@EXAMPLE.COM'), isTrue);
      expect(NotificationNavigationService.isChatActiveWith('jay@example.com'), isFalse);

      NotificationNavigationService.clearActiveChat();
      expect(NotificationNavigationService.activeChatPartnerEmail, isNull);
      expect(NotificationNavigationService.isChatActiveWith('vivek@example.com'), isFalse);
    });

    test('TC-20: Unauthenticated user queues payload and does not navigate directly', () async {
      await StorageService.saveLoginStatus(false);
      await StorageService.clearToken();

      final payload = {
        'notificationType': 'CHAT_MESSAGE',
        'senderEmail': 'vivek@example.com',
        'senderName': 'Vivek Patel',
        'conversationId': 'jay@example.com_vivek@example.com',
      };

      await NotificationNavigationService.handleNotificationPayload(payload);

      // Verified: Navigation is deferred until user is authenticated
      expect(NotificationNavigationService.pendingNotificationData, isNotNull);
      expect(NotificationNavigationService.pendingNotificationData!['senderEmail'], equals('vivek@example.com'));
    });

    test('TC-21 & TC-22: Authenticated user queues pending payload if Navigator is not yet mounted', () async {
      await StorageService.saveLoginStatus(true);
      await StorageService.saveToken('mock_jwt_token_123');

      final payload = {
        'notificationType': 'CHAT_MESSAGE',
        'senderEmail': 'vivek@example.com',
        'senderName': 'Vivek Patel',
      };

      await NotificationNavigationService.handleNotificationPayload(payload);

      // NavigatorState is not mounted in headless unit test, so pendingNotificationData is preserved
      expect(NotificationNavigationService.pendingNotificationData, isNotNull);
      expect(NotificationNavigationService.pendingNotificationData!['senderName'], equals('Vivek Patel'));
    });

    test('TC-25: Suppresses duplicate navigation if user is already in target chat', () async {
      await StorageService.saveLoginStatus(true);
      await StorageService.saveToken('mock_jwt_token_123');
      NotificationNavigationService.setActiveChat('vivek@example.com');

      final payload = {
        'notificationType': 'CHAT_MESSAGE',
        'senderEmail': 'vivek@example.com',
        'senderName': 'Vivek Patel',
      };

      await NotificationNavigationService.handleNotificationPayload(payload);

      // Should not set pendingNotificationData because user is already actively in the chat!
      expect(NotificationNavigationService.pendingNotificationData, isNull);
    });

    test('Non-chat notification payloads are ignored safely', () async {
      final payload = {
        'notificationType': 'SYSTEM_ALERT',
        'content': 'Maintenance notice',
      };

      await NotificationNavigationService.handleNotificationPayload(payload);
      expect(NotificationNavigationService.pendingNotificationData, isNull);
    });
  });
}

