// ignore_for_file: avoid_print, unused_element, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/users/user_detail.dart';
import 'package:mobischo/services/services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
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
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: FutureBuilder(
            future: Services.getUsers(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return Container(
                  color: CustomTheme.grey,
                  child: ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white),
                            child: ListTile(
                              leading: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                        image: AssetImage(
                                            'assets/images/avatar-s-19.jpg'),
                                        fit: BoxFit.fill),
                                  )),
                              subtitle:
                                  Text("${snapshot.data[index].account_type}"),
                              title: Text(
                                  "${snapshot.data[index].nom} ${snapshot.data[index].prenom}"),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                if (isLoaded == true) {
                                  _interstitialAd!.show();
                                }
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => UserDetailScreen(
                                          user: snapshot.data[index],
                                        )));
                              },
                            ),
                          ),
                        );
                      }),
                );
              }
            },
          ),
        ));
  }
}
