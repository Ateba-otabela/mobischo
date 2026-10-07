import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/students/student_detail.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/models/class.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/principal_service.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class PrincipalStudentClassesPage extends StatefulWidget {
  final User user;

  const PrincipalStudentClassesPage({Key? key, required this.user})
      : super(key: key);

  @override
  State<PrincipalStudentClassesPage> createState() =>
      _PrincipalStudentClassesPageState();
}

class _PrincipalStudentClassesPageState
    extends State<PrincipalStudentClassesPage> {
  late Future<List<PrincipalClassSummary>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = PrincipalService.getClasses(widget.user);
  }

  void _retry() {
    setState(() {
      _classesFuture = PrincipalService.getClasses(widget.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrincipalClassSummary>>(
      future: _classesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _LoadError(
            message: uiText(context, 'classesLoadError'),
            onRetry: _retry,
          );
        }

        final classes = (snapshot.data ?? <PrincipalClassSummary>[])
            .where((schoolClass) => schoolClass.codeClasse.trim().isNotEmpty)
            .toList();
        if (classes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                uiText(context, 'noClassAvailable'),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(
              uiText(context, 'chooseClassToViewStudents'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...classes.map(
              (schoolClass) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F0FE),
                    child: Icon(Icons.class_outlined, color: CustomTheme.blue),
                  ),
                  title: Text(
                    schoolClass.name.trim().isEmpty
                        ? schoolClass.codeClasse
                        : schoolClass.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (schoolClass.name.trim().isNotEmpty &&
                          schoolClass.name != schoolClass.codeClasse)
                        Text(
                          uiText(
                            context,
                            'classCode',
                            parameters: <String, String>{
                              'code': schoolClass.codeClasse,
                            },
                          ),
                        ),
                      Text(
                        uiText(
                          context,
                          'studentCount',
                          parameters: <String, String>{
                            'count': '${schoolClass.studentCount}',
                          },
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    final classe = Classe(
                      LibelleClasse: schoolClass.name,
                      CodeClasse: schoolClass.codeClasse,
                      CodeTypeClasse: '',
                      CodeCycle: '',
                      CodeSpecialite: '',
                      codetypeinscrip: '',
                      CodeEtablissement: widget.user.CodeEtablissement,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PrincipalClassStudentsPage(
                          user: widget.user,
                          classe: classe,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PrincipalClassStudentsPage extends StatefulWidget {
  final User user;
  final Classe classe;

  const PrincipalClassStudentsPage({
    Key? key,
    required this.user,
    required this.classe,
  }) : super(key: key);

  @override
  State<PrincipalClassStudentsPage> createState() =>
      _PrincipalClassStudentsPageState();
}

class _PrincipalClassStudentsPageState
    extends State<PrincipalClassStudentsPage> {
  late Future<List<Student>> _studentsFuture;
  String _searchQuery = '';
  String _selectedGender = 'all';

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
  }

  Future<List<Student>> _loadStudents() {
    return StudentServices.getPrincipalClassStudents(
      widget.classe.CodeClasse,
      code: widget.user.code,
      codeEtablissement: widget.user.CodeEtablissement,
    );
  }

  void _retry() {
    setState(() {
      _studentsFuture = _loadStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        title: Text(
          widget.classe.LibelleClasse.trim().isEmpty
              ? widget.classe.CodeClasse
              : widget.classe.LibelleClasse,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Student>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(
              message: uiText(context, 'retryLoadingStudents'),
              onRetry: _retry,
            );
          }

          final students = (snapshot.data ?? <Student>[])
              .where((student) =>
                  student.CodeClasse.trim() == widget.classe.CodeClasse)
              .toList();
          if (students.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  uiText(context, 'noStudentsInClass'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final visibleStudents = students.where(_matchesFilters).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    labelText: uiText(context, 'searchStudents'),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: uiText(context, 'filterByGender'),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(uiText(context, 'allStudents')),
                    ),
                    DropdownMenuItem(
                      value: 'male',
                      child: Text(uiText(context, 'male')),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text(uiText(context, 'female')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGender = value);
                    }
                  },
                ),
              ),
              Expanded(
                child: visibleStudents.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            uiText(context, 'studentSearchEmpty'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        itemCount: visibleStudents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final student = visibleStudents[index];
                          final name = getStudentDisplayName(student);
                          final image = _studentImage(student);
                          final gender = _genderLabel(student.Sex, context);
                          final details = <String>[
                            if (student.CodeEleve.trim().isNotEmpty)
                              '${uiText(context, 'studentCode')}: ${student.CodeEleve}',
                            if (gender.isNotEmpty) gender,
                            widget.classe.LibelleClasse.trim().isEmpty
                                ? widget.classe.CodeClasse
                                : widget.classe.LibelleClasse,
                          ];
                          return Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: image,
                                child: image == null
                                    ? const Icon(Icons.person_outline)
                                    : null,
                              ),
                              title: Text(
                                name == 'Student'
                                    ? uiText(context, 'notProvided')
                                    : name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(details.join(' • ')),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => StudentDetailScreen(
                                      user: widget.user,
                                      student: student,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _matchesFilters(Student student) {
    if (_selectedGender != 'all' &&
        _normalizedGender(student.Sex) != _selectedGender) {
      return false;
    }

    if (_searchQuery.isEmpty) return true;
    return getStudentDisplayName(student)
            .toLowerCase()
            .contains(_searchQuery) ||
        student.CodeEleve.toLowerCase().contains(_searchQuery);
  }

  String _normalizedGender(String value) {
    switch (value.trim().toLowerCase()) {
      case '1':
      case 'm':
      case 'masculin':
      case 'male':
      case 'garcon':
      case 'g':
        return 'male';
      case '0':
      case 'f':
      case 'feminin':
      case 'female':
      case 'fille':
      case 'fe':
        return 'female';
      default:
        return '';
    }
  }

  String _genderLabel(String value, BuildContext context) {
    switch (_normalizedGender(value)) {
      case 'male':
        return uiText(context, 'male');
      case 'female':
        return uiText(context, 'female');
      default:
        return '';
    }
  }

  ImageProvider<Object>? _studentImage(Student student) {
    for (final candidate in [student.Image, student.photo, student.strimage]) {
      final value = candidate.trim();
      if (value.startsWith('https://') || value.startsWith('http://')) {
        return NetworkImage(value);
      }
      if (value.startsWith('assets/')) {
        return AssetImage(value);
      }
    }
    return null;
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(uiText(context, 'retry')),
            ),
          ],
        ),
      ),
    );
  }
}
