import 'chat_message_model.dart';

class ConversationModel {
  final String id;
  final String otherUserEmail;
  final String? otherUserName;
  final String lastMessage;
  final MessageStatus lastMessageStatus;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  ConversationModel({
    required this.id,
    required this.otherUserEmail,
    this.otherUserName,
    required this.lastMessage,
    required this.lastMessageStatus,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, String myEmail) {
    final sender = (json["sender"]?.toString() ?? "").trim().toLowerCase();
    final receiver = (json["receiver"]?.toString() ?? "").trim().toLowerCase();
    final otherUser = sender == myEmail.toLowerCase() ? receiver : sender;

    MessageStatus parseStatus(dynamic statusStr) {
      if (statusStr == "READ" || json["read"] == true || json["isRead"] == true) {
        return MessageStatus.read;
      } else if (statusStr == "DELIVERED") {
        return MessageStatus.delivered;
      }
      return MessageStatus.sent;
    }

    DateTime parseTimestamp(dynamic ts) {
      if (ts == null) return DateTime.now();
      try {
        return DateTime.parse(ts.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return ConversationModel(
      id: json["conversationId"]?.toString() ?? "${sender}_$receiver",
      otherUserEmail: otherUser,
      lastMessage: json["content"]?.toString() ?? "",
      lastMessageStatus: parseStatus(json["status"]),
      lastMessageAt: parseTimestamp(json["timestamp"]),
      unreadCount: json["unreadCount"] is int ? json["unreadCount"] : 0,
    );
  }
}
