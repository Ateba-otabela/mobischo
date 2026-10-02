import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/parent_absence_submission_service.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class NewAbsenceJustificationPage extends StatefulWidget {
  final User user;

  const NewAbsenceJustificationPage({Key? key, required this.user})
      : super(key: key);

  @override
  State<NewAbsenceJustificationPage> createState() =>
      _NewAbsenceJustificationPageState();
}

class _NewAbsenceJustificationPageState
    extends State<NewAbsenceJustificationPage> {
  static const _reasons = [
    'Maladie',
    'Rendez-vous médical',
    'Raisons familiales',
    'Urgence familiale',
    'Autre',
  ];
  static const _maxDocumentSize = 10 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _reasonDetailController = TextEditingController();
  final _explanationController = TextEditingController();

  late Future<List<Student>> _childrenFuture;
  Future<List<EligibleAbsence>>? _absencesFuture;
  Student? _selectedChild;
  EligibleAbsence? _selectedAbsence;
  String? _selectedReason;
  Uint8List? _documentBytes;
  String? _documentName;
  bool _isSubmitting = false;
  bool _isPickingDocument = false;

  @override
  void initState() {
    super.initState();
    _childrenFuture = StudentServices.getParentStudents(widget.user.code);
  }

  @override
  void dispose() {
    _reasonDetailController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  void _reloadChildren() {
    setState(() {
      _childrenFuture = StudentServices.getParentStudents(widget.user.code);
    });
  }

  void _selectChild(Student student) {
    setState(() {
      _selectedChild = student;
      _selectedAbsence = null;
      _absencesFuture =
          ParentAbsenceSubmissionService.getEligibleAbsences(student.CodeEleve);
      _resetForm();
    });
  }

  void _resetForm() {
    _selectedReason = null;
    _reasonDetailController.clear();
    _explanationController.clear();
    _documentBytes = null;
    _documentName = null;
  }

  void _changeChild() {
    setState(() {
      _selectedChild = null;
      _selectedAbsence = null;
      _absencesFuture = null;
      _resetForm();
    });
  }

  void _changeAbsence() {
    setState(() {
      _selectedAbsence = null;
      _resetForm();
    });
  }

  Future<void> _pickDocument() async {
    setState(() => _isPickingDocument = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        debugPrint('Supporting document could not be read from the picker.');
        _showMessage('Le document sélectionné n’a pas pu être lu.');
        return;
      }
      if (file.size > _maxDocumentSize) {
        _showMessage('Le document ne doit pas dépasser 10 Mo.');
        return;
      }

      setState(() {
        _documentBytes = bytes;
        _documentName = file.name;
      });
    } on PlatformException catch (error) {
      debugPrint('Picking supporting document failed (${error.code}).');
      if (mounted) {
        _showMessage('Impossible de sélectionner ce document.');
      }
    } on Exception catch (error) {
      debugPrint('Picking supporting document failed (${error.runtimeType}).');
      if (mounted) {
        _showMessage('Impossible de sélectionner ce document.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingDocument = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || _selectedChild == null || _selectedAbsence == null) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ParentAbsenceSubmissionService.submit(
        studentCode: _selectedChild!.CodeEleve,
        absenceId: _selectedAbsence!.id,
        reason: _selectedReason!,
        reasonDetail: _reasonDetailController.text.trim(),
        explanation: _explanationController.text.trim(),
        documentBytes: _documentBytes,
        documentName: _documentName,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(
            Icons.check_circle_outline,
            color: CustomTheme.blue,
            size: 48,
          ),
          title: const Text(
            'Justification envoyée avec succès',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Elle est en attente de vérification.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Retour à l’historique'),
            ),
          ],
        ),
      );
    } on Exception catch (error) {
      debugPrint('Justification submission failed (${error.runtimeType}).');
      if (mounted) {
        _showMessage(
          'La justification n’a pas pu être envoyée. Vérifiez votre connexion et réessayez.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        foregroundColor: Colors.white,
        title: const Text('NOUVELLE JUSTIFICATION'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  const _StepHeading(
                    number: '1',
                    title: 'Sélectionnez votre enfant',
                  ),
                  const SizedBox(height: 10),
                  _buildChildrenStep(),
                  if (_selectedChild != null) ...[
                    const SizedBox(height: 22),
                    const _StepHeading(
                      number: '2',
                      title: 'Sélectionnez l’absence',
                    ),
                    const SizedBox(height: 10),
                    _buildAbsencesStep(),
                  ],
                  if (_selectedAbsence != null) ...[
                    const SizedBox(height: 22),
                    const _StepHeading(number: '3', title: 'Motif'),
                    const SizedBox(height: 10),
                    _buildReasonForm(),
                  ],
                ],
              ),
            ),
            if (_selectedAbsence != null) _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenStep() {
    return FutureBuilder<List<Student>>(
      future: _childrenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingCard();
        }
        if (snapshot.hasError) {
          return _MessageCard(
            icon: Icons.cloud_off_outlined,
            message: 'Impossible de charger vos enfants pour le moment.',
            actionLabel: 'Réessayer',
            onAction: _reloadChildren,
          );
        }

        final children = snapshot.data ?? const <Student>[];
        if (children.isEmpty) {
          return const _MessageCard(
            icon: Icons.family_restroom,
            message: 'Aucun enfant n’est associé à votre compte.',
          );
        }

        if (_selectedChild != null) {
          return _ChildTile(
            student: _selectedChild!,
            selected: true,
            onTap: _changeChild,
            trailingLabel: 'Changer',
          );
        }

        return Column(
          children: children
              .map(
                (student) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChildTile(
                    student: student,
                    onTap: () => _selectChild(student),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildAbsencesStep() {
    final future = _absencesFuture;
    if (future == null) {
      return const _MessageCard(
        icon: Icons.event_busy_outlined,
        message: 'Sélectionnez un enfant pour consulter ses absences.',
      );
    }

    return FutureBuilder<List<EligibleAbsence>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingCard();
        }
        if (snapshot.hasError) {
          return _MessageCard(
            icon: Icons.cloud_off_outlined,
            message: 'Impossible de charger les absences pour le moment.',
            actionLabel: 'Réessayer',
            onAction: () {
              setState(() {
                _absencesFuture =
                    ParentAbsenceSubmissionService.getEligibleAbsences(
                        _selectedChild!.CodeEleve);
              });
            },
          );
        }

        final absences = snapshot.data ?? const <EligibleAbsence>[];
        if (absences.isEmpty) {
          return const _MessageCard(
            icon: Icons.event_busy_outlined,
            title: 'Aucune absence à justifier',
            message:
                'Cet enfant n’a pas d’absence enregistrée disponible pour une justification.',
          );
        }

        if (_selectedAbsence != null) {
          return _AbsenceTile(
            absence: _selectedAbsence!,
            studentName: getStudentDisplayName(_selectedChild!),
            selected: true,
            onTap: _changeAbsence,
            trailingLabel: 'Changer',
          );
        }

        return Column(
          children: absences
              .map(
                (absence) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AbsenceTile(
                    absence: absence,
                    studentName: getStudentDisplayName(_selectedChild!),
                    onTap: () => setState(() {
                      _selectedAbsence = absence;
                    }),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildReasonForm() {
    return Form(
      key: _formKey,
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Choisissez un motif *',
                  border: OutlineInputBorder(),
                ),
                items: _reasons
                    .map(
                      (reason) => DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      ),
                    )
                    .toList(),
                onChanged: (reason) => setState(() {
                  _selectedReason = reason;
                  if (reason != 'Autre') {
                    _reasonDetailController.clear();
                  }
                }),
                validator: (value) =>
                    value == null ? 'Sélectionnez un motif.' : null,
              ),
              if (_selectedReason == 'Autre') ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reasonDetailController,
                  maxLength: 180,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Précisez le motif *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedReason != 'Autre') return null;
                    if (value == null || value.trim().length < 3) {
                      return 'Précisez le motif en quelques mots.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _explanationController,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Expliquez brièvement la raison de l’absence',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final explanation = value?.trim() ?? '';
                  if (explanation.isNotEmpty && explanation.length < 10) {
                    return 'Ajoutez quelques détails (10 caractères minimum).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Document justificatif (facultatif)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (_documentBytes == null)
                OutlinedButton.icon(
                  onPressed: _isPickingDocument ? null : _pickDocument,
                  icon: _isPickingDocument
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                  label: const Text('Ajouter un document ou une photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CustomTheme.blue,
                    side: const BorderSide(color: CustomTheme.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              else
                _buildSelectedDocument(),
              const SizedBox(height: 4),
              const Text(
                'PDF, JPG ou PNG · 10 Mo maximum',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDocument() {
    final name = _documentName ?? 'Document sélectionné';
    final isImage = name.toLowerCase().endsWith('.jpg') ||
        name.toLowerCase().endsWith('.jpeg') ||
        name.toLowerCase().endsWith('.png');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xfff3f7f4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffd6e8db)),
      ),
      child: Row(
        children: [
          if (isImage && _documentBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                _documentBytes!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            )
          else
            const Icon(Icons.description_outlined, color: CustomTheme.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            tooltip: 'Supprimer le document',
            onPressed: () => setState(() {
              _documentBytes = null;
              _documentName = null;
            }),
            icon: const Icon(Icons.close, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomTheme.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'ENVOYER LA JUSTIFICATION',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}

class _StepHeading extends StatelessWidget {
  final String number;
  final String title;

  const _StepHeading({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: CustomTheme.blue,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: CustomTheme.dark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChildTile extends StatelessWidget {
  final Student student;
  final bool selected;
  final VoidCallback onTap;
  final String? trailingLabel;

  const _ChildTile({
    required this.student,
    required this.onTap,
    this.selected = false,
    this.trailingLabel,
  });

  ImageProvider<Object>? _imageProvider() {
    final candidates = [student.Image, student.photo, student.strimage];
    for (final candidate in candidates) {
      final value = candidate.trim();
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return NetworkImage(value);
      }
      if (value.startsWith('assets/')) {
        return AssetImage(value);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProvider();
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: selected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? CustomTheme.blue : Colors.transparent,
          width: selected ? 1.5 : 0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xffedf7f0),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person_outline, color: CustomTheme.blue)
              : null,
        ),
        title: Text(
          getStudentDisplayName(student),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: student.CodeClasse.trim().isEmpty
            ? null
            : Text('Classe ${student.CodeClasse}'),
        trailing: trailingLabel != null
            ? Text(
                trailingLabel!,
                style: const TextStyle(
                  color: CustomTheme.blue,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: CustomTheme.blue,
              ),
      ),
    );
  }
}

class _AbsenceTile extends StatelessWidget {
  final EligibleAbsence absence;
  final String studentName;
  final bool selected;
  final VoidCallback onTap;
  final String? trailingLabel;

  const _AbsenceTile({
    required this.absence,
    required this.studentName,
    required this.onTap,
    this.selected = false,
    this.trailingLabel,
  });

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: selected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? CustomTheme.blue : Colors.transparent,
          width: selected ? 1.5 : 0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xffedf7f0),
          child: Icon(Icons.event_busy_outlined, color: CustomTheme.blue),
        ),
        title: Text(
          'Absence du ${_formatDate(absence.date)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(studentName),
            if (absence.className.trim().isNotEmpty) Text(absence.className),
            const Text('Statut : absent(e)'),
          ],
        ),
        trailing: trailingLabel != null
            ? Text(
                trailingLabel!,
                style: const TextStyle(
                  color: CustomTheme.blue,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: CustomTheme.blue,
              ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(color: CustomTheme.blue),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageCard({
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CustomTheme.blue, size: 38),
            const SizedBox(height: 10),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CustomTheme.dark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
