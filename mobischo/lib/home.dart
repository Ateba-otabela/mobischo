// ignore_for_file: implementation_imports, unnecessary_import, avoid_unnecessary_containers, unused_import, sort_child_properties_last, unused_field, must_call_super, must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mobischo/components/screens/layouts/customMenu.dart';
import 'package:mobischo/components/screens/layouts/sidebar.dart';
import 'package:mobischo/components/screens/teachers.dart/marks.dart';
import 'package:mobischo/components/screens/users/user_list.dart';
import 'package:mobischo/landing.dart';
import 'package:mobischo/models/user.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class Home extends StatefulWidget {
  final User user;
  int selectedPage;
  final Widget? initialBody;
  Home(
      {Key? key,
      required this.user,
      required this.selectedPage,
      this.initialBody})
      : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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

  @override
  Widget build(BuildContext context) {
    //to get a different button navigation menu for administrators and parents
    return Scaffold(
      body: Column(
        children: [
          // Container(
          //     height: 200,
          //     child: isLoaded?AdWidget(ad: nativeAd!):Center(child: Text('ad loading'))),
          Flexible(
            child: CustomMenu(
              user: widget.user,
              selectedPage: widget.selectedPage,
              initialBody: widget.initialBody,
            ),
          ),
        ],
      ),
    );
  }
}
