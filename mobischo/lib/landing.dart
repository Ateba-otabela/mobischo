// ignore_for_file: implementation_imports, unnecessary_import, camel_case_types

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// ignore: unused_import
import 'package:mobischo/components/screens/MyAccount.dart';
import 'package:mobischo/components/screens/layouts/main_menu.dart';
import 'package:mobischo/components/screens/parent/absence_justification_screen.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/utils/custom_theme.dart';

class landingScreen extends StatefulWidget {
  final User user;
  const landingScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<landingScreen> createState() => _landingScreenState();
}

class _landingScreenState extends State<landingScreen> {
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
              // _interstitialAd!.show();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      body: SingleChildScrollView(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MainMenu(user: widget.user),
          if (widget.user.account_type == 'parent')
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 10,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AbsenceJustificationScreen(
                          user: widget.user,
                        ),
                      ),
                    );
                  },
                  child: const ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: Icon(
                      Icons.edit_calendar_outlined,
                      color: CustomTheme.blue,
                      size: 32,
                    ),
                    title: Text('Justifier une absence'),
                    subtitle: Text(
                      'Signalez et justifiez l\'absence de votre enfant.',
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                ),
              ),
            ),
        ],
      )),
    );
  }
}
