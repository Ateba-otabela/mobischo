import 'package:flutter/material.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/models/mark.dart';
import 'package:mobischo/models/sequence_evaluation.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/mark_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class StudentSequenceNotesScreen extends StatefulWidget {
  final Student student;
  final VoidCallback? onBack;
  final Future<List<SequenceEvaluation>> Function()? loadSequences;
  final Future<List<Mark>> Function(String studentCode, String sequenceCode)?
      loadMarks;

  const StudentSequenceNotesScreen({
    Key? key,
    required this.student,
    this.onBack,
    this.loadSequences,
    this.loadMarks,
  }) : super(key: key);

  @override
  State<StudentSequenceNotesScreen> createState() =>
      _StudentSequenceNotesScreenState();
}

class _StudentSequenceNotesScreenState
    extends State<StudentSequenceNotesScreen> {
  late Future<List<SequenceEvaluation>> _sequencesFuture;
  SequenceEvaluation? _selectedSequence;
  Future<List<Mark>>? _marksFuture;

  @override
  void initState() {
    super.initState();
    _sequencesFuture = _loadSequences();
  }

  Future<List<SequenceEvaluation>> _loadSequences() =>
      widget.loadSequences?.call() ??
      AcademicServices.getSequencesForNotes(widget.student.CodeEleve);

  Future<List<Mark>> _loadMarks(SequenceEvaluation sequence) =>
      widget.loadMarks?.call(
        widget.student.CodeEleve,
        sequence.CodeEvaluation.toString(),
      ) ??
      MarkServices.getStudentSequenceMarks(
        widget.student.CodeEleve,
        sequence.CodeEvaluation.toString(),
      );

  void _selectSequence(SequenceEvaluation sequence) {
    setState(() {
      _selectedSequence = sequence;
      _marksFuture = _loadMarks(sequence);
    });
  }

  void _goBack() {
    if (_selectedSequence != null) {
      setState(() {
        _selectedSequence = null;
        _marksFuture = null;
      });
      return;
    }

    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _selectedSequence?.LibelleEvaluation ??
        uiText(context, 'chooseSequence');

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _NotesHeader(title: title, onBack: _goBack),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _studentName(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: _selectedSequence == null
                ? _buildSequences(context)
                : _buildMarks(context),
          ),
        ],
      ),
    );
  }

  String _studentName(BuildContext context) {
    final name = getStudentDisplayName(widget.student);
    return name == 'Student' ? uiText(context, 'notProvided') : name;
  }

  Widget _buildSequences(BuildContext context) {
    return FutureBuilder<List<SequenceEvaluation>>(
      future: _sequencesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _LoadError(
            message: uiText(context, 'sequencesLoadError'),
            onRetry: () => setState(() => _sequencesFuture = _loadSequences()),
          );
        }

        final sequences = snapshot.data ?? <SequenceEvaluation>[];
        if (sequences.isEmpty) {
          return _NotesMessage(
            title: uiText(context, 'noSequencesAvailable'),
            subtitle: uiText(context, 'sequencesWillAppear'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sequences.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final sequence = sequences[index];
            final available = sequence.hasMarks;
            return Card(
              margin: EdgeInsets.zero,
              color: available ? null : Colors.grey.shade100,
              child: ListTile(
                enabled: available,
                leading: CircleAvatar(
                  backgroundColor:
                      available ? CustomTheme.blue : Colors.grey.shade400,
                  child: Icon(
                    available ? Icons.check : Icons.circle_outlined,
                    color: Colors.white,
                  ),
                ),
                title: Text(sequence.LibelleEvaluation),
                subtitle: Text(
                  uiText(
                    context,
                    available
                        ? 'marksAvailable'
                        : 'noMarksAvailableForSequence',
                  ),
                ),
                trailing: available
                    ? const Icon(Icons.arrow_forward_ios, size: 18)
                    : null,
                onTap: available ? () => _selectSequence(sequence) : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMarks(BuildContext context) {
    return FutureBuilder<List<Mark>>(
      future: _marksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _LoadError(
            message: uiText(context, 'marksLoadError'),
            onRetry: () => setState(() {
              _marksFuture = _loadMarks(_selectedSequence!);
            }),
          );
        }

        final marks = snapshot.data ?? <Mark>[];
        if (marks.isEmpty) {
          return _NotesMessage(
            title: uiText(context, 'noMarksRecorded'),
            subtitle: uiText(context, 'noMarksForNow'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: marks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _MarkCard(mark: marks[index]),
        );
      },
    );
  }
}

class _NotesHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _NotesHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios, color: CustomTheme.blue),
          ),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(uiText(context, 'retry')),
          ),
        ],
      ),
    );
  }
}

class _NotesMessage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NotesMessage({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_outlined,
                size: 42, color: CustomTheme.blue),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkCard extends StatelessWidget {
  final Mark mark;

  const _MarkCard({required this.mark});

  @override
  Widget build(BuildContext context) {
    final subjectName = mark.LibelleMatiere.trim().isNotEmpty
        ? mark.LibelleMatiere.trim()
        : mark.CodeMatiere.trim().isNotEmpty
            ? mark.CodeMatiere.trim()
            : uiText(context, 'subject');
    final score = mark.valeur.trim();
    final parsedScore = double.tryParse(score.replaceAll(',', '.'));
    final details = <String>[
      if (mark.coef.trim().isNotEmpty)
        '${uiText(context, 'coefficient')}: ${mark.coef}',
      if (mark.total.trim().isNotEmpty)
        '${uiText(context, 'total')}: ${mark.total}',
      if (mark.CodeAppreciation.trim().isNotEmpty) mark.CodeAppreciation.trim(),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(subjectName),
        subtitle: details.isEmpty ? null : Text(details.join(' · ')),
        trailing: Text(
          score.isEmpty ? uiText(context, 'noMark') : '$score /20',
          style: TextStyle(
            color: parsedScore != null && parsedScore < 10
                ? Colors.red
                : CustomTheme.blue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
