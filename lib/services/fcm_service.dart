import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/storage_service.dart';
import 'notification_navigation_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint("🌙 Background FCM Message: ${message.messageId} | data: ${message.data}");
}

class FcmService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'Real-time notifications for incoming chat messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      debugPrint("🔥 Firebase Core initialized successfully");
    } catch (e) {
      debugPrint("⚠️ Firebase.initializeApp() skipped or failed: $e");
      return;
    }

    try {
      // 1. Setup local notifications for Android foreground presentation
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("🔥 TAP EVENT: LOCAL NOTIFICATION");
          debugPrint("🔥 PAYLOAD: ${response.payload}");
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final Map<String, dynamic> data = jsonDecode(response.payload!);
              NotificationNavigationService.handleNotificationPayload(data);
            } catch (e) {
              debugPrint("Error parsing notification tap payload: $e");
            }
          }
        },
      );

      // 2. Create high-importance Android Notification Channel
      final androidPlatform = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(_chatChannel);
      }

      // 3. Request permissions (Android 13+ and iOS)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint("🔔 FCM Permission status: ${settings.authorizationStatus}");

      // 4. Background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 5. Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 6. Background notification tap handler (app open from background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("🔥 TAP EVENT: BACKGROUND FCM");
        debugPrint("🔥 PAYLOAD: ${message.data}");

        NotificationNavigationService.handleNotificationPayload(message.data);
      });

      // 7. Check if app was launched from terminated state via notification tap
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      debugPrint("🔥 INITIAL MESSAGE: ${initialMessage?.data}");
      if (initialMessage != null) {
        debugPrint(
            "🚀 App launched from terminated state via notification: ${initialMessage.data}");
        NotificationNavigationService.handleNotificationPayload(
            initialMessage.data);
      }

      // 8. Listen for token refresh events
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint("🔄 FCM Token refreshed: ${maskToken(newToken)}");
        registerCurrentTokenWithBackend(forceToken: newToken);
      });

      _isInitialized = true;
      debugPrint("✅ FcmService initialized successfully");
    } catch (e) {
      debugPrint("⚠️ FcmService initialization error: $e");
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint("📥 Foreground FCM message received: ${message.data}");

    final senderEmail =
        message.data['senderEmail']?.toString().trim().toLowerCase();

    // Check if the recipient is currently viewing this exact conversation
    if (NotificationNavigationService.isChatActiveWith(senderEmail)) {
      debugPrint(
          "👀 User is actively viewing chat with $senderEmail. Suppressing foreground notification.");
      return;
    }

    final title = message.notification?.title ??
        message.data['senderName'] ??
        "GLS Connect";
    final body = message.notification?.body ??
        message.data['content'] ??
        "New message";

    final androidDetails = AndroidNotificationDetails(
      _chatChannel.id,
      _chatChannel.name,
      channelDescription: _chatChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      tag: message.data['conversationId'], // Group notifications by conversation
    );

    final notificationDetails =
        NotificationDetails(android: androidDetails);

    // Use a unique notification ID per conversation or message to prevent overwriting
    final notifId = (message.data['conversationId']?.hashCode ??
            DateTime.now().millisecondsSinceEpoch) &
        0x7FFFFFFF;

    _localNotifications.show(
      notifId,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> registerCurrentTokenWithBackend(
      {String? forceToken}) async {
    try {
      final isLoggedIn = await StorageService.getLoginStatus();
      final jwtToken = await StorageService.getToken();

      if (!isLoggedIn || jwtToken == null || jwtToken.trim().isEmpty) {
        debugPrint(
            "🔒 Skipping FCM token registration: User not logged in");
        return;
      }

      String? fcmToken = forceToken;
      fcmToken ??= await FirebaseMessaging.instance.getToken();

      if (fcmToken == null || fcmToken.trim().isEmpty) {
        debugPrint("⚠️ No FCM token available from FirebaseMessaging");
        return;
      }

      debugPrint("📲 Registering FCM token with backend: ${maskToken(fcmToken)}");

      final url = Uri.parse(
          "${ApiConfig.baseUrl}/api/notifications/devices/register");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode({
          "token": fcmToken.trim(),
          "deviceType": "ANDROID",
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Device FCM token registered successfully with backend");
      } else {
        debugPrint(
            "⚠️ Backend rejected FCM token registration: status=${response.statusCode}, body=${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to register FCM token with backend: $e");
    }
  }

  static Future<void> unregisterCurrentTokenWithBackend() async {
    try {
      final jwtToken = await StorageService.getToken();
      if (jwtToken == null || jwtToken.trim().isEmpty) return;

      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.trim().isEmpty) return;

      debugPrint(
          "🗑️ Unregistering FCM token from backend: ${maskToken(fcmToken)}");

      final url = Uri.parse(
          "${ApiConfig.baseUrl}/api/notifications/devices/unregister");
      await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode({
          "token": fcmToken.trim(),
        }),
      );
    } catch (e) {
      debugPrint("⚠️ Failed to unregister FCM token: $e");
    }
  }

  static String maskToken(String token) {
    if (token.length <= 12) return "***";
    return "${token.substring(0, 6)}...${token.substring(token.length - 4)}";
  }
}
