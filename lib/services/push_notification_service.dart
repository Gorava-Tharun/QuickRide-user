import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';
import 'firebase_service.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint('[User FCM Background] Message received: ${message.messageId}, data: ${message.data}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Set<String> _processedEventKeys = {};
  
  bool _isInitialized = false;
  String? _fcmToken;
  String? _currentUserId;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  Function(String rideId, String type, [Map<String, dynamic>? data])? onNotificationTap;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Android high-importance notification channel
  static const AndroidNotificationChannel _rideChannel =
      AndroidNotificationChannel(
    'quickride_user_rides',
    'QuickRide Trip Updates',
    description: 'Notifications for captain status, arrival, and ride progression.',
    importance: Importance.high,
  );

  /// Initialize Firebase Messaging & Local Notifications safely
  Future<bool> initialize({
    String? userId,
    Function(String rideId, String type, [Map<String, dynamic>? data])? onNotificationTap,
  }) async {
    if (onNotificationTap != null) {
      this.onNotificationTap = onNotificationTap;
    }
    if (userId != null && userId.isNotEmpty) {
      _currentUserId = userId;
    }

    if (_isInitialized) {
      if (userId != null && userId.isNotEmpty && _fcmToken != null) {
        await QuickRideFirebaseService().updateFcmToken(userId, _fcmToken);
      }
      return true;
    }

    try {
      // 1. Initialize local notifications for foreground popups
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            final parts = payload.split('|');
            final rideId = parts.isNotEmpty ? parts[0] : '';
            final type = parts.length > 1 ? parts[1] : '';
            if (this.onNotificationTap != null) {
              this.onNotificationTap!(rideId, type, {'rideId': rideId, 'type': type});
            }
          }
        },
      );

      // Create Android channel
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_rideChannel);
      }

      // Check if Firebase is available
      if (Firebase.apps.isEmpty) {
        debugPrint('[PushNotificationService] Firebase not initialized yet, skipping remote FCM listeners.');
        _isInitialized = true;
        return false;
      }

      // 2. Request Notification Permissions politely
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: true,
        sound: true,
      );

      debugPrint('[PushNotificationService] Permission status: ${settings.authorizationStatus}');

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Retrieve FCM Token
      try {
        _fcmToken = await messaging.getToken();
        debugPrint('[PushNotificationService] Retrieved FCM token: ${_fcmToken != null ? "YES (masked)" : "NONE"}');
        if (_currentUserId != null && _currentUserId!.isNotEmpty && _fcmToken != null) {
          await QuickRideFirebaseService().updateFcmToken(_currentUserId!, _fcmToken);
        }
      } catch (e) {
        debugPrint('[PushNotificationService] Error retrieving token (offline/fallback): $e');
      }

      // 4. Listen for Token Refreshes
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (_currentUserId != null && _currentUserId!.isNotEmpty) {
          QuickRideFirebaseService().updateFcmToken(_currentUserId!, newToken);
        }
      });

      // 5. Handle Foreground Messages
      _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 6. Handle App Opened from Background Notification Tap
      _onMessageOpenedAppSub?.cancel();
      _onMessageOpenedAppSub =
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message.data);
      });

      // 7. Check if App was Launched from a Terminated Notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data);
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('[PushNotificationService] Initialization error (using local fallback): $e');
      _isInitialized = true;
      return false;
    }
  }

  /// Register or update user ID on login
  Future<void> registerUser(String userId) async {
    _currentUserId = userId;
    if (_fcmToken != null) {
      await QuickRideFirebaseService().updateFcmToken(userId, _fcmToken);
    }
  }

  /// Clear token on logout
  Future<void> clearUser() async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      await QuickRideFirebaseService().updateFcmToken(_currentUserId!, null);
    }
    _currentUserId = null;
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {}
    _fcmToken = null;
  }

  /// Deduplication guard: returns true if event should be processed, false if duplicate
  bool shouldProcessRideEvent(String rideId, String status) {
    final key = '${rideId}_$status';
    if (_processedEventKeys.contains(key)) {
      return false;
    }
    _processedEventKeys.add(key);
    // Limit memory footprint of set
    if (_processedEventKeys.length > 200) {
      _processedEventKeys.remove(_processedEventKeys.first);
    }
    return true;
  }

  /// Handle incoming foreground push message
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'QuickRide';
    final body = notification?.body ?? data['message'] ?? '';
    final rideId = data['rideId'] ?? '';
    final typeStr = data['type'] ?? '';

    // Check deduplication
    if (rideId.isNotEmpty && typeStr.isNotEmpty) {
      if (!shouldProcessRideEvent(rideId, typeStr)) {
        return;
      }
    }

    // 1. Show local notification banner
    showLocalNotification(
      title: title,
      body: body,
      payload: '$rideId|$typeStr',
    );

    // 2. Add to in-app notification repository
    final parsedType = NotificationType.fromCode(typeStr);
    NotificationService().addNotification(
      AppNotification(
        id: 'fcm_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}',
        type: parsedType,
        title: title,
        message: body,
        createdAt: DateTime.now(),
        isRead: false,
        rideId: rideId.isNotEmpty ? rideId : null,
      ),
    );
  }

  /// Show a foreground heads-up banner notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'quickride_user_rides',
        'QuickRide Trip Updates',
        channelDescription: 'Notifications for captain status, arrival, and ride progression.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final id = notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _localNotifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('[PushNotificationService] Local notification show error: $e');
    }
  }

  /// Deep linking route based on tapped notification data payload
  void _handleNotificationTap(Map<String, dynamic> data) {
    final rideId = data['rideId'] as String? ?? data['complaintId'] as String? ?? '';
    final type = data['type'] as String? ?? '';
    if (onNotificationTap != null) {
      onNotificationTap!(rideId, type, data);
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
  }
}
