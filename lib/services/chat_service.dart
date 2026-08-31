import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/api_config.dart';
import '../utils/storage_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  StompClient? _stompClient;
  bool _isConnecting = false;
  String? _connectedUserEmail;

  final Map<String, Function(String messageJson)> _messageListeners = {};
  final Map<String, Function(String statusJson)> _statusListeners = {};
  final Map<String, Function(String typingJson)> _typingListeners = {};
  final Map<String, Function(String presenceJson)> _presenceListeners = {};
  final Map<String, Function(String error)> _errorListeners = {};

  void addMessageListener(String key, Function(String messageJson) callback) {
    _messageListeners[key] = callback;
  }

  void removeMessageListener(String key) {
    _messageListeners.remove(key);
  }

  void addStatusListener(String key, Function(String statusJson) callback) {
    _statusListeners[key] = callback;
  }

  void removeStatusListener(String key) {
    _statusListeners.remove(key);
  }

  void addTypingListener(String key, Function(String typingJson) callback) {
    _typingListeners[key] = callback;
  }

  void removeTypingListener(String key) {
    _typingListeners.remove(key);
  }

  void addPresenceListener(String key, Function(String presenceJson) callback) {
    _presenceListeners[key] = callback;
  }

  void removePresenceListener(String key) {
    _presenceListeners.remove(key);
  }

  void addErrorListener(String key, Function(String error) callback) {
    _errorListeners[key] = callback;
  }

  void removeErrorListener(String key) {
    _errorListeners.remove(key);
  }

  Future<void> connect({
    required String userEmail,
    Function(String messageJson)? onMessageReceived,
    Function(String statusJson)? onStatusUpdated,
    Function(String typingJson)? onTypingReceived,
    Function(String presenceJson)? onPresenceReceived,
    Function(String error)? onError,
  }) async {
    if (onMessageReceived != null) addMessageListener("default", onMessageReceived);
    if (onStatusUpdated != null) addStatusListener("default", onStatusUpdated);
    if (onTypingReceived != null) addTypingListener("default", onTypingReceived);
    if (onPresenceReceived != null) addPresenceListener("default", onPresenceReceived);
    if (onError != null) addErrorListener("default", onError);

    final normalizedEmail = userEmail.trim().toLowerCase();

    // If already connected for a DIFFERENT user, disconnect first
    if (_stompClient != null && _stompClient!.connected) {
      if (_connectedUserEmail != null && _connectedUserEmail != normalizedEmail) {
        debugPrint("🔄 User switch detected ($_connectedUserEmail -> $normalizedEmail), reconnecting STOMP...");
        disconnect();
      } else {
        return;
      }
    }

    if (_isConnecting) return;
    _isConnecting = true;

    final token = await StorageService.getToken();
    if (token == null) {
      debugPrint("❌ STOMP connect aborted: Authentication token missing");
      _notifyError("Authentication token missing");
      _isConnecting = false;
      return;
    }

    debugPrint("🔐 Connecting to WebSocket STOMP for user: $normalizedEmail");

    try {
      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: "${ApiConfig.baseUrl}/chat",
          heartbeatIncoming: const Duration(seconds: 10),
          heartbeatOutgoing: const Duration(seconds: 10),
          reconnectDelay: const Duration(seconds: 4),

          stompConnectHeaders: {
            "Authorization": "Bearer $token",
          },
          webSocketConnectHeaders: {
            "Authorization": "Bearer $token",
          },

          onConnect: (StompFrame frame) {
            _isConnecting = false;
            _connectedUserEmail = normalizedEmail;
            debugPrint("✅ STOMP CONNECTED for user: $normalizedEmail");
            _subscribe();
          },

          onWebSocketError: (error) {
            debugPrint("❌ WebSocket error: $error");
            _isConnecting = false;
            _notifyError("WebSocket error: $error");
          },

          onDisconnect: (frame) {
            debugPrint("🔴 STOMP Disconnected");
            _isConnecting = false;
          },

          onStompError: (frame) {
            debugPrint("❌ STOMP error: ${frame.body}");
            _notifyError("STOMP error: ${frame.body}");
          },
        ),
      );

      _stompClient!.activate();
    } catch (e) {
      debugPrint("❌ STOMP Connection exception: $e");
      _isConnecting = false;
      _notifyError("Connection exception: $e");
    }
  }

  void _notifyError(String error) {
    for (final listener in _errorListeners.values) {
      try {
        listener(error);
      } catch (_) {}
    }
  }

  void _subscribe() {
    if (_stompClient == null || !_stompClient!.connected) return;

    debugPrint("👂 RECEIVER SUBSCRIBED: user=$_connectedUserEmail, destination=/user/queue/messages");

    // 1. Subscribe to incoming chat messages
    _stompClient!.subscribe(
      destination: "/user/queue/messages",
      callback: (frame) {
        if (frame.body != null) {
          debugPrint("📨 RECEIVED MESSAGE on /user/queue/messages: body=${frame.body}");
          for (final listener in List.of(_messageListeners.values)) {
            try {
              listener(frame.body!);
            } catch (e) {
              debugPrint("Error in message listener: $e");
            }
          }
        }
      },
    );

    // 2. Subscribe to message status updates (e.g. SENT -> DELIVERED -> READ)
    _stompClient!.subscribe(
      destination: "/user/queue/status",
      callback: (frame) {
        if (frame.body != null) {
          debugPrint("✓✓ Received Status Update: ${frame.body}");
          for (final listener in List.of(_statusListeners.values)) {
            try {
              listener(frame.body!);
            } catch (e) {
              debugPrint("Error in status listener: $e");
            }
          }
        }
      },
    );

    // 3. Subscribe to typing events
    _stompClient!.subscribe(
      destination: "/user/queue/typing",
      callback: (frame) {
        if (frame.body != null) {
          for (final listener in List.of(_typingListeners.values)) {
            try {
              listener(frame.body!);
            } catch (e) {
              debugPrint("Error in typing listener: $e");
            }
          }
        }
      },
    );

    // 4. Subscribe to presence events (online/offline updates)
    _stompClient!.subscribe(
      destination: "/topic/presence",
      callback: (frame) {
        if (frame.body != null) {
          for (final listener in List.of(_presenceListeners.values)) {
            try {
              listener(frame.body!);
            } catch (e) {
              debugPrint("Error in presence listener: $e");
            }
          }
        }
      },
    );
  }

  void sendMessage({
    required String receiver,
    required String content,
  }) {
    if (_stompClient == null || !_stompClient!.connected) {
      debugPrint("❌ ChatService.sendMessage failed: Not connected to WebSocket server");
      _notifyError("Not connected to WebSocket server");
      return;
    }

    final targetReceiver = receiver.trim().toLowerCase();
    final payload = {
      "receiver": targetReceiver,
      "content": content,
    };

    debugPrint("📤 CHAT SEND: sender=$_connectedUserEmail, receiver=$targetReceiver, destination=/app/chat.send, payload=$payload");

    _stompClient!.send(
      destination: "/app/chat.send",
      body: jsonEncode(payload),
      headers: {"content-type": "application/json"},
    );
  }

  void sendTyping({
    required String receiver,
    required bool isTyping,
  }) {
    if (_stompClient == null || !_stompClient!.connected) return;

    final payload = {
      "receiver": receiver.trim().toLowerCase(),
      "isTyping": isTyping,
    };

    _stompClient!.send(
      destination: "/app/chat.typing",
      body: jsonEncode(payload),
      headers: {"content-type": "application/json"},
    );
  }

  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _isConnecting = false;
    _connectedUserEmail = null;
    _messageListeners.clear();
    _statusListeners.clear();
    _typingListeners.clear();
    _presenceListeners.clear();
    _errorListeners.clear();
  }

  bool get isConnected => _stompClient?.connected ?? false;
}
