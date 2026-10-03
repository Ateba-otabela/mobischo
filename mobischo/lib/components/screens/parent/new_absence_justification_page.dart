import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
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
  final _explanationController = TextEditingController();

  late Future<List<Student>> _childrenFuture;
  Student? _selectedChild;
  DateTime? _selectedDate;
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
      _selectedDate = null;
      _resetForm();
    });
  }

  void _resetForm() {
    _selectedReason = null;
    _explanationController.clear();
    _documentBytes = null;
    _documentName = null;
  }

  void _changeChild() {
    setState(() {
      _selectedChild = null;
      _selectedDate = null;
      _resetForm();
    });
  }

  Future<void> _selectAbsenceDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: uiText(context, 'absenceDatePicker'),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = DateUtils.dateOnly(picked));
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
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
        _showMessage(uiText(context, 'documentReadError'));
        return;
      }
      if (file.size > _maxDocumentSize) {
        _showMessage(uiText(context, 'documentTooLarge'));
        return;
      }

      setState(() {
        _documentBytes = bytes;
        _documentName = file.name;
      });
    } on PlatformException catch (error) {
      debugPrint('Picking supporting document failed (${error.code}).');
      if (mounted) {
        _showMessage(uiText(context, 'documentSelectError'));
      }
    } on Exception catch (error) {
      debugPrint('Picking supporting document failed (${error.runtimeType}).');
      if (mounted) {
        _showMessage(uiText(context, 'documentSelectError'));
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingDocument = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || _selectedChild == null || _selectedDate == null) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ParentAbsenceSubmissionService.submit(
        studentCode: _selectedChild!.CodeEleve,
        absenceDate: _selectedDate!,
        reason: _selectedReason!,
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
          title: Text(
            uiText(context, 'justificationSentSuccess'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            uiText(context, 'awaitingVerification'),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(true);
              },
              child: Text(uiText(context, 'backToHistory')),
            ),
          ],
        ),
      );
    } on ParentAbsenceSubmissionException catch (error) {
      debugPrint('Justification submission rejected by backend.');
      if (mounted) {
        _showMessage(error.message);
      }
    } on Exception catch (error) {
      debugPrint('Justification submission failed (${error.runtimeType}).');
      if (mounted) {
        _showMessage(
          uiText(context, 'justificationSubmissionError'),
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
        title: Text(uiText(context, 'newJustification')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  _StepHeading(
                    number: '1',
                    title: uiText(context, 'selectYourChild'),
                  ),
                  const SizedBox(height: 10),
                  _buildChildrenStep(),
                  if (_selectedChild != null) ...[
                    const SizedBox(height: 22),
                    _StepHeading(
                      number: '2',
                      title: uiText(context, 'absenceDate'),
                    ),
                    const SizedBox(height: 10),
                    _buildAbsenceDateStep(),
                  ],
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 22),
                    _StepHeading(
                      number: '3',
                      title:
                          '${uiText(context, 'reason')} et ${uiText(context, 'explanation')}',
                    ),
                    const SizedBox(height: 10),
                    _buildReasonForm(),
                  ],
                ],
              ),
            ),
            if (_selectedDate != null) _buildSubmitButton(),
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
          return _ParentMessageCard(
            icon: Icons.cloud_off_outlined,
            message: uiText(context, 'childrenLoadError'),
            actionLabel: uiText(context, 'retry'),
            onAction: _reloadChildren,
          );
        }

        final children = snapshot.data ?? const <Student>[];
        if (children.isEmpty) {
          return _ParentMessageCard(
            icon: Icons.family_restroom,
            message: uiText(context, 'noChildLinked'),
          );
        }

        if (_selectedChild != null) {
          return _ChildTile(
            student: _selectedChild!,
            selected: true,
            onTap: _changeChild,
            trailingLabel: uiText(context, 'change'),
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

  Widget _buildAbsenceDateStep() {
    final selectedDate = _selectedDate;
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: _selectAbsenceDate,
        leading: const Icon(Icons.calendar_month, color: CustomTheme.blue),
        title: Text(
          selectedDate == null
              ? uiText(context, 'selectDate')
              : _formatDate(selectedDate),
          style: TextStyle(
            color: selectedDate == null ? Colors.black54 : CustomTheme.dark,
            fontWeight:
                selectedDate == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
      ),
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
                decoration: InputDecoration(
                  labelText: uiText(context, 'chooseReason'),
                  border: OutlineInputBorder(),
                ),
                items: _reasons
                    .map(
                      (reason) => DropdownMenuItem<String>(
                        value: reason,
                        child: Text(
                          uiText(
                            context,
                            reason == 'Maladie'
                                ? 'reasonIllness'
                                : reason == 'Rendez-vous médical'
                                    ? 'reasonMedicalAppointment'
                                    : reason == 'Raisons familiales'
                                        ? 'reasonFamily'
                                        : reason == 'Urgence familiale'
                                            ? 'reasonFamilyEmergency'
                                            : 'reasonOther',
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (reason) => setState(() => _selectedReason = reason),
                validator: (value) =>
                    value == null ? uiText(context, 'selectReason') : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _explanationController,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: uiText(context, 'absenceExplanationLabel'),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final explanation = value?.trim() ?? '';
                  if (explanation.isEmpty) {
                    return _selectedReason == 'Autre'
                        ? uiText(context, 'explainChosenReason')
                        : uiText(context, 'addExplanation');
                  }
                  if (explanation.length < 10) {
                    return uiText(context, 'addSomeDetails');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Text(
                uiText(context, 'optionalSupportingDocument'),
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
                  label: Text(uiText(context, 'addDocumentOrPhoto')),
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
              Text(
                uiText(context, 'fileSizeLimit'),
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDocument() {
    final name = _documentName ?? uiText(context, 'selectedDocument');
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
            tooltip: uiText(context, 'deleteDocument'),
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
              : Text(
                  uiText(context, 'sendJustification').toUpperCase(),
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
            : Text(uiText(
                context,
                'classLabel',
                parameters: <String, String>{
                  'className': student.CodeClasse,
                },
              )),
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

class _ParentMessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ParentMessageCard({
    required this.icon,
    required this.message,
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
