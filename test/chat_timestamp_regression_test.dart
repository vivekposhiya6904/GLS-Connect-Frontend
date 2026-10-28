import 'package:flutter_test/flutter_test.dart';
import 'package:alumni_management/models/chat_message_model.dart';
import 'package:alumni_management/models/conversation_model.dart';

void main() {
  group('Chat Timestamp & DateTime Architecture Regression Tests', () {
    test('ChatMessageModel.fromJson parses explicit UTC ISO-8601 Z string correctly', () {
      // 06:43:00 UTC corresponds to 12:13:00 in IST (+05:30)
      final json = {
        "id": "msg_001",
        "sender": "alice@glsu.edu.in",
        "receiver": "bob@glsu.edu.in",
        "content": "Meeting at 12:13",
        "timestamp": "2026-10-28T06:43:00.123Z",
        "status": "SENT"
      };

      final model = ChatMessageModel.fromJson(json);

      expect(model.id, equals("msg_001"));
      expect(model.timestamp.isUtc, isFalse, reason: "Parsed timestamp should be in local time for display");

      // Verify that the underlying instant is identical
      final expectedUtc = DateTime.parse("2026-10-28T06:43:00.123Z");
      expect(model.timestamp.toUtc(), equals(expectedUtc));
    });

    test('Timestamp parsing preserves millisecond precision without truncation', () {
      final json = {
        "id": "msg_precision",
        "sender": "alice@glsu.edu.in",
        "receiver": "bob@glsu.edu.in",
        "content": "Precision test",
        "timestamp": "2026-10-28T12:13:45.678Z",
        "status": "SENT"
      };

      final model = ChatMessageModel.fromJson(json);
      expect(model.timestamp.toUtc().millisecond, equals(678));
    });

    test('Timestamp parsing handles numeric epoch millisecond timestamps', () {
      final epochMillis = DateTime.utc(2026, 10, 28, 6, 43, 0).millisecondsSinceEpoch;
      final json = {
        "id": "msg_epoch",
        "sender": "alice@glsu.edu.in",
        "receiver": "bob@glsu.edu.in",
        "content": "Epoch test",
        "timestamp": epochMillis,
        "status": "SENT"
      };

      final model = ChatMessageModel.fromJson(json);
      expect(model.timestamp.toUtc(), equals(DateTime.utc(2026, 10, 28, 6, 43, 0)));
    });

    test('ConversationModel.fromJson parses conversation lastMessageAt consistently', () {
      final json = {
        "conversationId": "alice@glsu.edu.in_bob@glsu.edu.in",
        "sender": "alice@glsu.edu.in",
        "receiver": "bob@glsu.edu.in",
        "content": "Latest conversation update",
        "timestamp": "2026-10-28T06:43:00.000Z",
        "status": "DELIVERED",
        "unreadCount": 0
      };

      final conv = ConversationModel.fromJson(json, "bob@glsu.edu.in");
      expect(conv.lastMessageAt.toUtc(), equals(DateTime.parse("2026-10-28T06:43:00.000Z")));
      expect(conv.lastMessage, equals("Latest conversation update"));
      expect(conv.lastMessageStatus, equals(MessageStatus.delivered));
    });

    test('Authoritative server message reconciles optimistic temp message without time offset regression', () {
      // 1. Optimistic message created locally on mobile device at 12:13:05 local
      final localSendTime = DateTime(2026, 10, 28, 12, 13, 5);
      final tempId = "temp_${localSendTime.millisecondsSinceEpoch}";

      final optimisticMsg = ChatMessageModel(
        id: tempId,
        clientMessageId: tempId,
        sender: "alice@glsu.edu.in",
        receiver: "bob@glsu.edu.in",
        content: "Hello Bob",
        status: MessageStatus.sent,
        timestamp: localSendTime,
      );

      final List<ChatMessageModel> messageList = [optimisticMsg];

      // 2. Confirmed server message returns with authoritative instant matching 12:13:05 local
      // (assuming +05:30 offset, 12:13:05 local == 06:43:05 UTC)
      final authoritativeUtc = localSendTime.toUtc();
      final serverConfirmedJson = {
        "id": "mongo_id_654321",
        "clientMessageId": tempId,
        "conversationId": "alice@glsu.edu.in_bob@glsu.edu.in",
        "sender": "alice@glsu.edu.in",
        "receiver": "bob@glsu.edu.in",
        "content": "Hello Bob",
        "type": "TEXT",
        "status": "SENT",
        "timestamp": authoritativeUtc.toIso8601String(),
      };

      final confirmedMsg = ChatMessageModel.fromJson(serverConfirmedJson);

      // 3. Reconcile by clientMessageId or tempId
      final tempIdx = messageList.indexWhere(
        (m) =>
            (confirmedMsg.clientMessageId != null &&
                confirmedMsg.clientMessageId!.isNotEmpty &&
                (m.clientMessageId == confirmedMsg.clientMessageId || m.id == confirmedMsg.clientMessageId)) ||
            (m.id != null &&
                m.id!.startsWith("temp_") &&
                m.sender == confirmedMsg.sender &&
                m.content == confirmedMsg.content),
      );

      expect(tempIdx, equals(0));
      messageList[tempIdx] = confirmedMsg;

      // 4. Assert final reconciled message displays the same 12:13 minute, NOT shifted to 12:12
      final displayed = messageList[0];
      expect(displayed.id, equals("mongo_id_654321"));
      expect(displayed.timestamp.hour, equals(localSendTime.hour));
      expect(displayed.timestamp.minute, equals(localSendTime.minute));
    });
  });
}
