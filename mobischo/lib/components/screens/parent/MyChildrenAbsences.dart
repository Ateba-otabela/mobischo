// ignore_for_file: file_names

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/parent/allStudentAbsences.dart';
import 'package:flutter/material.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class MyChildrenAbsences extends StatefulWidget {
  final User user;
  final bool embedded;
  final VoidCallback? onBack;

  const MyChildrenAbsences({
    Key? key,
    required this.user,
    this.embedded = false,
    this.onBack,
  }) : super(key: key);

  @override
  State<MyChildrenAbsences> createState() => _MyChildrenAbsencesState();
}

class _MyChildrenAbsencesState extends State<MyChildrenAbsences> {
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

  String getGender(String sex) {
    if (sex == '0') {
      return "Masculin";
    } else {
      return "Feminin";
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: FutureBuilder(
        future: StudentServices.getParentStudents(widget.user.code),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 12, left: 5, right: 5, bottom: 5),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: CustomTheme.cardShadow),
                    child: ListTile(
                      trailing: const Image(
                          image: AssetImage('assets/images/landing3.png')),
                      title: Text(
                        "Cliquez sur un enfant pour consulter ses absences",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: CustomTheme.grey,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
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
                                title: Text(
                                  getStudentDisplayName(snapshot.data[index]),
                                  style: const TextStyle(fontSize: 13)),
                                subtitle: Text(
                                  getGender(snapshot.data[index].Sex),
                                  style:
                                      const TextStyle(color: CustomTheme.blue),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: ((context) =>
                                              AllStudentAbsences(
                                                  user: widget.user,
                                                  student:
                                                      snapshot.data[index]))));
                                },
                              ),
                            ),
                          );
                        }),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );

    if (widget.embedded) {
      return WillPopScope(
        onWillPop: () async {
          widget.onBack?.call();
          return false;
        },
        child: Container(
          color: CustomTheme.grey,
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Retour au tableau de bord',
                    icon: const Icon(Icons.arrow_back_ios),
                    color: CustomTheme.blue,
                    onPressed: widget.onBack,
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CustomTheme.grey,
      body: body,
    );
  }
}
