import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/utils/custom_theme.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;
  const UserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
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

  void printUser() {}

  String getGender(String sex) {
    if (sex == '0') {
      return "Masculin";
    } else {
      return "Feminin";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        centerTitle: true,
        title: Text(uiText(context, 'userDetails')),
        // actions: [
        //   IconButton(
        //     onPressed: () {},
        //     icon: const Icon(Icons.more_vert),
        //   )
        // ],
      ),
      body: Container(
        color: CustomTheme.grey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white),
                child: ListTile(
                  leading: const Icon(Icons.code, color: CustomTheme.blue),
                  title: Text(
                    widget.user.code,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Text(uiText(context, 'teacherCode'),
                      style: TextStyle(color: Colors.grey)),
                  // trailing: const Icon(Icons.edit),
                  onTap: () {},
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.all(10),
            //   child: Container(
            //     decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(20),
            //         color: Colors.white),
            //     child: ListTile(
            //       leading: const Icon(Icons.verified_user_rounded,
            //           color: CustomTheme.blue),
            //       title: Text(
            //         user.login,
            //         style: Theme.of(context).textTheme.titleSmall,
            //       ),
            //       subtitle:
            //           const Text('Login', style: TextStyle(color: Colors.grey)),
            //       trailing: const Icon(Icons.edit),
            //       onTap: () {},
            //     ),
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(10),
            //   child: Container(
            //     decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(20),
            //         color: Colors.white),
            //     child: ListTile(
            //       leading: const Icon(Icons.security, color: CustomTheme.blue),
            //       title: Text(
            //         user.text_password,
            //         style: Theme.of(context).textTheme.titleSmall,
            //       ),
            //       subtitle: const Text('Mot de passe',
            //           style: TextStyle(color: Colors.grey)),
            //       trailing: const Icon(Icons.edit),
            //       onTap: () {},
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white),
                child: ListTile(
                  leading: const Icon(Icons.person, color: CustomTheme.blue),
                  title: Text(
                    '${widget.user.nom} ${widget.user.prenom}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Text(uiText(context, 'firstAndLastNames'),
                      style: TextStyle(color: Colors.grey)),
                  // trailing: const Icon(Icons.edit),
                  onTap: () {},
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white),
                child: ListTile(
                  leading: const Icon(
                    Icons.male,
                    color: CustomTheme.blue,
                  ),
                  title: Text(
                    getGender(widget.user.sex),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Text(uiText(context, 'gender'),
                      style: const TextStyle(color: Colors.grey)),
                  // trailing: const Icon(Icons.edit),
                  onTap: () {},
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.all(10),
            //   child: Container(
            //     decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(20),
            //         color: Colors.white),
            //     child: ListTile(
            //       leading: const Icon(
            //         Icons.person_pin_circle,
            //         color: CustomTheme.blue,
            //       ),
            //       title: Text(
            //         user.account_type,
            //         style: Theme.of(context).textTheme.titleSmall,
            //       ),
            //       subtitle: const Text('Type de compte',
            //           style: TextStyle(color: Colors.grey)),
            //       trailing: const Icon(Icons.edit),
            //       onTap: () {},
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white),
                child: ListTile(
                  leading: const Icon(
                    Icons.phone,
                    color: CustomTheme.blue,
                  ),
                  title: Text(
                    '+237 6 ${widget.user.contacts}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: const Text(
                    'Contacts',
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   child: const Icon(Icons.edit),
      // ),
    );
  }
}
