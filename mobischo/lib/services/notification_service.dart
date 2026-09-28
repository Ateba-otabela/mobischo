import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();
  String? _currentToken;
  bool _initialized = false;

  Stream<String> get tokenRefreshes => _tokenRefreshController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(
      (message) => _logMessageMetadata('Foreground message', message),
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

    try {
      _currentToken = await _messaging.getToken();
    } on FirebaseException catch (error) {
      _logPluginFailure('FCM token retrieval', error);
    } on PlatformException catch (error) {
      _logPluginFailure('FCM token retrieval', error);
    }

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
