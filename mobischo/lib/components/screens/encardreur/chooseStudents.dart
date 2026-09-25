// ignore_for_file: non_constant_identifier_names, avoid_print, file_names

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/encardreur/createConvocation.dart';
import 'package:mobischo/models/class.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:flutter/material.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/utils/custom_theme.dart';

class ChooseStudents extends StatefulWidget {
  final Classe classe;
  final User user;

  const ChooseStudents({Key? key, required this.classe, required this.user})
      : super(key: key);

  @override
  State<ChooseStudents> createState() => _ChooseStudentsState();
}

class _ChooseStudentsState extends State<ChooseStudents> {
  String getGender(String sex) {
    if (sex == '0') {
      return "Masculin";
    } else {
      return "Feminin";
    }
  }

  List<Map> list = [];

  List<Map> students = [];
  List<Map> student_list = [];

  List<Map> create_list() {
    StudentServices.getCourseStudents(widget.classe.CodeClasse)
        .then((students) {
      print(students.length);
      for (int i = 0; i < students.length; i++) {
        Map<String, dynamic> map = <String, dynamic>{
          "name": "${students[i].Nom} ${students[i].Prenom}",
          "Sex": students[i].Sex,
          "CodeEleve": students[i].CodeEleve,
          "CodeAnnee": students[i].CodeAnnee,
          "isSelected": false
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

  List<Map> create_checked_list() {
    StudentServices.getCourseStudents(widget.classe.CodeClasse)
        .then((students) {
      print(students.length);
      for (int i = 0; i < students.length; i++) {
        Map<String, dynamic> map = <String, dynamic>{
          "name": "${students[i].Nom} ${students[i].Prenom}",
          "Sex": students[i].Sex,
          "CodeEleve": students[i].CodeEleve,
          "CodeAnnee": students[i].CodeAnnee,
          "isSelected": true
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
  void initState() {
    super.initState();
    setState(() {
      student_list = create_list();
      // print(students);
      // students = student_list;
    });
    // List student_list = absence_list();
  }

  // void insertAbsences() {
  //   print(absences);
  //   ConduiteServices.clearConduite(
  //       widget.course.CodeEnseignement, widget.currentDate);
  //   for (int i = 0; i < absences.length; i++) {
  //     ConduiteServices.AddConduite(
  //         widget.currentDate,
  //         absences[i]['CodeEleve'],
  //         widget.course.NBRHEURE,
  //         absences[i]['CodeAnnee'],
  //         widget.course.CodeClasse,
  //         widget.course.CodeMatiere,
  //         widget.course.CodeEnseignement,
  //         "2");
  //   }
  // }

  bool? checkAll = false;
  void getAllStudents(bool? status) {
    if (status == true) {
      for (var i = 0; i < student_list.length; i++) {
        student_list[i]['isSelected'] = true;
        students.add(student_list[i]);
      }
    } else {
      for (var i = 0; i < student_list.length; i++) {
        student_list[i]['isSelected'] = false;
      }
      students = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // absence_list();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              // color: CustomTheme.blue,
            )),
        title: Text(
          'CONVOQUEZ DES ELEVES',
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
                          onTap: () {
                            if (isLoaded == true) {
                              _interstitialAd!.show();
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ListTile(
                                trailing: Checkbox(
                                  value: checkAll,
                                  onChanged: (value) {
                                    setState(() {
                                      student_list = create_checked_list();
                                      checkAll = value;
                                      getAllStudents(checkAll);
                                    });
                                  },
                                ),
                                title: const Text("ELEVES A CONVOQUER"),
                                subtitle: Text(
                                  "Ne cochez que les eleves a convoquer",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                onTap: () {
                                  // BottomForm(context);
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }
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
                value: hobby["isSelected"],
                title:
                    Text(hobby["name"], style: const TextStyle(fontSize: 13)),
                subtitle: Text(getGender(hobby['Sex']),
                    style: const TextStyle(color: CustomTheme.blue)),
                onChanged: (newValue) {
                  setState(() {
                    hobby["isSelected"] = newValue;
                    if (hobby['isSelected'] == true) {
                      if (students.contains(hobby)) {
                        print('$hobby is present in the list ');
                      } else {
                        students.add(hobby);
                      }
                    } else {
                      students.remove(hobby);
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

          // insertAbsences();

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: ((context) => CreateEncardreurConvocation(
                      user: widget.user,
                      students: students,
                      classe: widget.classe))));
        },
        backgroundColor: CustomTheme.blue,
        child: const Icon(Icons.check),
      ),
    );
  }
}
