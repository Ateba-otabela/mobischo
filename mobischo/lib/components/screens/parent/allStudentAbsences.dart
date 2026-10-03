// ignore_for_file: camel_case_types, sort_child_properties_last, prefer_typing_uninitialized_variables, non_constant_identifier_names, use_build_context_synchronously, import_of_legacy_library_into_null_safe, file_names

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/parent/SortedAllStudentAbsences.dart';
import 'package:mobischo/components/screens/teachers.dart/AbsenceDetail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/services/conduite_service.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class AllStudentAbsences extends StatefulWidget {
  final Student student;
  final User user;
  const AllStudentAbsences(
      {Key? key, required this.user, required this.student})
      : super(key: key);

  @override
  State<AllStudentAbsences> createState() => _AllStudentAbsencesState();
}

class _AllStudentAbsencesState extends State<AllStudentAbsences> {
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

  String current_date = 'Tous';

  String _sorted_val = '';

  _selectSortDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Refer step 1
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      _sorted_val = picked.toString();
      setState(() {
        current_date = _sorted_val;
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: ((context) => SortedAllStudentAbsences(
                  user: widget.user,
                  student: widget.student,
                  current_date: current_date))));
    }
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
                                      AssetImage('assets/images/welcome.png'),
                                ),
                                title: Text(current_date),
                                subtitle:
                                    Text(uiText(context, 'recordedOnDate')),
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

  const absencesList({
    Key? key,
    required this.widget,
    required this.interstitialAd,
    required this.isLoaded,
  }) : super(key: key);

  final AllStudentAbsences widget;

  String HumanDateFormat(String date) {
    return DateFormat.yMMMd().format(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ConduiteServices.getAllStudentAbsences(widget.student.CodeEleve),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Container(
            color: CustomTheme.grey,
            child: snapshot.data.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: CustomTheme.cardShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/landing3.png',
                              height: 110,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              uiText(context, 'noAbsenceOrLate'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF424242),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              uiText(context, 'absenceSummaryClear'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF757575),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
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
                                    return Text(
                                        uiText(context, 'loadingEllipsis'));
                                  } else {
                                    return Text(
                                      snapshot.data ?? "",
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
                              if (isLoaded == true) {
                                interstitialAd!.show();
                              }
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: ((context) => AbsenceDetail(
                                          // course: widget.course,
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
