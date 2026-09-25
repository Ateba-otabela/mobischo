// ignore_for_file: camel_case_types, sort_child_properties_last, prefer_typing_uninitialized_variables, non_constant_identifier_names, use_build_context_synchronously, import_of_legacy_library_into_null_safe, file_names

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/components/screens/teachers.dart/AbsenceDetail.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/conduite_service.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class SortedStudentAbsences extends StatefulWidget {
  final Course course;
  final User user;
  final Student student;
  final String current_date;
  const SortedStudentAbsences(
      {Key? key,
      required this.course,
      required this.user,
      required this.current_date,
      required this.student})
      : super(key: key);

  @override
  State<SortedStudentAbsences> createState() => _SortedStudentAbsencesState();
}

class _SortedStudentAbsencesState extends State<SortedStudentAbsences> {
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

  String _sorted_val = '';

  check_if_empty() {
    ConduiteServices.getSortedCourseAbsences(
            widget.course.CodeEnseignement, widget.current_date)
        .then((absences) {
      if (absences.isEmpty) {
        Fluttertoast.showToast(
            msg:
                "La liste est vide, Veillez faire l'appel de cette date pour pouvoir consulter",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            fontSize: 16.0,
            backgroundColor: Colors.white,
            textColor: CustomTheme.blue);
      }
    });
  }

  _selectSortDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Refer step 1
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      _sorted_val = picked.toString();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: ((context) => SortedStudentAbsences(
                    course: widget.course,
                    student: widget.student,
                    current_date: _sorted_val,
                    user: widget.user,
                  ))));
    }
  }

  @override
  void initState() {
    super.initState;
    check_if_empty();
  }

  String HumanDateFormat(String date) {
    return DateFormat.yMMMd().format(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
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
              return const Text('loading ...');
            } else {
              return Text(
                snapshot.data!.toUpperCase(),
                style: const TextStyle(color: Colors.black),
              );
            }
          },
        ),
        bottom: const PreferredSize(
            preferredSize: Size.zero,
            child: Text("Cliquez sur l'icone du calendrier pour trier")),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                _selectSortDate(context);
              },
              icon: const Icon(
                Icons.calendar_month,
                color: CustomTheme.blue,
              ))
        ],
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
                        // shape: RoundedRectangleBorder(
                        //   borderRadius: BorderRadius.circular(15.0),
                        // ),
                        // elevation: 10,
                        child: InkWell(
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ListTile(
                                leading: const Image(
                                  image: AssetImage('assets/images/menu4.png'),
                                ),
                                title:
                                    Text(HumanDateFormat(widget.current_date)),
                                subtitle: const Text("Date D'appel"),
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }
                                  _selectSortDate(context);
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
              child: absencesList(
            widget: widget,
            isLoaded: isLoaded,
            interstitialAd: _interstitialAd,
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _selectSortDate(context);
        },
        child: const Icon(Icons.calendar_month),
        backgroundColor: CustomTheme.blue,
      ),
    );
  }
}

class absencesList extends StatelessWidget {
  final InterstitialAd? interstitialAd;
  final bool isLoaded;

  const absencesList(
      {Key? key,
      required this.widget,
      required this.interstitialAd,
      required this.isLoaded})
      : super(key: key);

  final SortedStudentAbsences widget;

  String HumanDateFormat(String date) {
    return DateFormat.yMMMd().format(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ConduiteServices.getSortedStudentAbsences(
          widget.course.CodeEnseignement,
          widget.student.CodeEleve,
          widget.current_date.toString()),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Container(
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
                        leading: const Icon(
                          Icons.timer,
                          color: CustomTheme.blue,
                        ),
                        title: FutureBuilder<String>(
                            future: StudentServices.getMainStudent(
                                snapshot.data[index].CodeEleve),
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<String> snapshot,
                            ) {
                              if (snapshot.data == null) {
                                return const Text('loading ...');
                              } else {
                                return Text(
                                  snapshot.data ?? "",
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 13),
                                );
                              }
                            }),
                        subtitle: Text(
                            HumanDateFormat(snapshot.data[index].DateEnreg)),
                        // subtitle: Text("Note: ${snapshot.data[index].valeur}"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          if (isLoaded == true) {
                            interstitialAd!.show();
                          }
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: ((context) => AbsenceDetail(
                                      student: widget.student,
                                      absence: snapshot.data[index]))));
                        },
                      ),
                    ),
                  );
                }),
          );
        }
      },
    );
  }
}
