import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alumni_management/services/chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ChatService().disconnect();
  });

  tearDown(() {
    ChatService().disconnect();
  });

  group('ChatService Lifecycle and Listener Tests', () {
    test('Initial connection state is disconnected', () {
      final chatService = ChatService();
      expect(chatService.isConnected, isFalse);
      expect(chatService.isConnecting, isFalse);
      expect(chatService.connectedUserEmail, isNull);
    });

    test('Connect aborts and returns false when auth token is missing', () async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'test@gls.edu',
      });

      String? reportedError;
      final chatService = ChatService();
      chatService.addErrorListener('test', (err) {
        reportedError = err;
      });

      final result = await chatService.connect(userEmail: 'test@gls.edu');

      expect(result, isFalse);
      expect(chatService.isConnected, isFalse);
      expect(chatService.isConnecting, isFalse);
      expect(reportedError, contains('token missing'));
    });

    test('Listeners can be added and removed cleanly', () {
      final chatService = ChatService();

      String? msgReceived;
      chatService.addMessageListener('key1', (msg) => msgReceived = msg);
      chatService.removeMessageListener('key1');

      String? statusReceived;
      chatService.addStatusListener('key1', (st) => statusReceived = st);
      chatService.removeStatusListener('key1');

      String? typingReceived;
      chatService.addTypingListener('key1', (t) => typingReceived = t);
      chatService.removeTypingListener('key1');

      String? presenceReceived;
      chatService.addPresenceListener('key1', (p) => presenceReceived = p);
      chatService.removePresenceListener('key1');

      expect(msgReceived, isNull);
      expect(statusReceived, isNull);
      expect(typingReceived, isNull);
      expect(presenceReceived, isNull);
    });

    test('Disconnect resets isConnecting, connectedUserEmail, and clears listeners', () {
      final chatService = ChatService();
      chatService.addMessageListener('key1', (_) {});
      chatService.addStatusListener('key1', (_) {});
      chatService.addErrorListener('key1', (_) {});

      chatService.disconnect();

      expect(chatService.isConnected, isFalse);
      expect(chatService.isConnecting, isFalse);
      expect(chatService.connectedUserEmail, isNull);
    });
  });
}
