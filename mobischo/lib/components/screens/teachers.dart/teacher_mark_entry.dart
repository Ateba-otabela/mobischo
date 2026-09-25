import 'package:flutter/material.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/mark.dart';
import 'package:mobischo/models/sequence_evaluation.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/models/year.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/mark_services.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class TeacherMarkEntryScreen extends StatefulWidget {
  final User user;

  const TeacherMarkEntryScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<TeacherMarkEntryScreen> createState() => _TeacherMarkEntryScreenState();
}

class _TeacherMarkEntryScreenState extends State<TeacherMarkEntryScreen> {
  List<Course> _courses = [];
  List<Student> _students = [];
  List<Mark> _marks = [];
  final Map<String, String> _classLabels = {};
  final Map<String, String> _subjectLabels = {};

  String? _selectedClassCode;
  Course? _selectedCourse;
  Year? _selectedYear;
  SequenceEvaluation? _selectedSequence;
  bool _loading = true;
  bool _loadingStudents = false;
  String? _error;

  List<String> get _classCodes => _courses
      .map((course) => course.CodeClasse)
      .where((code) => code.isNotEmpty)
      .toSet()
      .toList();

  List<Course> get _coursesForSelectedClass => _courses
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

      for (final classCode in courses.map((course) => course.CodeClasse).toSet()) {
        _classLabels[classCode] = await CourseServices.getMainClass(classCode);
      }
      for (final subjectCode in courses.map((course) => course.CodeMatiere).toSet()) {
        _subjectLabels[subjectCode] = await CourseServices.getMainCourse(subjectCode);
      }

      if (!mounted) return;
      setState(() {
        _courses = courses;
        _selectedClassCode = courses.isEmpty ? null : courses.first.CodeClasse;
        _selectedYear = years.isEmpty ? null : years.first;
        _selectedSequence = sequences.isEmpty ? null : sequences.first;
        _loading = false;
        _error = null;
      });

      if (_coursesForSelectedClass.isNotEmpty) {
        await _selectCourse(_coursesForSelectedClass.first);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Les notes sont consultables uniquement en lecture.';
      });
    }
  }

  Future<void> _selectCourse(Course course) async {
    setState(() {
      _selectedCourse = course;
      _loadingStudents = true;
      _students = [];
      _marks = [];
    });

    try {
      final students = await StudentServices.getCourseStudents(course.CodeClasse);
      final year = _selectedYear;
      final sequence = _selectedSequence;
      final marks = year != null && sequence != null
          ? await MarkServices.getSortedCourseMarks(
              course.CodeEnseignement,
              sequence.CodeEvaluation.toString(),
              year.CodeAnnee.toString(),
            )
          : <Mark>[];

      if (!mounted) return;
      setState(() {
        _students = students;
        _marks = marks;
        _loadingStudents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingStudents = false;
        _error = 'Impossible de charger les notes pour cette matière.';
      });
    }
  }

  String _classLabel(String code) => _classLabels[code]?.isNotEmpty == true
      ? _classLabels[code]!
      : code;

  String _subjectLabel(String code) => _subjectLabels[code]?.isNotEmpty == true
      ? _subjectLabels[code]!
      : code;

  void _showReadOnlyDialog(Student student) {
    final mark = _marks.firstWhere(
      (item) => item.CodeEleve == student.CodeEleve,
      orElse: () => Mark(
        Codeenseignement: _selectedCourse?.CodeEnseignement ?? '',
        CodeEleve: student.CodeEleve,
        CodeEvaluation: _selectedSequence?.CodeEvaluation.toString() ?? '',
        CodeAppreciation: '',
        valeur: '—',
        coef: _selectedCourse?.Coefficient ?? '',
        total: '',
        Dateeng: '',
        codeannee: _selectedYear?.CodeAnnee.toString() ?? '',
      ),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Note existante'),
          content: Text(
            'Élève : ${student.Nom} ${student.Prenom}\n\nNote : ${mark.valeur == '—' ? 'Aucune' : mark.valeur}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: CustomTheme.blue));
    }
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_courses.isEmpty) {
      return const Center(child: Text('Aucune matière ne vous est actuellement attribuée.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedClassCode,
                decoration: const InputDecoration(labelText: 'Classe'),
                items: _classCodes
                    .map((code) => DropdownMenuItem<String>(
                          value: code,
                          child: Text(_classLabel(code)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedClassCode = value;
                    _selectedCourse = null;
                    _students = [];
                    _marks = [];
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Course>(
                value: _selectedCourse,
                decoration: const InputDecoration(labelText: 'Matière'),
                items: _coursesForSelectedClass
                    .map((course) => DropdownMenuItem<Course>(
                          value: course,
                          child: Text(_subjectLabel(course.CodeMatiere)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _selectCourse(value);
                },
              ),
            ],
          ),
        ),
        if (_loadingStudents)
          const Expanded(child: Center(child: CircularProgressIndicator(color: CustomTheme.blue)))
        else if (_students.isEmpty)
          const Expanded(child: Center(child: Text('Aucune note disponible pour cette matière.')))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final mark = _marks.firstWhere(
                  (item) => item.CodeEleve == student.CodeEleve,
                  orElse: () => Mark(
                    Codeenseignement: _selectedCourse?.CodeEnseignement ?? '',
                    CodeEleve: student.CodeEleve,
                    CodeEvaluation: _selectedSequence?.CodeEvaluation.toString() ?? '',
                    CodeAppreciation: '',
                    valeur: '—',
                    coef: _selectedCourse?.Coefficient ?? '',
                    total: '',
                    Dateeng: '',
                    codeannee: _selectedYear?.CodeAnnee.toString() ?? '',
                  ),
                );
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline, color: CustomTheme.blue),
                    title: Text('${student.Nom} ${student.Prenom}'),
                    trailing: Text(
                      mark.valeur == '—' ? '—' : mark.valeur,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: mark.valeur == '—' ? null : () => _showReadOnlyDialog(student),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
