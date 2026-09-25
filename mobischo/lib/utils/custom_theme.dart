import 'package:flutter/material.dart';

class CustomTheme {
  static const Color grey = Color(0xffDFDFDF);
  static const Color blue = Color.fromARGB(255, 62, 151, 96);
  static const Color dark = Color.fromARGB(255, 23, 43, 31);

  static const cardShadow = [
    BoxShadow(color: grey, blurRadius: 6, spreadRadius: 4, offset: Offset(0, 2))
  ];
  static const buttonShadow = [
    BoxShadow(color: grey, blurRadius: 3, spreadRadius: 4, offset: Offset(1, 3))
  ];

  static getCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(35),
      boxShadow: CustomTheme.cardShadow,
    );
  }

  static ThemeData getTheme() {
    Map<String, double> fontSize = {
      "sm": 14,
      "md": 18,
      "lg": 24,
    };

    return ThemeData(
        primaryColor: CustomTheme.blue,
        primarySwatch: Colors.green,
        fontFamily: 'DMSans',
        appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            toolbarHeight: 70,
            centerTitle: true,
            titleTextStyle: TextStyle(
                color: Colors.white,
                fontFamily: 'DMSans',
                fontSize: fontSize['lg'],
                fontWeight: FontWeight.bold,
                letterSpacing: 4)),
        tabBarTheme: const TabBarTheme(
            labelColor: CustomTheme.blue, unselectedLabelColor: Colors.white),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
              color: CustomTheme.blue,
              fontSize: fontSize['lg'],
              fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(
              color: CustomTheme.dark,
              fontSize: fontSize['md'],
              fontWeight: FontWeight.bold),
          titleLarge: TextStyle(
              color: Colors.white,
              fontSize: fontSize['md'],
              fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(
              color: CustomTheme.blue,
              fontSize: fontSize['sm'],
              fontWeight: FontWeight.bold),
          bodySmall: TextStyle(
              // color: Colors.green,
              fontSize: fontSize['sm'],
              fontWeight: FontWeight.normal),
          titleSmall: TextStyle(
              color: CustomTheme.dark,
              fontSize: fontSize['sm'],
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
          bodyMedium: TextStyle(
            color: CustomTheme.blue,
            fontSize: fontSize['sm'],
            // fontWeight: FontWeight.bold
          ),
        ));
  }
}
