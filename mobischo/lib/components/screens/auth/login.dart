// ignore_for_file: avoid_unnecessary_containers, unused_field, prefer_final_fields, import_of_legacy_library_into_null_safe, use_build_context_synchronously, unused_local_variable, avoid_print, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mobischo/services/mobile_api_service.dart';
import 'package:mobischo/services/notification_service.dart';

import '../../../home.dart';
import '../../../models/user.dart';
import '../../../utils/custom_button.dart';
import '../../../utils/custom_input.dart';
import '../../../utils/custom_theme.dart';
import '../changePassword.dart';
import '../principal_encadreur/principal_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _login = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String _error = '';

  Future login(BuildContext cont) async {
    final l10n = AppLocalizations.of(cont);
    if (_login.text == '' || _password.text == '') {
      Fluttertoast.showToast(
          msg: l10n.emptyFields,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          fontSize: 16.0);
    } else {
      const url = 'https://mobischo.com/api/mobile/login';

      var map = <String, dynamic>{};
      map['action'] = 'LOGIN';
      map['login'] = _login.text;
      map['text_password'] = _password.text;
      final response = await http.post(Uri.parse(url), body: map);

      if (response.body.isNotEmpty) {
        if (json.decode(response.body) == 'Error') {
          Fluttertoast.showToast(
            msg: l10n.incorrectLogin,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            fontSize: 16.0,
          );
        } else {
          final data = json.decode(response.body);
          if (data is! List || data.isEmpty) {
            Fluttertoast.showToast(
              msg: l10n.connectionError,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
            );
            return;
          }

          final loginData = data.first as Map<String, dynamic>;
          final user = User.fromJson(loginData);
          final mustChangePassword =
              loginData['must_change_password'] == true;
          if (user.token.isNotEmpty) {
            await MobileApiService.saveSession(user, user.token);
            unawaited(_registerDeviceAfterLogin());
          }

          final accountType = user.account_type.trim().toLowerCase();
          final shouldUsePrincipalShell = const {
            'principal',
            'encadreur',
            'principal_encadreur',
            'administrateur',
          }.contains(accountType);
          final destination = shouldUsePrincipalShell
              ? PrincipalShell(user: user)
              : Home(user: user, selectedPage: 0);

          if (mustChangePassword) {
            Fluttertoast.showToast(
              msg:
                  'For security, you must change your default password before continuing.',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              fontSize: 16.0,
            );
            if (!mounted) return;
            await Navigator.of(cont).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ChangePassword(
                  user: user,
                  postChangeDestination: destination,
                ),
              ),
            );
            return;
          }

          if (shouldUsePrincipalShell) {
            debugPrint(
              '[MobischoAI] Principal login token present='
              '${user.aiToken.trim().isNotEmpty}',
            );
            if (!mounted) return;
            Navigator.push(
              cont,
              MaterialPageRoute(
                  builder: (context) => PrincipalShell(user: user)),
            );
          } else {
            if (!mounted) return;
            Navigator.push(
              cont,
              MaterialPageRoute(
                  builder: (context) => Home(
                        user: user,
                        selectedPage: 0,
                      )),
            );
          }
        }
      } else {
        Fluttertoast.showToast(
            msg: l10n.connectionError,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER);
      }
    }
  }

  Future<void> _registerDeviceAfterLogin() async {
    try {
      final fcmToken = await NotificationService.instance.getCurrentToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await MobileApiService.registerDevice(
        fcmToken,
        MobileApiService.devicePlatform,
      );
    } on Exception catch (error) {
      debugPrint('Login device registration skipped (${error.runtimeType}).');
    }
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Form(
            key: _formKey,
            child: Wrap(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Image(
                      image: AssetImage('assets/images/icon.png'),
                      width: 80,
                      height: 80,
                    ),
                    Text(
                      'MOBISCHO',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      l10n.loginTitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: CustomTheme.getCardDecoration(),
                        child: Column(
                          children: [
                            CustomInput(
                                controller: _login,
                                hintText: 'username1234',
                                labelText: l10n.login,
                                isPassword: false,
                                prefixIcon: Icons.person,
                                surfixIcon: Icons.lock_outline_rounded,
                                readOnly: false,
                                borderColor: Colors.grey,
                                helperText: ""),
                            const SizedBox(
                              height: 2,
                            ),
                            CustomInput(
                                controller: _password,
                                hintText: '********',
                                labelText: l10n.password,
                                isPassword: true,
                                prefixIcon: Icons.lock,
                                surfixIcon: Icons.lock_outline_rounded,
                                enablePasswordToggle: true,
                                readOnly: false,
                                borderColor: Colors.grey,
                                helperText: ""),
                            const SizedBox(
                              height: 20,
                            ),
                            CustomButton(
                                text: l10n.signIn,
                                onPress: () => login(context)),
                            const SizedBox(
                              height: 20,
                            ),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.forgotPassword,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  InkWell(
                                      child: Text(
                                        l10n.reset,
                                        style: const TextStyle(
                                            color: CustomTheme.blue),
                                      ),
                                      onTap: () => () {}),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )),
      ),
    );
  }
}
