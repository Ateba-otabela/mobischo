// ignore_for_file: avoid_unnecessary_containers, unused_field, prefer_final_fields, import_of_legacy_library_into_null_safe, use_build_context_synchronously, unused_local_variable, avoid_print, no_leading_underscores_for_local_identifiers

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import '../../../home.dart';
import '../../../models/user.dart';
import '../../../utils/custom_button.dart';
import '../../../utils/custom_input.dart';
import '../../../utils/custom_theme.dart';
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
    if (_login.text == '' || _password.text == '') {
      Fluttertoast.showToast(
          msg: "Les champs ne peuvent pas etre vides !",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          fontSize: 16.0);
    } else {
      var url = "https://mobischo.com/login.php";

      var map = <String, dynamic>{};
      map['action'] = 'LOGIN';
      map['login'] = _login.text;
      map['text_password'] = _password.text;
      final response = await http.post(Uri.parse(url), body: map);

      if (response.body.isNotEmpty) {
        print(response.body);
        if (json.decode(response.body) == 'Error') {
          Fluttertoast.showToast(
            msg: "Les Logins incorrectes",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            fontSize: 16.0,
          );
        } else {
          var data = json.decode(response.body);
          data.cast<Map<String, dynamic>>();
          var list = data.map<User>((json) => User.fromJson(json));
          final user = list.first;
          print(user.nom);

          if (user.admin == '1' && user.CodeEtablissement.trim().isNotEmpty) {
            Navigator.push(
              cont,
              MaterialPageRoute(
                  builder: (context) => PrincipalShell(user: user)),
            );
          } else {
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
            msg: 'Erreur de Connextion',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return MaterialApp(
        theme: CustomTheme.getTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
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
                          'Connectez vous a votre compte',
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
                                    labelText: 'Login',
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
                                    labelText: 'Mot de passe',
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
                                    text: "Se Connecter",
                                    onPress: () => login(context)),
                                const SizedBox(
                                  height: 20,
                                ),
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Mot de passe oublié ?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                      InkWell(
                                          child: const Text(
                                            'réinitialiser',
                                            style: TextStyle(
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
        ));
  }
}
