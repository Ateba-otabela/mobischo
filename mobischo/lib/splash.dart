// ignore_for_file: implementation_imports, unnecessary_import, non_constant_identifier_names

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/welcome.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  // @override
  // void initState() {
  //   super.initState();
  //   _NavigateToHome();
  // }

  // _NavigateToHome() async {
  //   await Future.delayed(const Duration(milliseconds: 3000), () {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const Welcome()));
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSplashScreen(
        backgroundColor: CustomTheme.blue,
        splash: const Icon(
          Icons.school,
          color: Colors.white,
          size: 80,
        ),
        nextScreen: const Welcome(),
        duration: 3000,
        splashTransition: SplashTransition.fadeTransition,
      ),
    );
  }
}
