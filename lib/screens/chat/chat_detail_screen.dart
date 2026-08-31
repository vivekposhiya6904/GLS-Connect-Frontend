import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';
import '../../services/encryption_service.dart';
import '../../utils/storage_service.dart';
import '../../widgets/chat_avatar.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_indicator.dart';

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
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> messages = [];
  final ChatService _chatService = ChatService();

  String? myEmail;
  String? token;
  late String targetEmail;
  bool isLoading = true;
  bool isSending = false;
  bool _showScrollToBottom = false;
  bool _hasTypedText = false;

  bool isTargetOnline = false;
  bool isTargetTyping = false;
  Timer? _typingDebounceTimer;
  Timer? _typingAutoResetTimer;

  @override
  void initState() {
    super.initState();
    targetEmail = widget.receiverEmail.trim().toLowerCase();
    _scrollController.addListener(_handleScroll);
    _textController.addListener(_handleTextChange);
    initChat();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final isFarFromBottom = (maxScroll - currentScroll) > 250;

    if (isFarFromBottom != _showScrollToBottom && mounted) {
      setState(() {
        _showScrollToBottom = isFarFromBottom;
      });
    }
  }

  void _handleTextChange() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasTypedText && mounted) {
      setState(() {
        _hasTypedText = hasText;
      });
    }
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
    await _checkPresence();
    await _markAsRead();

    // Register WebSocket Listeners for Chat Detail
    _chatService.addMessageListener("chat_detail", _handleIncomingMessage);
    _chatService.addStatusListener("chat_detail", _handleStatusUpdate);
    _chatService.addTypingListener("chat_detail", _handleTypingEvent);
    _chatService.addPresenceListener("chat_detail", _handlePresenceEvent);

    await _chatService.connect(userEmail: myEmail!);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
      _scrollToBottom(animate: false);
    }
  }

  void _handleIncomingMessage(String messageJson) {
    try {
      final decoded = jsonDecode(messageJson);
      final msgModel = ChatMessageModel.fromJson(decoded);
      final sender = msgModel.sender;
      final receiver = msgModel.receiver;

      if ((sender == targetEmail && receiver == myEmail) ||
          (sender == myEmail && receiver == targetEmail)) {
        final rawContent = decoded["content"] ?? "";
        final decryptedText =
            EncryptionService.decrypt(rawContent, myEmail!, targetEmail);

        final finalMsg = msgModel.copyWith(content: decryptedText);
        debugPrint("📱 CHAT SCREEN RECEIVED MESSAGE: sender=$sender, receiver=$receiver, content=$decryptedText");

        _addOrUpdateMessage(finalMsg);

        // Automatically mark incoming messages as read when viewing conversation
        if (sender == targetEmail) {
          _markAsRead();
        }
      }
    } catch (_) {}
  }

  void _handleStatusUpdate(String statusJson) {
    try {
      final decoded = jsonDecode(statusJson);
      final msgId = decoded["messageId"]?.toString();
      final statusStr = decoded["status"]?.toString();

      if (msgId != null && statusStr != null) {
        MessageStatus newStatus = MessageStatus.sent;
        if (statusStr == "READ") newStatus = MessageStatus.read;
        if (statusStr == "DELIVERED") newStatus = MessageStatus.delivered;

        if (mounted) {
          setState(() {
            final idx = messages.indexWhere((m) => m.id == msgId);
            if (idx >= 0) {
              messages[idx] = messages[idx].copyWith(status: newStatus);
            }
          });
        }
      }
    } catch (_) {}
  }

  void _handleTypingEvent(String typingJson) {
    try {
      final decoded = jsonDecode(typingJson);
      final sender = (decoded["sender"]?.toString() ?? "").trim().toLowerCase();
      final isTyping = decoded["isTyping"] == true;

      if (sender == targetEmail && mounted) {
        _typingAutoResetTimer?.cancel();
        setState(() {
          isTargetTyping = isTyping;
        });

        if (isTyping) {
          _typingAutoResetTimer = Timer(const Duration(milliseconds: 3500), () {
            if (mounted) {
              setState(() {
                isTargetTyping = false;
              });
            }
          });
        }
      }
    } catch (_) {}
  }

  void _handlePresenceEvent(String presenceJson) {
    try {
      final decoded = jsonDecode(presenceJson);
      final email = (decoded["userEmail"]?.toString() ?? "").trim().toLowerCase();
      final status = decoded["status"]?.toString();

      if (email == targetEmail && mounted) {
        setState(() {
          isTargetOnline = status == "ONLINE";
        });
      }
    } catch (_) {}
  }

  Future<void> _checkPresence() async {
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/chat/presence/$targetEmail"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            isTargetOnline = data["online"] == true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _markAsRead() async {
    if (token == null || myEmail == null) return;
    try {
      await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/chat/mark-read/$targetEmail"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
    } catch (_) {}
  }

  void _addOrUpdateMessage(ChatMessageModel msg) {
    if (!mounted) return;
    setState(() {
      // 1. Check by exact message ID
      if (msg.id != null && msg.id!.isNotEmpty && !msg.id!.startsWith("temp_")) {
        final exactIdx = messages.indexWhere((m) => m.id == msg.id);
        if (exactIdx >= 0) {
          messages[exactIdx] = msg;
          _scrollToBottom();
          return;
        }

        // 2. Reconcile with pending optimistic temp message
        final tempIdx = messages.indexWhere((m) =>
            m.id != null &&
            m.id!.startsWith("temp_") &&
            m.sender == msg.sender &&
            m.content == msg.content);
        if (tempIdx >= 0) {
          messages[tempIdx] = msg;
          _scrollToBottom();
          return;
        }
      }

      // 3. Otherwise, append as new message
      messages.add(msg);
    });
    _scrollToBottom();
  }

  Future<void> loadChatHistory() async {
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
        final loaded = data.map((item) {
          final model = ChatMessageModel.fromJson(item);
          final rawContent = item["content"] ?? "";
          final decryptedText =
              EncryptionService.decrypt(rawContent, myEmail!, targetEmail);
          return model.copyWith(content: decryptedText);
        }).toList();

        if (mounted) {
          setState(() {
            messages.clear();
            messages.addAll(loaded);
          });
          _scrollToBottom(animate: false);
        }
      }
    } catch (_) {}
  }

  void _onTextChanged(String text) {
    if (myEmail == null) return;

    if (_typingDebounceTimer?.isActive ?? false) {
      _typingDebounceTimer!.cancel();
    } else {
      _chatService.sendTyping(receiver: targetEmail, isTyping: true);
    }

    _typingDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _chatService.sendTyping(receiver: targetEmail, isTyping: false);
    });
  }

  Future<void> sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty ||
        myEmail == null ||
        token == null ||
        targetEmail.isEmpty ||
        isSending) {
      return;
    }

    isSending = true;
    _textController.clear();
    _typingDebounceTimer?.cancel();
    _chatService.sendTyping(receiver: targetEmail, isTyping: false);

    final encryptedContent =
        EncryptionService.encrypt(text, myEmail!, targetEmail);
    final tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";

    final localMsg = ChatMessageModel(
      id: tempId,
      sender: myEmail!,
      receiver: targetEmail,
      content: text,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    // Optimistically render locally
    _addOrUpdateMessage(localMsg);

    // 1. Send via WebSocket if connected
    if (_chatService.isConnected) {
      _chatService.sendMessage(
        receiver: targetEmail,
        content: encryptedContent,
      );
      isSending = false;
    } else {
      // 2. Fallback to HTTP REST
      try {
        await http.post(
          Uri.parse("${ApiConfig.baseUrl}/api/chat/send"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "receiver": targetEmail,
            "content": encryptedContent,
          }),
        );
      } catch (_) {}
      isSending = false;
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  void dispose() {
    _chatService.removeMessageListener("chat_detail");
    _chatService.removeStatusListener("chat_detail");
    _chatService.removeTypingListener("chat_detail");
    _chatService.removePresenceListener("chat_detail");
    _typingDebounceTimer?.cancel();
    _typingAutoResetTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _textController.removeListener(_handleTextChange);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSubtitle() {
    if (isTargetTyping) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "typing",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6EE7B7),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 3),
          TypingIndicator(dotColor: Color(0xFF6EE7B7), dotSize: 3.5),
        ],
      );
    } else if (isTargetOnline) {
      return const Text(
        "Online",
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF6EE7B7),
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      return const Text(
        "Offline",
        style: TextStyle(
          fontSize: 12,
          color: Colors.white70,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final composerBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            ChatAvatar(
              name: widget.name,
              radius: 19,
              isOnline: isTargetOnline,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  _buildSubtitle(),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                          strokeWidth: 3,
                        ),
                      )
                    : messages.isEmpty
                        ? _buildEmptyConversationState(primaryColor)
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe = msg.sender.toLowerCase() == myEmail;
                              return MessageBubble(
                                message: msg,
                                isMe: isMe,
                              );
                            },
                          ),
              ),
              _buildMessageComposer(composerBg, inputBg, isDark, primaryColor),
            ],
          ),
          if (_showScrollToBottom)
            Positioned(
              right: 16,
              bottom: 80,
              child: FloatingActionButton.small(
                onPressed: () => _scrollToBottom(animate: true),
                backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                foregroundColor: primaryColor,
                elevation: 3,
                child: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyConversationState(Color primaryColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.waving_hand_rounded,
                size: 36,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Say hello to ${widget.name}!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Start the conversation by sending a friendly greeting below.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer(
      Color composerBg, Color inputBg, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: composerBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onChanged: _onTextChanged,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Message...",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                            fontSize: 15,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasTypedText ? primaryColor : Colors.grey.shade400,
                shape: BoxShape.circle,
                boxShadow: _hasTypedText
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _hasTypedText ? sendMessage : null,
                tooltip: "Send message",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
