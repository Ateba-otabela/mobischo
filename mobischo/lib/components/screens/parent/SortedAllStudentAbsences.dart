// ignore_for_file: camel_case_types, sort_child_properties_last, prefer_typing_uninitialized_variables, non_constant_identifier_names, use_build_context_synchronously, import_of_legacy_library_into_null_safe, file_names

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/parent/allStudentAbsences.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/services/conduite_service.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class SortedAllStudentAbsences extends StatefulWidget {
  final User user;
  final Student student;
  final String current_date;
  const SortedAllStudentAbsences(
      {Key? key,
      required this.user,
      required this.current_date,
      required this.student})
      : super(key: key);

  @override
  State<SortedAllStudentAbsences> createState() =>
      _SortedAllStudentAbsencesState();
}

class _SortedAllStudentAbsencesState extends State<SortedAllStudentAbsences> {
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
    ConduiteServices.getSortedAllStudentAbsences(
            widget.student.CodeEleve, widget.current_date)
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
              builder: ((context) => SortedAllStudentAbsences(
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
          getStudentDisplayName(widget.student),
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
                                trailing: const Image(
                                  image:
                                      AssetImage('assets/images/landing3.png'),
                                ),
                                title:
                                    Text(HumanDateFormat(widget.current_date)),
                                subtitle: Text(uiText(context, 'dateOfCall')),
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
                                                  student: widget.student))));
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
          Flexible(child: absencesList(widget: widget)),
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
  const absencesList({
    Key? key,
    required this.widget,
  }) : super(key: key);

  final SortedAllStudentAbsences widget;

  String HumanDateFormat(String date) {
    return DateFormat.yMMMd().format(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ConduiteServices.getSortedAllStudentAbsences(
          // widget.course.CodeEnseignement,
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
                            future: CourseServices.getMainCourse(
                                snapshot.data[index].CodeMatiere),
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<String> snapshot,
                            ) {
                              if (snapshot.data == null) {
                                return Text(uiText(context, 'loadingEllipsis'));
                              } else {
                                return Text(
                                  snapshot.data ?? "",
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 13),
                                );
                              }
                            }),
                        subtitle: Text(
                          "Date : ${HumanDateFormat(snapshot.data[index].DateEnreg)}",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        // subtitle: Text("Note: ${snapshot.data[index].valeur}"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: ((context) => AbsenceDetail(
                          //             // course: widget.course,
                          //             student: widget.student,
                          //             absence: snapshot.data[index]))));
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
