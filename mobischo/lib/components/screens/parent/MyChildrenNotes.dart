// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/parent/ParentNotesSequence.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/mark.dart';
import 'package:mobischo/models/sequence_evaluation.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/year.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class MyChildrenNotes extends StatefulWidget {
  final User user;
  final Student? initialStudent;
  final VoidCallback? onBack;

  const MyChildrenNotes({
    Key? key,
    required this.user,
    this.initialStudent,
    this.onBack,
  }) : super(key: key);

  @override
  State<MyChildrenNotes> createState() => _MyChildrenNotesState();
}

class _MyChildrenNotesState extends State<MyChildrenNotes> {
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

  bool isLoaded = false;
  Student? selectedStudent;
  Year? selectedYear;
  SequenceEvaluation? selectedSequence;
  List<Course> selectedSequenceCourses = <Course>[];
  List<Mark> selectedSequenceMarks = <Mark>[];
  int notesStage = 0;
  Future<Year?>? _currentYearFuture;

  @override
  void initState() {
    super.initState();
    if (widget.initialStudent != null) {
      selectedStudent = widget.initialStudent;
      notesStage = 1;
      _currentYearFuture = _getCurrentYear();
    }
  }

  Future<Year?> _getCurrentYear() async {
    final years = await AcademicServices.getYears();
    if (years.isEmpty) {
      return null;
    }

    years.sort((first, second) {
      final firstMatch = RegExp(r'\d{4}').firstMatch(first.Libelle);
      final secondMatch = RegExp(r'\d{4}').firstMatch(second.Libelle);
      final firstStartYear =
          int.tryParse(firstMatch?.group(0) ?? '') ?? first.CodeAnnee;
      final secondStartYear =
          int.tryParse(secondMatch?.group(0) ?? '') ?? second.CodeAnnee;
      final comparison = secondStartYear.compareTo(firstStartYear);
      return comparison != 0
          ? comparison
          : second.CodeAnnee.compareTo(first.CodeAnnee);
    });

    return years.first;
  }

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

  String getGender(String sex, BuildContext context) {
    if (sex == '0') {
      return uiText(context, 'genderMale');
    } else {
      return uiText(context, 'genderFemale');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (notesStage == 1 && selectedStudent != null) {
      return FutureBuilder<Year?>(
        future: _currentYearFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final year = snapshot.data;
          if (year == null) {
            return Center(
                child: Text(uiText(context, 'noSchoolYearAvailable')));
          }

          return ParentNotesSequenceScreen(
            student: selectedStudent!,
            year: year,
            onBack: widget.onBack ??
                () => setState(() {
                      notesStage = 0;
                      selectedStudent = null;
                      _currentYearFuture = null;
                    }),
            onSequenceSelected: (sequence, courses, marks) => setState(() {
              selectedYear = year;
              notesStage = 3;
              selectedSequence = sequence;
              selectedSequenceCourses = courses;
              selectedSequenceMarks = marks;
            }),
          );
        },
      );
    }

    if (notesStage == 3 &&
        selectedStudent != null &&
        selectedYear != null &&
        selectedSequence != null) {
      return ParentSequenceMarksScreen(
        student: selectedStudent!,
        year: selectedYear!,
        sequence: selectedSequence!,
        courses: selectedSequenceCourses,
        marks: selectedSequenceMarks,
        onBack: () => setState(() {
          notesStage = 1;
          selectedSequence = null;
          selectedSequenceCourses = <Course>[];
          selectedSequenceMarks = <Mark>[];
        }),
      );
    }

    return Center(
      child: FutureBuilder(
        future: StudentServices.getParentStudents(widget.user.code),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 12, left: 5, right: 5, bottom: 5),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: CustomTheme.cardShadow),
                    child: ListTile(
                      trailing: const Image(
                          image: AssetImage('assets/images/landing6.png')),
                      title: Text(
                        "Cliquez sur un enfant pour consulter ses notes",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                        // style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                ),
                // Divider(),
                Container(
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
                              leading: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                        image: AssetImage(
                                            'assets/images/avatar-s-19.jpg'),
                                        fit: BoxFit.fill),
                                  )),
                              title: Text(
                                  getStudentDisplayName(snapshot.data[index]),
                                  style: const TextStyle(fontSize: 13)),
                              subtitle: Text(
                                getGender(snapshot.data[index].Sex, context),
                                style: const TextStyle(color: CustomTheme.blue),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                if (isLoaded == true) {
                                  _interstitialAd!.show();
                                }
                                setState(() {
                                  selectedStudent = snapshot.data[index];
                                  notesStage = 1;
                                  _currentYearFuture = _getCurrentYear();
                                });
                              },
                            ),
                          ),
                        );
                      }),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
