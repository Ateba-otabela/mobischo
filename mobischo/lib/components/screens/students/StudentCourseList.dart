// ignore_for_file: file_names, non_constant_identifier_names

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/parent/allStudentAbsences.dart';
import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/courses/ParentCourseDetail.dart';
import 'package:mobischo/components/screens/parent/studentMarkList.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class StudentCoursesScreen extends StatefulWidget {
  final User user;
  final Student student;
  const StudentCoursesScreen(
      {Key? key, required this.user, required this.student})
      : super(key: key);

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
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
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        title: Text(
          getStudentDisplayName(widget.student),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      backgroundColor: CustomTheme.grey,
      body: FutureBuilder(
        future: CourseServices.getClassCourses(widget.student.CodeClasse),
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
                              return const Text('loading ...');
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
                              return const Text('loading ...');
                            } else {
                              return Text(snapshot.data ?? "");
                            }
                          },
                        ),
                        trailing: IconButton(
                            onPressed: () {
                              BottomForm(context, snapshot.data[index]);
                            },
                            icon: const Icon(Icons.more_vert)),
                        onTap: () {
                          BottomForm(context, snapshot.data[index]);
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

  Future<void> BottomForm(BuildContext context, Course course) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          return Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30))),
            height: 230,
            width: double.infinity,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.inventory_outlined),
                    title: const Text("Details"),
                    subtitle: const Text(
                      'Cliquez pour consulter',
                      style: TextStyle(color: CustomTheme.blue),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => ParentCourseDetail(
                                  course: course,
                                  user: widget.user,
                                  student: widget.student))));
                    },
                  ),
                  const Divider(
                    height: 1,
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text('Notes'),
                    subtitle: const Text(
                      'Cliquez pour consulter',
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
                              builder: ((context) => StudentMarkListScreen(
                                  student: widget.student,
                                  user: widget.user,
                                  course: course))));
                    },
                  ),
                  const Divider(
                    height: 1,
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Absences'),
                    subtitle: const Text(
                      'Cliquez pour consulter',
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
                              builder: ((context) => AllStudentAbsences(
                                  user: widget.user,
                                  student: widget.student))));
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
