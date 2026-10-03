// ignore_for_file: camel_case_types, sort_child_properties_last, prefer_typing_uninitialized_variables, non_constant_identifier_names, use_build_context_synchronously, import_of_legacy_library_into_null_safe

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/components/screens/teachers.dart/create_absences.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/services/conduite_service.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/utils/custom_theme.dart';

class AbsenceListScreen extends StatefulWidget {
  final Course course;
  final User user;
  const AbsenceListScreen({Key? key, required this.course, required this.user})
      : super(key: key);

  @override
  State<AbsenceListScreen> createState() => _AbsenceListScreenState();
}

class _AbsenceListScreenState extends State<AbsenceListScreen> {
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

  String current_date = 'Tous';
  String? _selectedAttendanceDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Refer step 1
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _selectedAttendanceDate = selectedDate;
        current_date = selectedDate;
      });
    }
  }

  Future<void> _openAttendanceForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAbsenceScreen(
          course: widget.course,
          user: widget.user,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {});
    }
  }

  String HumanDateFormat(String date, BuildContext context) {
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(DateTime.parse(date));
  }

  String _displayDate(String date, BuildContext context) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) {
      return date;
    }
    return DateFormat.yMMMMd(Localizations.localeOf(context).toString())
        .format(parsed);
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
              return Text(uiText(context, 'loadingEllipsis'));
            } else {
              return Text(snapshot.data!.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium);
            }
          },
        ),
        // bottom: PreferredSize(
        //     preferredSize: Size.zero,
        //     child: Text(
        //       "Cliquez sur l'icone du calendrier pour trier",
        //       style: Theme.of(context).textTheme.bodyMedium,
        //     )),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                _selectDate(context);
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
                                title: Text(_selectedAttendanceDate == null
                                    ? uiText(context, 'selectDate')
                                    : _displayDate(
                                        _selectedAttendanceDate!,
                                        context,
                                      )),
                                subtitle: Text(uiText(context, 'dateOfCall')),
                                onTap: () async {
                                  _selectDate(context);
                                },
                                trailing: const Image(
                                  image:
                                      AssetImage('assets/images/welcome.png'),
                                ),
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
            current_date: current_date,
            interstitialAd: _interstitialAd,
            isLoaded: isLoaded,
            onEdited: () => setState(() {}),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isLoaded == true) {
            _interstitialAd!.show();
          }
          _openAttendanceForm();
        },
        child: const Icon(Icons.add),
        backgroundColor: CustomTheme.blue,
      ),
    );
  }
}

class absencesList extends StatelessWidget {
  final current_date;
  final InterstitialAd? interstitialAd;
  final bool isLoaded;
  final VoidCallback onEdited;

  const absencesList(
      {Key? key,
      required this.widget,
      required this.current_date,
      required this.interstitialAd,
      required this.isLoaded,
      required this.onEdited})
      : super(key: key);

  final AbsenceListScreen widget;

  String HumanDateFormat(String date, BuildContext context) {
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ConduiteServices.getTeacherAttendance(
          widget.user.code,
          widget.course.CodeEnseignement,
          current_date == 'Tous' ? null : current_date),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: CustomTheme.blue),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 42),
                  SizedBox(height: 12),
                  Text(
                    uiText(context, 'attendanceNotLoaded'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    uiText(context, 'attendanceLoadError'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final records = snapshot.data as List<dynamic>? ?? <dynamic>[];
        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_available,
                      color: CustomTheme.blue, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    current_date == 'Tous'
                        ? uiText(context, 'noCallRecorded')
                        : uiText(context, 'noCallForDate'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    current_date == 'Tous'
                        ? uiText(context, 'noCallYetForSubject')
                        : uiText(context, 'noCallForSubjectDate'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final dates = <String>[];
        final recordsByDate = <String, List<dynamic>>{};
        for (final record in records) {
          final date = record.DateEnreg.toString();
          recordsByDate.putIfAbsent(date, () => <dynamic>[]).add(record);
        }
        dates.addAll(recordsByDate.keys);
        dates.sort((first, second) => second.compareTo(first));

        return Container(
          color: CustomTheme.grey,
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: dates.length,
              itemBuilder: (BuildContext context, int index) {
                final date = dates[index];
                final dateRecords = recordsByDate[date]!;
                final absent = dateRecords
                    .where((record) =>
                        record.CodeEtatCond == 'A' ||
                        record.CodeEtatCond.isEmpty)
                    .length;
                final late = dateRecords
                    .where((record) => record.CodeEtatCond == 'R')
                    .length;
                final present = dateRecords.length - absent - late;
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
                      title: Text(HumanDateFormat(date, context)),
                      subtitle: Text(uiText(
                        context,
                        'presentAbsentLateCount',
                        parameters: <String, String>{
                          'present': '$present',
                          'absent': '$absent',
                          'late': '$late',
                        },
                      )),
                      // subtitle: Text("Note: ${snapshot.data[index].valeur}"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        if (isLoaded == true) {
                          interstitialAd!.show();
                        }
                        await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => CreateAbsenceScreen(
                                      user: widget.user,
                                      course: widget.course,
                                      absenceDate: date,
                                    ))));
                        onEdited();
                      },
                    ),
                  ),
                );
              }),
        );
      },
    );
  }
}
