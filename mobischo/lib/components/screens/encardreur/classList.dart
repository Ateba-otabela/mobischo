// ignore_for_file: file_names

// ignore: unused_import

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/encardreur/chooseStudents.dart';
import 'package:mobischo/components/screens/encardreur/createAllConvocation.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:flutter/material.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/utils/custom_theme.dart';

class ClassListScreen extends StatefulWidget {
  final User user;
  const ClassListScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
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
      backgroundColor: CustomTheme.grey,
      body: FutureBuilder(
        future: AcademicServices.getAllClasses(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: CustomTheme.blue,
              ),
            );
          } else {
            return Column(
              children: [
                Center(
                    child: SizedBox(
                  width: double.infinity,
                  height: 90,
                  // padding: const EdgeInsets.all(2.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    // elevation: 10,
                    child: InkWell(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ListTile(
                            title: Text(
                              "MESSAGE A TOUS LES PARENTS",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              "Cliquez ici pour continuer",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            trailing: const Image(
                              image: AssetImage('assets/images/landing2.png'),
                            ),
                            onTap: () {
                              if (isLoaded == true) {
                                _interstitialAd!.show();
                              }
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: ((context) =>
                                          CreateAllConvocation(
                                              user: widget.user))));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
                Flexible(
                  child: ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white),
                            child: ListTile(
                              leading: const Icon(
                                Icons.timer,
                                color: CustomTheme.blue,
                              ),
                              title: Text(snapshot.data[index].LibelleClasse),
                              subtitle: Text(
                                'Code Classe : ${snapshot.data[index].CodeClasse}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                if (isLoaded == true) {
                                  _interstitialAd!.show();
                                }
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: ((context) => ChooseStudents(
                                            classe: snapshot.data[index],
                                            user: widget.user))));
                              },
                            ),
                          ),
                        );
                      }),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
