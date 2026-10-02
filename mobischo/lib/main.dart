// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mobischo/services/mobile_api_service.dart';
import 'package:mobischo/services/notification_service.dart';
import 'package:mobischo/splash.dart';
import 'package:mobischo/utils/custom_theme.dart';

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();
  var firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } on FirebaseException catch (error) {
    if (kDebugMode) {
      debugPrint('Firebase initialization unavailable (${error.code}).');
    }
  } on PlatformException catch (error) {
    if (kDebugMode) {
      debugPrint('Firebase initialization unavailable (${error.code}).');
    }
  }

  if (firebaseInitialized) {
    try {
      final notificationService = NotificationService.instance;
      await notificationService.initialize();
      notificationService.tokenRefreshes.listen((fcmToken) {
        unawaited(MobileApiService.registerDevice(
          fcmToken,
          MobileApiService.devicePlatform,
        ));
      });
      unawaited(_registerDeviceForStoredSession(notificationService));
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('Firebase Messaging initialization unavailable (${error.code}).');
      }
    } on PlatformException catch (error) {
      if (kDebugMode) {
        debugPrint('Firebase Messaging initialization unavailable (${error.code}).');
      }
    }
  }

  MobileAds.instance.initialize();

  runApp(const MyApp());
}

Future<void> _registerDeviceForStoredSession(
  NotificationService notificationService,
) async {
  try {
    final sanctumToken = await MobileApiService.loadToken();
    if (sanctumToken == null || sanctumToken.isEmpty) return;

    final fcmToken = await notificationService.getCurrentToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    await MobileApiService.registerDevice(
      fcmToken,
      MobileApiService.devicePlatform,
    );
  } on Exception catch (error) {
    if (kDebugMode) {
      debugPrint('Stored-session device registration skipped (${error.runtimeType}).');
    }
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  final app_title = "mobischo";
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'mobischo',
        debugShowCheckedModeBanner: false,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        localeResolutionCallback: (locale, supportedLocales) {
          final languageCode = locale?.languageCode;
          return languageCode == 'en' ? const Locale('en') : const Locale('fr');
        },
        theme: CustomTheme.getTheme(),
        home: const Splash());
  }
}
