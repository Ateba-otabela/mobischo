// ignore_for_file: unnecessary_import, implementation_imports, sort_child_properties_last, non_constant_identifier_names

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/parent/allStudentAbsences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mobischo/components/screens/parent/MyChildrenInscription.dart';
import 'package:mobischo/components/screens/students/StudentCourseList.dart';
import 'package:mobischo/components/screens/teachers.dart/CreateConvocation.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/courses.dart';
// ignore: unused_import
import 'package:mobischo/services/services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class StudentDetailScreen extends StatefulWidget {
  final User user;
  final Student student;
  const StudentDetailScreen(
      {Key? key, required this.student, required this.user})
      : super(key: key);

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  String getGender(String sex) {
    if (sex == '0') {
      return "Masculin";
    } else {
      return "Feminin";
    }
  }

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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              BottomForm(context);
            },
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
          )
        ],
        centerTitle: true,
        title: Text(
          getStudentDisplayName(widget.student),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: CustomTheme.blue),
            subtitle: const Text('Noms et Prenoms'),
          ),
          ListTile(
            leading: const Icon(Icons.male_outlined, color: CustomTheme.blue),
            title: Text(getGender(widget.student.Sex)),
            subtitle: const Text('Genre'),
          ),
          ListTile(
            leading: const Icon(Icons.code, color: CustomTheme.blue),
            title: Text(widget.student.CodeEleve),
            subtitle: const Text('Code Eleve'),
          ),
          ListTile(
            leading: const Icon(Icons.home_filled, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future: CourseServices.getMainClass(widget.student.CodeClasse),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return const Text('Loading ...');
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: const Text('Classe'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: CustomTheme.blue),
            title: Text(widget.student.DateNaissance),
            subtitle: const Text("Date de Naissance"),
          ),
          ListTile(
            leading: const Icon(Icons.gps_fixed, color: CustomTheme.blue),
            title: Text(widget.student.LieuNaissance),
            subtitle: const Text("Lieu de Naissance"),
          ),
          ListTile(
              leading: const Icon(Icons.calendar_month_outlined,
                  color: CustomTheme.blue),
              title: Text(widget.student.dateinscription),
              subtitle: const Text("Date d'Inscription"))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            BottomForm(context);
          },
          backgroundColor: CustomTheme.blue,
          child: const Icon(Icons.more_horiz)),
    );
  }

  Future<void> BottomForm(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          if (widget.user.account_type == 'enseignant') {
            return Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading:
                          const Icon(Icons.menu_book, color: CustomTheme.blue),
                      title: const Text('Notes'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => StudentCoursesScreen(
                                      student: widget.student,
                                      user: widget.user,
                                    ))));
                      },
                    ),
                    const Divider(
                      height: 1,
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer, color: CustomTheme.blue),
                      title: const Text('Absences'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => StudentCoursesScreen(
                                      student: widget.student,
                                      user: widget.user,
                                    ))));
                      },
                    ),
                    const Divider(
                      height: 1,
                    ),
                    ListTile(
                        leading: const Icon(Icons.inventory_outlined,
                            color: CustomTheme.blue),
                        title: const Text("Historiques d'Inscriptions"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          if (isLoaded == true) {
                            _interstitialAd!.show();
                          }
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: ((context) => MyChildrenInscriptions(
                                      user: widget.user,
                                      student: widget.student))));
                        }),
                    const Divider(
                      height: 1,
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.menu_book, color: CustomTheme.blue),
                      title: const Text("Matieres"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => StudentCoursesScreen(
                                    user: widget.user,
                                    student: widget.student))));
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.security, color: CustomTheme.blue),
                      title: const Text("Couper une convocation"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => CreateConvocation(
                                    user: widget.user,
                                    student: widget.student))));
                      },
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading:
                          const Icon(Icons.menu_book, color: CustomTheme.blue),
                      title: const Text('Notes'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => StudentCoursesScreen(
                                      student: widget.student,
                                      user: widget.user,
                                    ))));
                      },
                    ),
                    const Divider(
                      height: 1,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.timer,
                        color: CustomTheme.blue,
                      ),
                      title: const Text('Absences'),
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
                                      student: widget.student,
                                      user: widget.user,
                                    ))));
                      },
                    ),
                    const Divider(
                      height: 1,
                    ),
                    ListTile(
                      leading: const Icon(Icons.inventory_outlined,
                          color: CustomTheme.blue),
                      title: const Text("Historiques d'Inscriptions"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => MyChildrenInscriptions(
                                      user: widget.user,
                                      student: widget.student,
                                    ))));
                      },
                    ),
                    const Divider(
                      height: 1,
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.menu_book, color: CustomTheme.blue),
                      title: const Text("Matieres"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => StudentCoursesScreen(
                                    user: widget.user,
                                    student: widget.student))));
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.security, color: CustomTheme.blue),
                      title: const Text("Consulter les convocations"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => StudentCoursesScreen(
                                    user: widget.user,
                                    student: widget.student))));
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        });
      },
    );
  }
}
