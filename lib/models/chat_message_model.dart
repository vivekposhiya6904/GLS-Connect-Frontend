enum MessageStatus {
  sent,
  delivered,
  read,
}

enum MessageType {
  text,
  image,
  video,
  audio,
  document,
}

class ChatMessageModel {
  final String? id;
  final String? conversationId;
  final String sender;
  final String receiver;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;

  ChatMessageModel({
    this.id,
    this.conversationId,
    required this.sender,
    required this.receiver,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    MessageStatus parseStatus(dynamic statusStr) {
      if (statusStr == "READ" || json["read"] == true || json["isRead"] == true) {
        return MessageStatus.read;
      } else if (statusStr == "DELIVERED") {
        return MessageStatus.delivered;
      }
      return MessageStatus.sent;
    }

    MessageType parseType(dynamic typeStr) {
      if (typeStr == "IMAGE") return MessageType.image;
      if (typeStr == "VIDEO") return MessageType.video;
      if (typeStr == "AUDIO") return MessageType.audio;
      if (typeStr == "DOCUMENT") return MessageType.document;
      return MessageType.text;
    }

    DateTime parseTimestamp(dynamic ts) {
      if (ts == null) return DateTime.now();
      try {
        return DateTime.parse(ts.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return ChatMessageModel(
      id: json["id"]?.toString(),
      conversationId: json["conversationId"]?.toString(),
      sender: (json["sender"]?.toString() ?? "").trim().toLowerCase(),
      receiver: (json["receiver"]?.toString() ?? "").trim().toLowerCase(),
      content: json["content"]?.toString() ?? "",
      type: parseType(json["type"]),
      status: parseStatus(json["status"]),
      timestamp: parseTimestamp(json["timestamp"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      if (conversationId != null) "conversationId": conversationId,
      "sender": sender,
      "receiver": receiver,
      "content": content,
      "type": type.name.toUpperCase(),
      "status": status.name.toUpperCase(),
      "timestamp": timestamp.toIso8601String(),
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    String? sender,
    String? receiver,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
