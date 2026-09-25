import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/models/absence_justification.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/absence_justification_service.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class AbsenceJustificationScreen extends StatefulWidget {
  final User user;

  const AbsenceJustificationScreen({Key? key, required this.user})
      : super(key: key);

  @override
  State<AbsenceJustificationScreen> createState() =>
      _AbsenceJustificationScreenState();
}

class _AbsenceJustificationScreenState
    extends State<AbsenceJustificationScreen> {
  final _explanationController = TextEditingController();
  DateTime? _absenceDate;
  Student? _selectedStudent;
  String? _motif;
  String? _attachment;
  bool _sending = false;
  bool _showForm = false;
  late Future<List<Student>> _students;

  final _motifs = const [
    'Maladie',
    'Rendez-vous médical',
    'Raisons familiales',
    'Urgence familiale',
    'Autre',
  ];

  // Temporary UI-only records used when the API has no justifications.
  final _temporaryMockJustifications = <AbsenceJustification>[
    AbsenceJustification(
      id: 'mock-jean',
      studentCode: 'Jean Dupont',
      dateAbsence: '20/09/2026',
      motif: 'Maladie',
      justification: 'L’élève était absent pour des raisons de santé.',
      pieceJointe: '',
      statut: 'En attente',
      dateEnvoi: '2026-09-20',
    ),
    AbsenceJustification(
      id: 'mock-marie',
      studentCode: 'Marie Ngono',
      dateAbsence: '18/09/2026',
      motif: 'Raisons familiales',
      justification: 'L’élève devait s’absenter pour une raison familiale.',
      pieceJointe: '',
      statut: 'En attente',
      dateEnvoi: '2026-09-18',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _students = StudentServices.getParentStudents(widget.user.code);
  }

  @override
  void dispose() {
    _explanationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _absenceDate = picked);
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.name.isNotEmpty) {
      setState(() => _attachment = result.files.single.name);
    }
  }

  Future<void> _submit() async {
    if (_selectedStudent == null ||
        _absenceDate == null ||
        _motif == null ||
        _explanationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez compléter tous les champs.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await AbsenceJustificationService.submit(
        parentCode: widget.user.code,
        studentCode: _selectedStudent!.CodeEleve,
        absenceDate: DateFormat('yyyy-MM-dd').format(_absenceDate!),
        motif: _motif!,
        justification: _explanationController.text.trim(),
        attachment: _attachment,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _showForm = false;
        _selectedStudent = null;
        _absenceDate = null;
        _motif = null;
        _attachment = null;
        _explanationController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’envoyer la justification.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: CustomTheme.blue,
        leading: _showForm
            ? IconButton(
                tooltip: 'Retour aux justifications récentes',
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => setState(() => _showForm = false),
              )
            : null,
        title: Text(
          _showForm ? 'Nouvelle justification' : 'Justifier une absence',
        ),
      ),
      floatingActionButton: _showForm
          ? null
          : FloatingActionButton(
              tooltip: 'Ajouter une justification',
              backgroundColor: CustomTheme.blue,
              onPressed: () => setState(() => _showForm = true),
              child: const Icon(Icons.add),
            ),
      body: FutureBuilder<List<Student>>(
        future: _students,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              if (_showForm) _buildForm(students) else _buildHistory(students),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm(List<Student> students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Enfant'),
        _card(
          child: DropdownButtonFormField<Student>(
            value: _selectedStudent,
            isExpanded: true,
            decoration: const InputDecoration(border: InputBorder.none),
            hint: const Text('Sélectionnez un enfant'),
            items: students
                .map((student) => DropdownMenuItem<Student>(
                      value: student,
                      child: Row(
                        children: [
                          _studentAvatar(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${getStudentDisplayName(student)}\nClasse : ${student.CodeClasse}',
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (student) => setState(() => _selectedStudent = student),
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Date de l’absence'),
        _card(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: CustomTheme.blue),
            title: Text(_absenceDate == null
                ? 'Sélectionner une date'
                : DateFormat('dd/MM/yyyy').format(_absenceDate!)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _pickDate,
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Motif de l’absence'),
        _card(
          child: DropdownButtonFormField<String>(
            value: _motif,
            isExpanded: true,
            decoration: const InputDecoration(border: InputBorder.none),
            hint: const Text('Sélectionnez un motif'),
            items: _motifs
                .map((motif) => DropdownMenuItem<String>(
                      value: motif,
                      child: Text(motif),
                    ))
                .toList(),
            onChanged: (motif) => setState(() => _motif = motif),
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Justification'),
        _card(
          child: TextField(
            controller: _explanationController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Expliquez brièvement la raison de l’absence...',
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Pièce justificative'),
        _card(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_file, color: CustomTheme.blue),
            title: Text(_attachment ?? 'Ajouter un document ou une photo'),
            trailing: _attachment == null
                ? const Icon(Icons.add, color: CustomTheme.blue)
                : IconButton(
                    tooltip: 'Supprimer la pièce jointe',
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _attachment = null),
                  ),
            onTap: _attachment == null ? _pickAttachment : null,
          ),
        ),
        const SizedBox(height: 22),
        CustomButton(
          text: 'Envoyer la justification',
          loading: _sending,
          onPress: _submit,
        ),
      ],
    );
  }

  Widget _buildHistory(List<Student> students) {
    final history = [..._temporaryMockJustifications]
      ..sort((first, second) =>
          _historyDate(second.dateEnvoi).compareTo(
            _historyDate(first.dateEnvoi),
          ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Justifications récentes'),
        Column(
          children: history.map((item) {
            final studentName = _studentName(students, item.studentCode);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _detail('Date d’absence', item.dateAbsence),
                    _detail('Motif', item.motif),
                    if (item.justification.isNotEmpty)
                      _detail('Justification', item.justification),
                    if (item.statut.isNotEmpty) _detail('Statut', item.statut),
                    if (item.dateEnvoi.isNotEmpty)
                      _detail('Date d’envoi', item.dateEnvoi),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  DateTime _historyDate(String value) =>
      DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

  String _studentName(List<Student> students, String studentCode) {
    for (final student in students) {
      if (student.CodeEleve == studentCode) {
        return getStudentDisplayName(student);
      }
    }
    return studentCode;
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: CustomTheme.cardShadow,
        ),
        child: child,
      );

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label)),
            Expanded(
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

  Widget _studentAvatar() => Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage('assets/images/avatar-s-19.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      );
}
