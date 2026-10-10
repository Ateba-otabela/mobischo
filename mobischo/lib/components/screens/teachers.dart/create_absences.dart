// ignore_for_file: non_constant_identifier_names, avoid_print, import_of_legacy_library_into_null_safe

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/conduite_service.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/l10n/ui_text.dart';

class CreateAbsenceScreen extends StatefulWidget {
  final Course course;
  final String? absenceDate;
  final User user;

  const CreateAbsenceScreen(
      {Key? key, required this.course, this.absenceDate, required this.user})
      : super(key: key);

  @override
  State<CreateAbsenceScreen> createState() => _CreateAbsenceScreenState();
}

class _CreateAbsenceScreenState extends State<CreateAbsenceScreen> {
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
  List student_list = [];
  Map<String, String> statuses = {};
  Map<String, String> recordIds = {};
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    selectedAttendanceDate =
        widget.absenceDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadAttendance();
  }

  String? selectedAttendanceDate;

  Future<void> _loadAttendance() async {
    final students = await StudentServices.getCourseStudents(
      widget.course.CodeClasse,
    );
    final records = await ConduiteServices.getTeacherAttendance(
      widget.user.code,
      widget.course.CodeEnseignement,
      selectedAttendanceDate ?? widget.absenceDate,
    );
    final saved = records;

    if (!mounted) return;
    setState(() {
      student_list = students;
      for (final student in students) {
        statuses[student.CodeEleve] = 'P';
      }
      for (final record in saved) {
        recordIds[record.CodeEleve] = record.CodeConduite;
        statuses[record.CodeEleve] =
            record.CodeEtatCond.isEmpty ? 'A' : record.CodeEtatCond;
      }
      loading = false;
    });
  }

  Future<void> _saveAttendance() async {
    if (student_list.isEmpty) return;
    setState(() => saving = true);
    final date = selectedAttendanceDate ?? widget.absenceDate!;
    final success = widget.absenceDate != null
        ? await ConduiteServices.updateTeacherAttendance(
            teacherCode: widget.user.code,
            date: date,
            codeEnseignement: widget.course.CodeEnseignement,
            records: student_list
                .where((student) => recordIds.containsKey(student.CodeEleve))
                .map<Map<String, String>>((student) => {
                      'id': recordIds[student.CodeEleve]!,
                      'status': statuses[student.CodeEleve] ?? 'P',
                    })
                .toList(),
          )
        : await ConduiteServices.saveTeacherAttendance(
            teacherCode: widget.user.code,
            date: date,
            codeAnnee: student_list.first.CodeAnnee,
            codeEnseignement: widget.course.CodeEnseignement,
            statuses: student_list
                .map<Map<String, String>>((student) => {
                      'CodeEleve': student.CodeEleve,
                      'status': statuses[student.CodeEleve] ?? 'P',
                    })
                .toList(),
          );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiText(context, 'attendanceSaveFailed'))),
      );
    }
  }

  String HumanDateFormat(String date) {
    return DateFormat.yMMMd().format(DateTime.parse(date));
  }

  String _displayDate(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) {
      return date;
    }
    return DateFormat(
      'd MMMM yyyy',
      Localizations.localeOf(context).toString(),
    ).format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final attendanceDate = selectedAttendanceDate!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: CustomTheme.blue,
          ),
        ),
        title: FutureBuilder<String>(
          future: CourseServices.getMainCourse(widget.course.CodeMatiere),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return Text(uiText(context, 'loadingEllipsis'));
            }
            return Text(
              snapshot.data!.toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium,
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              "Enregistrer l'appel pour ${_displayDate(attendanceDate)}",
              style: const TextStyle(color: CustomTheme.blue),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 10,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(
                        "Enregistrer l'appel pour ${_displayDate(attendanceDate)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        "Ne cochez que les eleves absents",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: const SizedBox(
                        width: 28,
                        child: Image(
                          image: AssetImage('assets/images/menu4.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : student_list.isEmpty
                      ? Center(
                          child: Text(uiText(context, 'noStudentsForSubject')),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 8,
                            right: 8,
                            bottom: 88,
                          ),
                          itemCount: student_list.length,
                          itemBuilder: (context, index) {
                            final student = student_list[index];
                            final status = statuses[student.CodeEleve] ?? 'P';

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 3,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${student.Nom} ${student.Prenom}'
                                            .trim(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          _statusChoice(
                                            student.CodeEleve,
                                            status,
                                            'P',
                                            uiText(context, 'present'),
                                          ),
                                          _statusChoice(
                                            student.CodeEleve,
                                            status,
                                            'A',
                                            uiText(
                                                context, 'absentStatusLabel'),
                                          ),
                                          _statusChoice(
                                            student.CodeEleve,
                                            status,
                                            'R',
                                            uiText(context, 'lateStatusLabel'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (loading || saving) return;
          if (isLoaded == true) {
            _interstitialAd!.show();
          }
          _saveAttendance();
        },
        backgroundColor: CustomTheme.blue,
        child: saving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
    );
  }

  Widget _statusChoice(
      String codeEleve, String selected, String value, String label) {
    final isSelected = selected == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => setState(() => statuses[codeEleve] = value),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: CustomTheme.blue,
              onChanged: (_) => setState(() => statuses[codeEleve] = value),
            ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? CustomTheme.blue : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
