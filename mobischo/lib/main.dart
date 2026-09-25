// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/splash.dart';
import 'package:mobischo/utils/custom_theme.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(const MyApp());
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
        theme: CustomTheme.getTheme(),
        home: const Splash());
  }
}
