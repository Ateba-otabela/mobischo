// ignore_for_file: file_names, camel_case_types

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/teachers.dart/absences.dart';
import 'package:mobischo/components/screens/teachers.dart/absences_list.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:flutter/material.dart';

class teacherClassList extends StatefulWidget {
  const teacherClassList({
    Key? key,
    required this.widget,
  }) : super(key: key);

  final AbsencesScreen widget;

  @override
  State<teacherClassList> createState() => _teacherClassListState();
}

class _teacherClassListState extends State<teacherClassList> {
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
        future: CourseServices.getTeacherCourses(widget.widget.user.code),
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
                      onTap: () {},
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ListTile(
                            title: Text(
                              "CHOISISEZ UNE CLASSE",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              "Cliquez sur la classe pour continuer",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            trailing: const Image(
                              image: AssetImage('assets/images/landing2.png'),
                            ),
                            onTap: () {},
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
                              title: FutureBuilder<String>(
                                future: CourseServices.getMainCourse(
                                    snapshot.data[index].CodeMatiere),
                                builder: (
                                  BuildContext context,
                                  AsyncSnapshot<String> snapshot,
                                ) {
                                  if (snapshot.data == null) {
                                    return Text(
                                        uiText(context, 'loadingEllipsis'));
                                  } else {
                                    return Text(snapshot.data ?? "");
                                  }
                                },
                              ),
                              subtitle: FutureBuilder<String>(
                                future: CourseServices.getMainClass(
                                    snapshot.data[index].CodeClasse),
                                builder: (
                                  BuildContext context,
                                  AsyncSnapshot<String> snapshot,
                                ) {
                                  if (snapshot.data == null) {
                                    return Text(
                                        uiText(context, 'loadingEllipsis'));
                                  } else {
                                    return Text(
                                      snapshot.data ?? "",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    );
                                  }
                                },
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
                                            AbsenceListScreen(
                                                course: snapshot.data[index],
                                                user: widget.widget.user))));
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
