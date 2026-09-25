import 'package:flutter/material.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/devoir.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/devoir_service.dart';
import 'package:mobischo/utils/custom_theme.dart';

class TeacherDevoirsScreen extends StatefulWidget {
  final User user;

  const TeacherDevoirsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<TeacherDevoirsScreen> createState() => _TeacherDevoirsScreenState();
}

class _TeacherDevoirsScreenState extends State<TeacherDevoirsScreen> {
  List<Course> _courses = [];
  List<Devoir> _devoirs = [];
  final Map<String, String> _classLabels = {};
  final Map<String, String> _subjectLabels = {};

  String? _selectedClassCode;
  Course? _selectedCourse;
  bool _loading = true;
  bool _loadingDevoirs = false;
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
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await CourseServices.getTeacherCoursesForNotes(widget.user.code);
      for (final classCode in courses.map((course) => course.CodeClasse).toSet()) {
        _classLabels[classCode] = await CourseServices.getMainClass(classCode);
      }
      for (final subjectCode in courses.map((course) => course.CodeMatiere).toSet()) {
        _subjectLabels[subjectCode] = await CourseServices.getMainCourse(subjectCode);
      }
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _selectedClassCode = null;
        _selectedCourse = null;
        _devoirs = [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger vos classes et matières.';
      });
    }
  }

  Future<void> _loadDevoirs() async {
    if (_selectedClassCode == null || _selectedCourse == null) {
      if (!mounted) return;
      setState(() {
        _devoirs = [];
        _loadingDevoirs = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loadingDevoirs = true;
      _error = null;
    });

    try {
      final devoirs = await DevoirServices.getTeacherDevoirs(
        teacherCode: widget.user.code,
        codeClasse: _selectedClassCode,
        codeMatiere: _selectedCourse!.CodeMatiere,
      );
      if (!mounted) return;
      setState(() {
        _devoirs = devoirs;
        _loadingDevoirs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingDevoirs = false;
        _error = 'Impossible de charger les devoirs.';
      });
    }
  }

  Future<void> _showCreateForm() async {
    final course = _selectedCourse;
    if (course == null || _selectedClassCode == null) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool submitting = false;
        final dialogNavigator = Navigator.of(dialogContext, rootNavigator: true);
        final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Nouveau devoir'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titre'),
                  ),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date limite de remise'),
                    subtitle: Text(_formatDate(selectedDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: submitting
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setDialogState(() => selectedDate = date);
                            }
                          },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty) {
                          if (!mounted) return;
                          scaffoldMessenger?.showSnackBar(
                            const SnackBar(content: Text('Le titre est obligatoire.')),
                          );
                          return;
                        }
                        setDialogState(() => submitting = true);
                        final success = await DevoirServices.createTeacherDevoir(
                          teacherCode: widget.user.code,
                          codeEnseignement: course.CodeEnseignement,
                          titre: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          dateDuDevoir: _formatDate(selectedDate),
                        );
                        if (!dialogNavigator.mounted) return;
                        if (success) {
                          dialogNavigator.pop(true);
                        } else {
                          setDialogState(() => submitting = false);
                          if (!mounted) return;
                          scaffoldMessenger?.showSnackBar(
                            const SnackBar(content: Text('Le devoir n\'a pas pu être créé.')),
                          );
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devoir créé avec succès.')),
      );
      await _loadDevoirs();
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _classLabel(String code) => _classLabels[code]?.isNotEmpty == true
      ? _classLabels[code]!
      : code;

  String _subjectLabel(String code) => _subjectLabels[code]?.isNotEmpty == true
      ? _subjectLabels[code]!
      : code;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: CustomTheme.blue));
    }
    if (_error != null && _courses.isEmpty) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_courses.isEmpty) {
      return const Center(child: Text('Aucune classe ne vous est actuellement attribuée.'));
    }

    return Scaffold(
      backgroundColor: CustomTheme.grey,
      floatingActionButton: _selectedCourse == null
          ? null
          : FloatingActionButton(
              onPressed: _showCreateForm,
              backgroundColor: CustomTheme.blue,
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              children: [
                DropdownButtonFormField<String?>(
                  value: _selectedClassCode,
                  decoration: const InputDecoration(labelText: 'Classe'),
                  items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sélectionnez une classe'),
                        ),
                      ] +
                      _classCodes
                          .map((code) => DropdownMenuItem<String?>(
                                value: code,
                                child: Text(_classLabel(code)),
                              ))
                          .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      setState(() {
                        _selectedClassCode = null;
                        _selectedCourse = null;
                        _devoirs = [];
                        _error = null;
                      });
                      return;
                    }

                    setState(() {
                      _selectedClassCode = value;
                      _selectedCourse = null;
                      _devoirs = [];
                      _error = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Course?>(
                  value: _selectedCourse,
                  decoration: const InputDecoration(labelText: 'Matière'),
                  items: [
                    const DropdownMenuItem<Course?>(
                      value: null,
                      child: Text('Sélectionnez une matière'),
                    ),
                    ...(_selectedClassCode == null
                            ? <Course>[]
                            : _coursesForSelectedClass)
                        .map((course) => DropdownMenuItem<Course?>(
                              value: course,
                              child: Text(_subjectLabel(course.CodeMatiere)),
                            )),
                  ],
                  onChanged: (course) {
                    if (course == null) {
                      setState(() {
                        _selectedCourse = null;
                        _devoirs = [];
                        _error = null;
                      });
                      return;
                    }

                    setState(() {
                      _selectedCourse = course;
                      _devoirs = [];
                      _error = null;
                    });
                    _loadDevoirs();
                  },
                ),
              ],
            ),
          ),
          if (_loadingDevoirs)
            const Expanded(child: Center(child: CircularProgressIndicator(color: CustomTheme.blue)))
          else if (_error != null)
            Expanded(child: Center(child: Text(_error!, textAlign: TextAlign.center)))
          else if (_selectedCourse == null)
            const Expanded(
              child: Center(
                child: Text('Sélectionnez une matière pour afficher les devoirs récents.'),
              ),
            )
          else if (_devoirs.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Aucun devoir précédent pour cette classe et cette matière.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                itemCount: _devoirs.length,
                itemBuilder: (context, index) {
                  final devoir = _devoirs[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined, color: CustomTheme.blue),
                      title: Text(devoir.titre),
                      subtitle: Text(
                        'Date limite de remise : ${devoir.dateDuDevoir}\n${devoir.description}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
