// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/changePassword.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/welcome.dart';

class MyAccount extends StatefulWidget {
  final User user;
  const MyAccount({Key? key, required this.user}) : super(key: key);

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
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
      // backgroundColor: CustomTheme.grey,
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios)),
        title: Text(
          "Mon Compte",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                BottomForm(context);
              },
              icon: const Icon(Icons.more_vert))
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: CustomTheme.cardShadow),
              child: ListTile(
                leading: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/avatar-s-19.jpg'),
                      // fit: BoxFit.fill
                    ),
                  ),
                  // child: Text(widget.user.account_type),
                ),
                title: Text("${widget.user.nom} ${widget.user.prenom}"),
                subtitle: Text(widget.user.account_type,
                    style: const TextStyle(
                      color: CustomTheme.blue,
                    )),
                onTap: () {
                  BottomForm(context);
                },
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.code,
              color: CustomTheme.blue,
            ),
            title: Text(widget.user.code),
            subtitle: const Text('Code'),
          ),
          ListTile(
            leading: const Icon(
              Icons.login,
              color: CustomTheme.blue,
            ),
            title: Text(widget.user.login),
            subtitle: const Text('Login'),
          ),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: CustomTheme.blue,
            ),
            title: const Text('Deconnection'),
            subtitle: const Text('Se Deconnecter'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              if (isLoaded == true) {
                _interstitialAd!.show();
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Welcome()),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          BottomForm(context);
        },
        backgroundColor: CustomTheme.blue,
        child: const Icon(Icons.more_horiz),
      ),
    );
  }

  Future<void> BottomForm(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          return Container(
            height: 180,
            width: double.infinity,
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text("Modifier le mot de passe"),
                    subtitle: const Text(
                      'Cliquez pour modifier',
                      style: TextStyle(color: CustomTheme.blue),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChangePassword(
                                  user: widget.user,
                                )),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Deconnection'),
                    subtitle: const Text(
                      'Cliquez pour vous deconnecter',
                      style: TextStyle(color: CustomTheme.blue),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Welcome()),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
