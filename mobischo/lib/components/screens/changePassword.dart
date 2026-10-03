// ignore_for_file: avoid_unnecessary_containers, unused_field, prefer_final_fields, import_of_legacy_library_into_null_safe, use_build_context_synchronously, unused_local_variable, avoid_print, no_leading_underscores_for_local_identifiers, file_names, non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/changePasswordSuccess.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/models/user.dart';

import 'package:mobischo/utils/custom_input.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:http/http.dart' as http;
import 'package:mobischo/l10n/ui_text.dart';

class ChangePassword extends StatefulWidget {
  final User user;
  final bool localOnly;
  const ChangePassword({Key? key, required this.user, this.localOnly = false})
      : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

  bool isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-2496623977736610/2133664237',
        // adUnitId: 'ca-app-pub-2496623977736610/2133664237',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);

            setState(() {
              isLoaded = true;
            });
          },
          onAdFailedToLoad: (LoadAdError error) {
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              _createInterstitialAd();
            }
          },
        ));
  }

  final TextEditingController _new_password = TextEditingController();
  final TextEditingController _confirm_new_password = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String _error = '';
  bool _isSubmitting = false;

  Future<void> changepassword(BuildContext cont) async {
    if (_isSubmitting) return;

    if (_new_password.text == '' ||
        _password.text == '' ||
        _confirm_new_password.text == '') {
      Fluttertoast.showToast(
          msg: uiText(cont, 'emptyFields'),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          fontSize: 16.0);
      return;
    }

    if (_new_password.text != _confirm_new_password.text) {
      Fluttertoast.showToast(
          msg: uiText(cont, 'passwordMismatch'),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          fontSize: 16.0);
      return;
    }

    setState(() => _isSubmitting = true);

    if (widget.localOnly) {
      _password.clear();
      _new_password.clear();
      _confirm_new_password.clear();
      Navigator.push(
        cont,
        MaterialPageRoute(
          builder: (context) => ChangePasswordSuccess(
            user: widget.user,
            returnToLogin: true,
          ),
        ),
      );
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    const url = "https://mobischo.com/login.php";
    final map = <String, dynamic>{
      'action': 'CHANGE PASSWORD',
      'login': widget.user.login.toString(),
      'current_password': _password.text,
      'new_password': _new_password.text,
    };

    try {
      final response = await http.post(Uri.parse(url), body: map);
      dynamic decodedResponse;

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        try {
          decodedResponse = json.decode(response.body);
        } catch (_) {
          decodedResponse = null;
        }
      }

      if (response.statusCode != 200 || decodedResponse != 'Success') {
        Fluttertoast.showToast(
          msg: uiText(cont, 'passwordChangeError'),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          fontSize: 16.0,
        );
      } else {
        _password.clear();
        _new_password.clear();
        _confirm_new_password.clear();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChangePasswordSuccess(
                    user: widget.user,
                  )),
        );
      }
    } catch (_) {
      Fluttertoast.showToast(
          msg: uiText(cont, 'connectionError'),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: CustomTheme.blue,
            )),
        title: Text(
          uiText(context, 'myAccount'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Image(
              image: AssetImage('assets/images/icon.png'),
              width: 40,
              height: 40,
            ),
          ),
        ],
      ),
      body: Center(
        child: Wrap(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: CustomTheme.getCardDecoration(),
                    child: Column(
                      children: [
                        // Padding(
                        //   padding: const EdgeInsets.only(bottom: 20.0),
                        //   child: Text(
                        //     'Modifiez votre mot de passe',
                        //     style:
                        //         Theme.of(context).textTheme.bodyMedium,
                        //     textAlign: TextAlign.center,
                        //   ),
                        // ),
                        CustomInput(
                            controller: _password,
                            hintText: 'username1234',
                            labelText: uiText(context, 'password'),
                            isPassword: true,
                            prefixIcon: Icons.lock,
                            surfixIcon: Icons.lock_outline_rounded,
                            readOnly: false,
                            borderColor: Colors.grey,
                            helperText: ""),
                        const SizedBox(
                          height: 2,
                        ),
                        CustomInput(
                            controller: _new_password,
                            hintText: '********',
                            labelText: uiText(context, 'newPassword'),
                            isPassword: true,
                            prefixIcon: Icons.lock,
                            surfixIcon: Icons.lock_outline_rounded,
                            readOnly: false,
                            borderColor: Colors.grey,
                            helperText: ""),
                        const SizedBox(
                          height: 2,
                        ),
                        CustomInput(
                            controller: _confirm_new_password,
                            hintText: '********',
                            labelText: uiText(context, 'confirmPassword'),
                            isPassword: true,
                            prefixIcon: Icons.lock,
                            surfixIcon: Icons.lock_outline_rounded,
                            readOnly: false,
                            borderColor: Colors.grey,
                            helperText: ""),
                        const SizedBox(
                          height: 20,
                        ),
                        CustomButton(
                            text: "Sauvegarder",
                            loading: _isSubmitting,
                            onPress: () => changepassword(context)),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
