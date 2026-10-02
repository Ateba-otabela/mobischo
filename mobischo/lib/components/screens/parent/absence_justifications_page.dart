import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/parent/new_absence_justification_page.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/parent_absence_history_service.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class AbsenceJustificationsPage extends StatefulWidget {
  final User user;

  const AbsenceJustificationsPage({Key? key, required this.user})
      : super(key: key);

  @override
  State<AbsenceJustificationsPage> createState() =>
      _AbsenceJustificationsPageState();
}

class _AbsenceJustificationsPageState extends State<AbsenceJustificationsPage> {
  late Future<_AbsenceHistoryData> _history;

  @override
  void initState() {
    super.initState();
    _history = _loadHistory();
  }

  Future<_AbsenceHistoryData> _loadHistory() async {
    final records = await ParentAbsenceHistoryService.getRecentJustifications();
    final students = await StudentServices.getParentStudents(widget.user.code);
    return _AbsenceHistoryData(records: records, students: students);
  }

  void _retry() {
    setState(() {
      _history = _loadHistory();
    });
  }

  Future<void> _openNewJustification() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NewAbsenceJustificationPage(user: widget.user),
      ),
    );
    if (submitted == true && mounted) {
      _retry();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        foregroundColor: Colors.white,
        title: const Text('JUSTIFIER UNE ABSENCE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<_AbsenceHistoryData>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: CustomTheme.blue),
            );
          }

          if (snapshot.hasError) {
            return _HistoryErrorState(onRetry: _retry);
          }

          final history = snapshot.data!;
          if (history.records.isEmpty) {
            return const _HistoryEmptyState();
          }

          final studentNames = {
            for (final student in history.students)
              student.CodeEleve: getStudentDisplayName(student),
          };

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: history.records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _JustificationHistoryCard(
              record: history.records[index],
              studentName: studentNames[
                      (history.records[index]['CodeEleve'] ?? '').toString()] ??
                  'Élève',
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewJustification,
        backgroundColor: CustomTheme.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AbsenceHistoryData {
  final List<Map<String, dynamic>> records;
  final List<Student> students;

  const _AbsenceHistoryData({required this.records, required this.students});
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: CustomTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.event_note_outlined,
                color: CustomTheme.blue,
                size: 52,
              ),
              SizedBox(height: 18),
              Text(
                'Aucune justification pour le moment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CustomTheme.dark,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Vous n’avez pas encore soumis de justification d’absence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xff757575),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _HistoryErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: CustomTheme.blue, size: 44),
            const SizedBox(height: 12),
            const Text(
              'L’historique est momentanément indisponible.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CustomTheme.dark, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JustificationHistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final String studentName;

  const _JustificationHistoryCard({
    required this.record,
    required this.studentName,
  });

  String _firstValue(List<String> keys) {
    for (final key in keys) {
      final value = (record[key] ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) {
      return value;
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final absenceDate = _firstValue(['date_absence', 'absence_date']);
    final reason = _firstValue(['motif', 'reason', 'justification']);
    final status = _firstValue(['statut', 'status']);
    final submittedAt = _firstValue(['created_at']);

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xffedf7f0),
                  child: Icon(Icons.person_outline, color: CustomTheme.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(
                      color: CustomTheme.dark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (status.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xffedf7f0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: CustomTheme.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (absenceDate.isNotEmpty) ...[
              const SizedBox(height: 12),
              _HistoryDetail(
                icon: Icons.event_outlined,
                label: 'Absence du ${_formatDate(absenceDate)}',
              ),
            ],
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              _HistoryDetail(icon: Icons.notes_rounded, label: reason),
            ],
            if (submittedAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              _HistoryDetail(
                icon: Icons.schedule_rounded,
                label: 'Soumise le ${_formatDate(submittedAt)}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HistoryDetail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: Colors.black45),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
