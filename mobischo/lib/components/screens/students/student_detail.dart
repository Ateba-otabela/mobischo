// ignore_for_file: unnecessary_import, implementation_imports, sort_child_properties_last, non_constant_identifier_names

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/parent/allStudentAbsences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mobischo/components/screens/parent/MyChildrenInscription.dart';
import 'package:mobischo/components/screens/students/StudentCourseList.dart';
import 'package:mobischo/components/screens/students/student_sequence_notes_screen.dart';
import 'package:mobischo/components/screens/teachers.dart/CreateConvocation.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
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
  bool get _usesConsolidatedNotes {
    final accountType = widget.user.account_type.trim().toLowerCase();
    return accountType == 'parent' ||
        accountType == 'principal' ||
        accountType == 'principal_encadreur' ||
        accountType == 'administrateur' ||
        widget.user.admin == '1' ||
        widget.user.admin.toLowerCase() == 'true';
  }

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
            subtitle: Text(uiText(context, 'firstAndLastNames')),
          ),
          ListTile(
            leading: const Icon(Icons.male_outlined, color: CustomTheme.blue),
            title: Text(getGender(widget.student.Sex)),
            subtitle: Text(uiText(context, 'gender')),
          ),
          ListTile(
            leading: const Icon(Icons.code, color: CustomTheme.blue),
            title: Text(widget.student.CodeEleve),
            subtitle: Text(uiText(context, 'studentCode')),
          ),
          ListTile(
            leading: const Icon(Icons.home_filled, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future: CourseServices.getMainClass(widget.student.CodeClasse),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return Text(uiText(context, 'loadingEllipsis'));
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: Text(uiText(context, 'className')),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: CustomTheme.blue),
            title: Text(widget.student.DateNaissance),
            subtitle: Text(uiText(context, 'birthDate')),
          ),
          ListTile(
            leading: const Icon(Icons.gps_fixed, color: CustomTheme.blue),
            title: Text(widget.student.LieuNaissance),
            subtitle: Text(uiText(context, 'birthPlace')),
          ),
          ListTile(
              leading: const Icon(Icons.calendar_month_outlined,
                  color: CustomTheme.blue),
              title: Text(widget.student.dateinscription),
              subtitle: Text(uiText(context, 'enrollmentDate')))
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
                      title: Text(uiText(context, 'notes')),
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
                      title: Text(uiText(context, 'absences')),
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
                        title: Text(uiText(context, 'enrollmentHistory')),
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
                      title: Text(uiText(context, 'subjectsLabel')),
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
                      title: Text(uiText(context, 'convoke')),
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
                      title: Text(uiText(context, 'notes')),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => _usesConsolidatedNotes
                                    ? StudentSequenceNotesScreen(
                                        student: widget.student,
                                      )
                                    : StudentCoursesScreen(
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
                      title: Text(uiText(context, 'absences')),
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
                      title: Text(uiText(context, 'enrollmentHistory')),
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
                      title: Text(uiText(context, 'subjectsLabel')),
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
                      title: Text(uiText(context, 'consultConvocations')),
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
