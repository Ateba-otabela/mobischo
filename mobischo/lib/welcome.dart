// ignore_for_file: implementation_imports, unnecessary_import

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/components/screens/auth/login.dart';
import 'package:mobischo/components/screens/welcome/body.dart';

class Welcome extends StatefulWidget {
  const Welcome({Key? key}) : super(key: key);

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const Expanded(
              flex: 6,
              child: Body(),
            ),
            Expanded(
              // flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30, left: 10, right: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                        text: "Continuer",
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        })
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
