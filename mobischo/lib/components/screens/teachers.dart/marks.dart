import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/mark.dart';
import 'package:mobischo/models/sequence_evaluation.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/models/year.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/mark_services.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class MarkScreen extends StatefulWidget {
  final User user;
  const MarkScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<MarkScreen> createState() => _MarkScreenState();
}

class _MarkScreenState extends State<MarkScreen> {
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

  bool isLoaded = false;
  bool _loading = true;
  bool _loadingMarks = false;
  String? _error;

  String _step = 'classes';
  List<Course> _courses = [];
  List<Mark> _marks = [];
  List<Student> _students = [];
  List<SequenceEvaluation> _sequences = [];
  final Map<String, List<Mark>> _marksBySequence = {};

  final Map<String, String> _classLabels = {};
  final Map<String, String> _subjectLabels = {};

  String? _selectedClassCode;
  Course? _selectedCourse;
  Year? _selectedYear;
  SequenceEvaluation? _selectedSequence;

  List<String> get _classCodes => _courses
      .map((course) => course.CodeClasse)
      .where((code) => code.isNotEmpty)
      .toSet()
      .toList();

  List<Course> get _subjectsForSelectedClass => _courses
      .where((course) => course.CodeClasse == _selectedClassCode)
      .toList();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        CourseServices.getTeacherCoursesForNotes(widget.user.code),
        AcademicServices.getYears(),
        AcademicServices.getSequences(),
      ]);

      final courses = results[0] as List<Course>;
      final years = results[1] as List<Year>;
      final sequences = results[2] as List<SequenceEvaluation>;

      await Future.wait([
        ...courses.map((course) => course.CodeClasse).toSet().map(
          (classCode) async {
            _classLabels[classCode] =
                await CourseServices.getMainClass(classCode);
          },
        ),
        ...courses.map((course) => course.CodeMatiere).toSet().map(
          (subjectCode) async {
            _subjectLabels[subjectCode] =
                await CourseServices.getMainCourse(subjectCode);
          },
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _courses = courses;
        _sequences = sequences;
        _selectedYear = years.isEmpty ? null : years.first;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiText(context, 'marksLoadError');
      });
    }
  }

  Future<void> _selectClass(String classCode) async {
    final classCourses =
        _courses.where((course) => course.CodeClasse == classCode).toList();
    setState(() {
      _selectedClassCode = classCode;
      _selectedCourse = classCourses.isEmpty ? null : classCourses.first;
      _step = 'subjects';
      _marks = [];
      _students = [];
    });
  }

  Future<void> _selectSubject(Course course) async {
    setState(() {
      _selectedCourse = course;
      _step = 'semesters';
      _loadingMarks = true;
      _error = null;
    });
    await _loadSequenceAvailability();
  }

  Future<void> _loadSequenceAvailability() async {
    final course = _selectedCourse;
    final year = _selectedYear;
    if (course == null || year == null) {
      setState(() {
        _loadingMarks = false;
      });
      return;
    }

    try {
      final marks = await MarkServices.getCourseYearMarksForNotes(
        course.CodeEnseignement,
        year.CodeAnnee.toString(),
      );
      final availability = <String, List<Mark>>{
        for (final sequence in _sequences)
          sequence.CodeEvaluation.toString(): marks
              .where((mark) =>
                  mark.CodeEvaluation == sequence.CodeEvaluation.toString())
              .toList(),
      };
      if (!mounted) return;
      setState(() {
        _marksBySequence
          ..clear()
          ..addAll(availability);
        _loadingMarks = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMarks = false;
        _error = uiText(context, 'subjectMarksLoadError');
      });
    }
  }

  Future<void> _selectSequence(SequenceEvaluation sequence) async {
    setState(() {
      _selectedSequence = sequence;
      _step = 'marks';
      _loadingMarks = true;
      _error = null;
    });
    await _loadMarksForSelectedSubject();
  }

  Future<void> _loadMarksForSelectedSubject() async {
    final course = _selectedCourse;
    final year = _selectedYear;
    final sequence = _selectedSequence;

    if (course == null || year == null || sequence == null) {
      if (mounted) {
        setState(() {
          _loadingMarks = false;
        });
      }
      return;
    }

    try {
      final students =
          await StudentServices.getCourseStudents(course.CodeClasse);

      if (!mounted) return;
      setState(() {
        _marks =
            _marksBySequence[sequence.CodeEvaluation.toString()] ?? <Mark>[];
        _students = students;
        _loadingMarks = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMarks = false;
        _error = uiText(context, 'subjectMarksLoadError');
      });
    }
  }

  void _goBackOneLevel() {
    if (_step == 'marks') {
      setState(() {
        _step = 'semesters';
        _marks = [];
      });
    } else if (_step == 'semesters') {
      setState(() {
        _step = 'subjects';
        _selectedCourse = null;
        _marksBySequence.clear();
      });
    } else if (_step == 'subjects') {
      setState(() {
        _step = 'classes';
        _selectedClassCode = null;
        _selectedCourse = null;
      });
    }
  }

  String _classLabel(String code) =>
      _classLabels[code]?.isNotEmpty == true ? _classLabels[code]! : code;

  String _subjectLabel(String code) =>
      _subjectLabels[code]?.isNotEmpty == true ? _subjectLabels[code]! : code;

  Future<void> _showReadOnlyMarkDialog(String studentCode) async {
    final student = _students.firstWhere(
      (item) => item.CodeEleve == studentCode,
      orElse: () => Student(
        CodeEleve: studentCode,
        CodeAnnee: _selectedYear?.CodeAnnee.toString() ?? '',
        CodeClasse: _selectedClassCode ?? '',
        code: '',
        CodeConduite: '',
        Nom: '',
        Prenom: '',
        DateNaissance: '',
        LieuNaissance: '',
        Sex: '',
        Nationalite: '',
        dateinscription: '',
        photo: '',
        Excl: '',
        Nomp: '',
        TelP: '',
        Image: '',
        strimage: '',
        Nomm: '',
        REGION: '',
        DEPART: '',
        RELIGION: '',
        SITREG: '',
        ACTIVEEPS: '',
        PROFP: '',
        NOMT: '',
        PROFM: '',
        ADRESSE: '',
        RESIDENT: '',
        TELM: '',
        TELT: '',
        PERSONCON: '',
        RESERVE1: '',
        RESERVE2: '',
        RESERVE3: '',
        RESERVE4: '',
      ),
    );
    final existingMark = _marks.firstWhere(
      (mark) => mark.CodeEleve == studentCode,
      orElse: () => Mark(
        Codeenseignement: _selectedCourse?.CodeEnseignement ?? '',
        CodeEleve: studentCode,
        CodeEvaluation: _selectedSequence?.CodeEvaluation.toString() ?? '',
        CodeAppreciation: '',
        valeur: '—',
        coef: _selectedCourse?.Coefficient ?? '',
        total: '',
        Dateeng: '',
        codeannee: _selectedYear?.CodeAnnee.toString() ?? '',
      ),
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(uiText(context, 'existingMark')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${student.Nom} ${student.Prenom}'.trim()),
              const SizedBox(height: 12),
              Text(uiText(
                context,
                'noteLabel',
                parameters: <String, String>{
                  'value': existingMark.valeur == '—'
                      ? uiText(context, 'noMark')
                      : existingMark.valeur,
                },
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(uiText(context, 'close')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: CustomTheme.blue));
    }

    if (_error != null && _courses.isEmpty) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }

    if (_courses.isEmpty) {
      return Center(child: Text(uiText(context, 'noAssignedSubjects')));
    }

    final currentTitle = _step == 'classes'
        ? uiText(context, 'marksByClass')
        : _step == 'subjects'
            ? uiText(context, 'marksBySubject')
            : _step == 'semesters'
                ? uiText(context, 'marksBySemesters')
                : uiText(context, 'grades');

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  if (_step != 'classes')
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: CustomTheme.blue),
                      onPressed: _goBackOneLevel,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      currentTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _step == 'classes'
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: _classCodes.length,
                      itemBuilder: (context, index) {
                        final classCode = _classCodes[index];
                        return Card(
                          child: ListTile(
                            title: Text(_classLabel(classCode)),
                            subtitle: Text(uiText(
                              context,
                              'classLabel',
                              parameters: <String, String>{
                                'className': classCode,
                              },
                            )),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _selectClass(classCode),
                          ),
                        );
                      },
                    )
                  : _step == 'subjects'
                      ? ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _subjectsForSelectedClass.length,
                          itemBuilder: (context, index) {
                            final course = _subjectsForSelectedClass[index];
                            return Card(
                              child: ListTile(
                                title: Text(_subjectLabel(course.CodeMatiere)),
                                subtitle: Text(course.CodeEnseignement),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _selectSubject(course),
                              ),
                            );
                          },
                        )
                      : _step == 'semesters'
                          ? _loadingMarks
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: CustomTheme.blue,
                                  ),
                                )
                              : _error != null
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(_error!),
                                          TextButton(
                                            onPressed: _selectedCourse == null
                                                ? null
                                                : () => _selectSubject(
                                                    _selectedCourse!),
                                            child:
                                                Text(uiText(context, 'retry')),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 0, 12, 12),
                                      itemCount: _sequences.length,
                                      itemBuilder: (context, index) {
                                        final sequence = _sequences[index];
                                        final sequenceMarks = _marksBySequence[
                                                sequence.CodeEvaluation
                                                    .toString()] ??
                                            [];
                                        final hasMarks =
                                            sequenceMarks.isNotEmpty;
                                        return Card(
                                          child: ListTile(
                                            title: Text(
                                                sequence.LibelleEvaluation),
                                            subtitle: Text(hasMarks
                                                ? uiText(
                                                    context, 'marksAvailable')
                                                : uiText(context,
                                                    'noMarksForSubject')),
                                            leading: Icon(
                                              hasMarks
                                                  ? Icons.check_circle_outline
                                                  : Icons.info_outline,
                                              color: hasMarks
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                            trailing: const Icon(
                                                Icons.arrow_forward_ios),
                                            onTap: () =>
                                                _selectSequence(sequence),
                                          ),
                                        );
                                      },
                                    )
                          : _loadingMarks
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: CustomTheme.blue))
                              : _error != null
                                  ? Center(child: Text(_error!))
                                  : (_students.isEmpty || _marks.isEmpty)
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.menu_book_outlined,
                                                  size: 48,
                                                  color: CustomTheme.blue,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  uiText(
                                                      context, 'noMarksForNow'),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  uiText(context,
                                                      'marksNotPublished'),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 0, 12, 12),
                                          itemCount: _students.length,
                                          itemBuilder: (context, index) {
                                            final student = _students[index];
                                            final existingMark =
                                                _marks.firstWhere(
                                              (mark) =>
                                                  mark.CodeEleve ==
                                                  student.CodeEleve,
                                              orElse: () => Mark(
                                                Codeenseignement: _selectedCourse
                                                        ?.CodeEnseignement ??
                                                    '',
                                                CodeEleve: student.CodeEleve,
                                                CodeEvaluation:
                                                    _selectedSequence
                                                            ?.CodeEvaluation
                                                            .toString() ??
                                                        '',
                                                CodeAppreciation: '',
                                                valeur: '—',
                                                coef: _selectedCourse
                                                        ?.Coefficient ??
                                                    '',
                                                total: '',
                                                Dateeng: '',
                                                codeannee: _selectedYear
                                                        ?.CodeAnnee
                                                        .toString() ??
                                                    '',
                                              ),
                                            );
                                            return Card(
                                              child: ListTile(
                                                leading: const Icon(
                                                    Icons.person_outline,
                                                    color: CustomTheme.blue),
                                                title: Text(
                                                    '${student.Nom} ${student.Prenom}'),
                                                trailing: Text(
                                                  existingMark.valeur == '—'
                                                      ? '—'
                                                      : existingMark.valeur,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                onTap: existingMark.valeur ==
                                                        '—'
                                                    ? null
                                                    : () =>
                                                        _showReadOnlyMarkDialog(
                                                            student.CodeEleve),
                                              ),
                                            );
                                          },
                                        ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-2496623977736610/2133664237',
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
      ),
    );
  }
}
