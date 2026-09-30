import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ---------------------------------------------------------------------------
// Android notification channel used for foreground FCM display.
// ---------------------------------------------------------------------------
const String _kChannelId = 'mobischo_notifications';
const String _kChannelName = 'MOBISCHO Notifications';
const String _kChannelDesc = 'General MOBISCHO push notifications.';

// ---------------------------------------------------------------------------
// Background handler — must be a top-level function.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (error) {
    _logPluginFailure('Background Firebase initialization', error);
    return;
  } on PlatformException catch (error) {
    _logPluginFailure('Background Firebase initialization', error);
    return;
  }

  _logMessageMetadata('Background message', message);
}

// ---------------------------------------------------------------------------
// NotificationService
// ---------------------------------------------------------------------------
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();
  String? _currentToken;
  bool _initialized = false;

  // Local notifications plugin — used only for foreground display.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Monotonically increasing ID so each foreground notification is distinct.
  int _notificationId = 0;

  Stream<String> get tokenRefreshes => _tokenRefreshController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    // ------------------------------------------------------------------
    // 1. Initialise flutter_local_notifications with the Android channel.
    // ------------------------------------------------------------------
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    // Create / register the high-importance notification channel on Android.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: _kChannelDesc,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ------------------------------------------------------------------
    // 2. Register FCM handlers (unchanged from original).
    // ------------------------------------------------------------------
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: _handleStreamError,
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTap,
      onError: _handleStreamError,
    );

    _messaging.onTokenRefresh.listen(
      (token) {
        _currentToken = token;
        _tokenRefreshController.add(token);
      },
      onError: _handleStreamError,
    );

    _initialized = true;

    // ------------------------------------------------------------------
    // 3. Request permission (unchanged).
    // ------------------------------------------------------------------
    try {
      final settings = await _messaging.requestPermission();
      if (kDebugMode) {
        debugPrint(
          'Notification permission status: ${settings.authorizationStatus}.',
        );
      }
    } on FirebaseException catch (error) {
      _logPluginFailure('Notification permission request', error);
    } on PlatformException catch (error) {
      _logPluginFailure('Notification permission request', error);
    }

    // ------------------------------------------------------------------
    // 4. FCM token retrieval (unchanged).
    // ------------------------------------------------------------------
    try {
      _currentToken = await _messaging.getToken();
    } on FirebaseException catch (error) {
      _logPluginFailure('FCM token retrieval', error);
    } on PlatformException catch (error) {
      _logPluginFailure('FCM token retrieval', error);
    }

    // ------------------------------------------------------------------
    // 5. Handle notification that launched the app (unchanged).
    // ------------------------------------------------------------------
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } on FirebaseException catch (error) {
      _logPluginFailure('Initial notification lookup', error);
    } on PlatformException catch (error) {
      _logPluginFailure('Initial notification lookup', error);
    }
  }

  Future<String?> getCurrentToken() async => _currentToken;

  // ------------------------------------------------------------------
  // Foreground message handler:
  //   • logs metadata (existing behaviour)
  //   • displays a local notification banner (new behaviour)
  // ------------------------------------------------------------------
  void _handleForegroundMessage(RemoteMessage message) {
    _logMessageMetadata('Foreground message', message);

    final title = message.notification?.title;
    final body = message.notification?.body;

    // Only display a banner when the FCM message carries a notification
    // payload (which the backend always includes per the diagnostic report).
    if (title == null && body == null) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      _localNotifications.show(
        _notificationId++,
        title,
        body,
        notificationDetails,
      );
    } on PlatformException catch (error) {
      _logPluginFailure('Foreground local notification display', error);
    } catch (error, stackTrace) {
      Zone.current.handleUncaughtError(error, stackTrace);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _logMessageMetadata('Notification opened', message);
    // TODO: Route using validated notification data in the future.
  }

  void _handleStreamError(Object error, [StackTrace? stackTrace]) {
    if (error is FirebaseException || error is PlatformException) {
      _logPluginFailure('Firebase Messaging stream', error);
      return;
    }

    Zone.current.handleUncaughtError(error, stackTrace ?? StackTrace.current);
  }
}

void _logMessageMetadata(String event, RemoteMessage message) {
  if (!kDebugMode) return;

  final title = message.notification?.title;
  final body = message.notification?.body;
  final rawType = message.data['type'];
  final type = rawType is String ? rawType : null;

  debugPrint('$event: title=$title, body=$body, type=$type');
}

void _logPluginFailure(String operation, Object error) {
  if (!kDebugMode) return;

  if (error is FirebaseException) {
    debugPrint('$operation failed (${error.code}).');
  } else if (error is PlatformException) {
    debugPrint('$operation failed (${error.code}).');
  }
}
