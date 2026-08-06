import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/chat_service.dart';
import '../../services/encryption_service.dart';
import '../../utils/storage_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String receiverEmail;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.receiverEmail,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  final ChatService _chatService = ChatService();
  Timer? _pollTimer;

  String? myEmail;
  String? token;
  late String targetEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    targetEmail = widget.receiverEmail.trim().toLowerCase();
    initChat();
  }

  Future<void> initChat() async {
    final rawEmail = await StorageService.getUserEmail();
    myEmail = rawEmail?.trim().toLowerCase();
    token = await StorageService.getToken();

    if (myEmail == null || token == null || targetEmail.isEmpty) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    await loadChatHistory();

    // 1. Real-Time WebSocket Listener
    _chatService.connect(
      userEmail: myEmail!,
      onMessageReceived: (message) {
        try {
          final decoded = jsonDecode(message);
          final sender = (decoded["sender"]?.toString() ?? "").trim().toLowerCase();
          final receiver = (decoded["receiver"]?.toString() ?? "").trim().toLowerCase();

          if ((sender == targetEmail && receiver == myEmail) ||
              (sender == myEmail && receiver == targetEmail)) {

            final rawContent = decoded["content"] ?? "";
            final decryptedText = EncryptionService.decrypt(rawContent, myEmail!, targetEmail);

            _addOrUpdateMessage({
              "id": decoded["id"]?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              "text": decryptedText,
              "isMe": sender == myEmail,
              "timestamp": decoded["timestamp"],
            });
          }
        } catch (_) {}
      },
    );

    // 2. High-Frequency Auto-Sync Poll Timer (every 1.5 seconds)
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) loadChatHistory(silent: true);
    });

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addOrUpdateMessage(Map<String, dynamic> msg) {
    if (!mounted) return;
    setState(() {
      int existingIdx = messages.indexWhere((m) =>
          (m["id"] == msg["id"] && m["id"] != null && m["id"].toString().isNotEmpty) ||
          (m["text"] == msg["text"] && m["isMe"] == msg["isMe"]));

      if (existingIdx >= 0) {
        messages[existingIdx] = msg;
      } else {
        messages.add(msg);
      }
    });
  }

  Future<void> loadChatHistory({bool silent = false}) async {
    if (token == null || myEmail == null || targetEmail.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/chat/history/$targetEmail"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final loaded = data.map((msg) {
          final rawContent = msg["content"] ?? "";
          final decryptedText = EncryptionService.decrypt(rawContent, myEmail!, targetEmail);
          final sender = (msg["sender"]?.toString() ?? "").trim().toLowerCase();

          return {
            "id": msg["id"]?.toString() ?? "",
            "text": decryptedText,
            "isMe": sender == myEmail,
            "timestamp": msg["timestamp"],
          };
        }).toList();

        if (mounted) {
          setState(() {
            for (var newMsg in loaded) {
              int existingIdx = messages.indexWhere((m) =>
                  (m["id"] == newMsg["id"] && newMsg["id"].toString().isNotEmpty) ||
                  (m["text"] == newMsg["text"] && m["isMe"] == newMsg["isMe"]));

              if (existingIdx >= 0) {
                messages[existingIdx] = newMsg;
              } else {
                messages.add(newMsg);
              }
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || myEmail == null || token == null || targetEmail.isEmpty) return;

    controller.clear();

    final tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";
    final encryptedContent = EncryptionService.encrypt(text, myEmail!, targetEmail);

    final localMsg = {
      "id": tempId,
      "text": text,
      "isMe": true,
      "timestamp": DateTime.now().toIso8601String(),
    };

    // Optimistically render message locally
    setState(() {
      messages.add(localMsg);
    });

    // 1. Send via HTTP REST API
    try {
      await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/chat/send"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "sender": myEmail,
          "receiver": targetEmail,
          "content": encryptedContent,
        }),
      );
    } catch (_) {}

    // 2. Send via WebSocket if connected
    if (_chatService.isConnected) {
      _chatService.sendMessage(
        receiver: targetEmail,
        content: encryptedContent,
      );
    }

    // Refresh history immediately after sending
    Future.delayed(const Duration(milliseconds: 300), () => loadChatHistory(silent: true));
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return "";
    try {
      final dt = DateTime.parse(ts.toString());
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute $period";
    } catch (_) {
      return "";
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    controller.dispose();
    _chatService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
            Row(
              children: [
                const Icon(Icons.lock_rounded, size: 10, color: Colors.greenAccent),
                const SizedBox(width: 4),
                Text("End-to-End Encrypted", style: TextStyle(fontSize: 11, color: Colors.greenAccent.shade100)),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A3A8F),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A8F)))
                : messages.isEmpty
                    ? Center(
                        child: Text(
                          "No messages yet. Say hello!",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg["isMe"] == true;
                          final timeStr = _formatTime(msg["timestamp"]);

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF1A3A8F) : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: Radius.circular(isMe ? 14 : 2),
                                  bottomRight: Radius.circular(isMe ? 2 : 14),
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg["text"] ?? "",
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 14.5,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (timeStr.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: isMe ? Colors.white70 : Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Type an encrypted message...",
                        filled: true,
                        fillColor: const Color(0xFFF4F7FF),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1A3A8F),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
