import 'package:flutter/material.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../models/user.dart';
import '../../../services/courses.dart';
import '../../../utils/custom_theme.dart';
import 'course_detail.dart';

class CoursesScreen extends StatefulWidget {
  final User user;
  const CoursesScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
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
        future: CourseServices.getTeacherCourses(widget.user.code.toString()),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: CustomTheme.blue,
              ),
            );
          } else {
            return ListView.builder(
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
                          Icons.menu_book,
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
                              return Text(uiText(context, 'loadingEllipsis'));
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
                              return Text(uiText(context, 'loadingEllipsis'));
                            } else {
                              return Text(snapshot.data ?? "");
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
                                  builder: ((context) => CourseDetailScreen(
                                      course: snapshot.data[index],
                                      user: widget.user))));
                        },
                      ),
                    ),
                  );
                });
          }
        },
      ),
    );
  }
}
