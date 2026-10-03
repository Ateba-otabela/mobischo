// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/teachers.dart/absences_success.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/conduite_service.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/l10n/ui_text.dart';

class ModifyAbsenceScreen extends StatefulWidget {
  final Course course;
  final String currentDate;
  final User user;

  const ModifyAbsenceScreen(
      {Key? key,
      required this.course,
      required this.currentDate,
      required this.user})
      : super(key: key);

  @override
  State<ModifyAbsenceScreen> createState() => _ModifyAbsenceScreenState();
}

class _ModifyAbsenceScreenState extends State<ModifyAbsenceScreen> {
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

  List<Map> list = [];

  List<Map> absences = [];
  List<Map> student_list = [];

  List<Map> absence_list() {
    ConduiteServices.getSortedCourseAbsentStudents(
            widget.course.CodeEnseignement, widget.currentDate)
        .then((students) {
      print(students.length);
      for (int i = 0; i < students.length; i++) {
        Map<String, dynamic> map = <String, dynamic>{
          "name": "${students[i].Nom} ${students[i].Prenom}",
          "Sex": students[i].Sex,
          "CodeEleve": students[i].CodeEleve,
          "CodeAnnee": students[i].CodeAnnee,
          "isAbsent": true
        };
        // print(map);
        list.add(map);
        print(list);
      }
      // print(list);
      setState(() {
        student_list = list;
      });
      return list;
    });
    return list;
  }

  // String HumanDateFormat(String date) {
  //   return DateFormat.yMMMd().format(DateTime.parse(date));
  // }

  @override
  void initState() {
    super.initState();
    setState(() {
      student_list = absence_list();
      absences = student_list;
    });
    // List student_list = absence_list();
  }

  void insertAbsences() {
    print(absences);
    ConduiteServices.clearConduite(
        widget.course.CodeEnseignement, widget.currentDate);
    for (int i = 0; i < absences.length; i++) {
      ConduiteServices.AddConduite(
          widget.currentDate,
          absences[i]['CodeEleve'],
          widget.course.NBRHEURE,
          absences[i]['CodeAnnee'],
          widget.course.CodeClasse,
          widget.course.CodeMatiere,
          widget.course.CodeEnseignement,
          "2");
    }
  }

  @override
  Widget build(BuildContext context) {
    // absence_list();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: CustomTheme.blue,
            )),
        title: FutureBuilder<String>(
          future: CourseServices.getMainCourse(widget.course.CodeMatiere),
          builder: (
            BuildContext context,
            AsyncSnapshot<String> snapshot,
          ) {
            if (snapshot.data == null) {
              return Text(uiText(context, 'loadingEllipsis'));
            } else {
              return Text(
                snapshot.data!.toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium,
              );
            }
          },
        ),
        bottom: PreferredSize(
            preferredSize: Size.zero,
            child: Text(uiText(context, 'dateLabel', parameters: {
              'date': widget.currentDate,
            }))),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: CustomTheme.grey,
            // decoration: CustomTheme.getCardDecoration(),
            height: 80,
            width: double.infinity,
            // color: CustomTheme.blue,
            child: Column(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                        child: SizedBox(
                      width: double.infinity,
                      height: 80,
                      // padding: const EdgeInsets.all(2.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 10,
                        child: InkWell(
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ListTile(
                                leading: const Image(
                                  image: AssetImage('assets/images/menu4.png'),
                                ),
                                title: Text(uiText(context, 'editAbsences')),
                                subtitle: const Text(
                                    "Ne cochez que les eleves absents"),
                                onTap: () {
                                  // BottomForm(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ))
                  ],
                ),
              ],
            ),
          ),
          // const Divider(
          //   height: 10,
          //   color: CustomTheme.grey,
          // ),
          Flexible(
              child: ListView(
                  children: student_list.map((hobby) {
            return CheckboxListTile(
                value: hobby["isAbsent"],
                title:
                    Text(hobby["name"], style: const TextStyle(fontSize: 13)),
                subtitle: Text(getGender(hobby['Sex']),
                    style: const TextStyle(color: CustomTheme.blue)),
                onChanged: (newValue) {
                  setState(() {
                    hobby["isAbsent"] = newValue;
                    if (hobby['isAbsent'] == true) {
                      if (absences.contains(hobby)) {
                        print('$hobby is present in the list ');
                      } else {
                        absences.add(hobby);
                      }
                    } else {
                      absences.remove(hobby);
                    }
                    // print(absences);
                    // print(list);
                  });
                });
          }).toList()))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // filter_absences

          insertAbsences();

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: ((context) => AbsenceSuccess(
                        user: widget.user,
                        course: widget.course,
                      ))));
        },
        backgroundColor: CustomTheme.blue,
        child: const Icon(Icons.check),
      ),
    );
  }
}
