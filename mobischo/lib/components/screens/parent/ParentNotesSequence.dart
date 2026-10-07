import 'package:flutter/material.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/mark.dart';
import 'package:mobischo/models/sequence_evaluation.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/models/year.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/mark_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class ParentNotesYearScreen extends StatelessWidget {
  final Student student;
  final VoidCallback onBack;
  final ValueChanged<Year> onYearSelected;

  const ParentNotesYearScreen({
    Key? key,
    required this.student,
    required this.onBack,
    required this.onYearSelected,
  }) : super(key: key);

  List<Year> _sortYearsNewestFirst(List<Year> years) {
    final sortedYears = List<Year>.from(years);
    sortedYears.sort((first, second) {
      final firstStartYear = _startYear(first);
      final secondStartYear = _startYear(second);
      final comparison = secondStartYear.compareTo(firstStartYear);
      return comparison != 0
          ? comparison
          : second.CodeAnnee.compareTo(first.CodeAnnee);
    });
    return sortedYears;
  }

  int _startYear(Year year) {
    final match = RegExp(r'\d{4}').firstMatch(year.Libelle);
    return int.tryParse(match?.group(0) ?? '') ?? year.CodeAnnee;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NotesHeader(
            title: uiText(context, 'chooseSchoolYear'), onBack: onBack),
        Expanded(
          child: FutureBuilder<List<Year>>(
            future: AcademicServices.getYears(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final years = _sortYearsNewestFirst(
                snapshot.data ?? <Year>[],
              );
              if (years.isEmpty) {
                return _NotesMessage(
                  title: uiText(context, 'noSchoolYearAvailable'),
                  subtitle: uiText(context, 'yearsWillAppear'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: years.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final year = years[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    elevation: 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: CustomTheme.blue,
                        child: Icon(Icons.calendar_today, color: Colors.white),
                      ),
                      title: Text(
                        year.Libelle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(uiText(context, 'consultYearGrades')),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () => onYearSelected(year),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ParentNotesSequenceScreen extends StatefulWidget {
  final Student student;
  final Year year;
  final VoidCallback onBack;
  final void Function(
          SequenceEvaluation sequence, List<Course> courses, List<Mark> marks)
      onSequenceSelected;

  const ParentNotesSequenceScreen({
    Key? key,
    required this.student,
    required this.year,
    required this.onBack,
    required this.onSequenceSelected,
  }) : super(key: key);

  @override
  State<ParentNotesSequenceScreen> createState() =>
      _ParentNotesSequenceScreenState();
}

class _SequenceNotesData {
  final List<Course> courses;
  final List<Mark> marks;

  const _SequenceNotesData({required this.courses, required this.marks});
}

class _ParentNotesSequenceScreenState extends State<ParentNotesSequenceScreen> {
  SequenceEvaluation? unavailableSequence;
  late final Future<List<SequenceEvaluation>> _sequencesFuture;
  late Future<_SequenceNotesData> _availabilityFuture;

  @override
  void initState() {
    super.initState();
    _sequencesFuture = AcademicServices.getSequences();
    _availabilityFuture = _loadAvailability();
  }

  Future<_SequenceNotesData> _loadAvailability() async {
    await _sequencesFuture;
    final results = await Future.wait([
      CourseServices.getClassCourses(widget.student.CodeClasse),
      MarkServices.getStudentYearMarksForNotes(
        widget.student.CodeEleve,
        widget.year.CodeAnnee.toString(),
      ),
    ]);
    final courses = results[0] as List<Course>;
    final classTeachingCodes =
        courses.map((course) => course.CodeEnseignement).toSet();
    final marks = (results[1] as List<Mark>)
        .where((mark) => classTeachingCodes.contains(mark.Codeenseignement))
        .toList();

    return _SequenceNotesData(courses: courses, marks: marks);
  }

  Future<void> _selectSequence(SequenceEvaluation sequence) async {
    final data = await _availabilityFuture;
    final sequenceMarks = data.marks
        .where(
            (mark) => mark.CodeEvaluation == sequence.CodeEvaluation.toString())
        .toList();
    final hasMarks = sequenceMarks.isNotEmpty;
    if (hasMarks) {
      widget.onSequenceSelected(sequence, data.courses, sequenceMarks);
    } else {
      setState(() {
        unavailableSequence = sequence;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (unavailableSequence != null) {
      return Column(
        children: [
          _NotesHeader(
            title: unavailableSequence!.LibelleEvaluation,
            onBack: () => setState(() => unavailableSequence = null),
          ),
          Expanded(
            child: _UnavailableSequenceMessage(
              sequence: unavailableSequence!.LibelleEvaluation,
              onBack: () => setState(() => unavailableSequence = null),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _NotesHeader(
          title: uiText(context, 'chooseSequence'),
          onBack: widget.onBack,
        ),
        Expanded(
          child: FutureBuilder<List<SequenceEvaluation>>(
            future: _sequencesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final sequences = snapshot.data ?? <SequenceEvaluation>[];
              if (sequences.isEmpty) {
                return _NotesMessage(
                  title: uiText(context, 'noSequencesAvailable'),
                  subtitle: uiText(context, 'sequencesWillAppear'),
                );
              }

              return FutureBuilder<_SequenceNotesData>(
                future: _availabilityFuture,
                builder: (context, availabilitySnapshot) {
                  if (availabilitySnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (availabilitySnapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(uiText(context, 'marksLoadError')),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              _availabilityFuture = _loadAvailability();
                            }),
                            child: Text(uiText(context, 'retry')),
                          ),
                        ],
                      ),
                    );
                  }

                  final marks = availabilitySnapshot.data?.marks ?? <Mark>[];
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: sequences.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sequence = sequences[index];
                      final isAvailable = marks.any((mark) =>
                          mark.CodeEvaluation ==
                          sequence.CodeEvaluation.toString());
                      final mutedColor = Colors.grey.shade600;

                      return Card(
                        margin: EdgeInsets.zero,
                        elevation: 1,
                        color: isAvailable ? null : Colors.grey.shade100,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isAvailable
                                ? CustomTheme.blue
                                : Colors.grey.shade400,
                            child: Icon(
                              isAvailable
                                  ? Icons.check_circle_outline
                                  : Icons.remove_circle_outline,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            sequence.LibelleEvaluation,
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: isAvailable ? null : mutedColor,
                            ),
                          ),
                          subtitle: Text(
                            isAvailable
                                ? 'Consulter les notes de ${sequence.LibelleEvaluation.toLowerCase()}'
                                : 'Aucune note disponible',
                            style: TextStyle(
                              color: isAvailable ? null : mutedColor,
                            ),
                          ),
                          trailing: Icon(
                            isAvailable
                                ? Icons.arrow_forward_ios
                                : Icons.info_outline,
                            size: 18,
                            color: isAvailable ? null : mutedColor,
                          ),
                          onTap: () => _selectSequence(sequence),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ParentSequenceMarksScreen extends StatelessWidget {
  final Student student;
  final Year year;
  final SequenceEvaluation sequence;
  final List<Course> courses;
  final List<Mark> marks;
  final VoidCallback onBack;

  const ParentSequenceMarksScreen({
    Key? key,
    required this.student,
    required this.year,
    required this.sequence,
    required this.courses,
    required this.marks,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NotesHeader(title: sequence.LibelleEvaluation, onBack: onBack),
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Text(
            getStudentDisplayName(student),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: courses.isEmpty
              ? _NotesMessage(
                  title: uiText(context, 'noSubjectsAvailable'),
                  subtitle: uiText(context, 'subjectsWillAppear'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: courses.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == courses.length) {
                      return _MarksSummary(marks: marks);
                    }
                    final course = courses[index];
                    return _CourseMarkCard(
                      course: course,
                      marks: marks
                          .where((mark) =>
                              mark.Codeenseignement == course.CodeEnseignement)
                          .toList(),
                    );
                  },
                ),
        ),
      ],
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
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableSequenceMessage extends StatelessWidget {
  final String sequence;
  final VoidCallback onBack;

  const _UnavailableSequenceMessage({
    required this.sequence,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_note_outlined,
              size: 46,
              color: CustomTheme.blue,
            ),
            const SizedBox(height: 14),
            Text(
              "$sequence n'est pas encore disponible",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              uiText(context, 'sequenceMarksNotRecorded'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(uiText(context, 'returnBack')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseMarkCard extends StatelessWidget {
  final Course course;
  final List<Mark> marks;

  const _CourseMarkCard({
    required this.course,
    required this.marks,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<String>(
          future: CourseServices.getMainCourse(course.CodeMatiere),
          builder: (context, subjectSnapshot) {
            final subject = subjectSnapshot.data ?? uiText(context, 'subject');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (marks.isEmpty)
                  Text(
                    uiText(context, 'noMarksRecorded'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  ...marks.map((mark) => _MarkDetails(mark: mark)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MarksSummary extends StatelessWidget {
  final List<Mark> marks;

  const _MarksSummary({required this.marks});

  double? _number(Object? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.toString().trim().replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    double totalCoefficients = 0;
    double totalPoints = 0;
    var usableMarks = 0;

    for (final mark in marks) {
      final valeur = _number(mark.valeur);
      final coefficient = _number(mark.coef);
      if (valeur == null || coefficient == null || coefficient == 0) {
        continue;
      }
      totalCoefficients += coefficient;
      totalPoints += valeur * coefficient;
      usableMarks++;
    }

    if (usableMarks == 0 || totalCoefficients == 0) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(uiText(context, 'noMarksForSubject')),
        ),
      );
    }

    final average = totalPoints / totalCoefficients;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text(uiText(
              context,
              'totalCoefficients',
              parameters: <String, String>{
                'value': totalCoefficients.toStringAsFixed(2),
              },
            )),
            const SizedBox(height: 6),
            Text(uiText(
              context,
              'totalPoints',
              parameters: <String, String>{
                'value': totalPoints.toStringAsFixed(2),
              },
            )),
            const SizedBox(height: 6),
            Text(
              uiText(
                context,
                'average',
                parameters: <String, String>{
                  'value': average.toStringAsFixed(2),
                },
              ),
              style: TextStyle(
                color: average < 10 ? Colors.red : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkDetails extends StatelessWidget {
  final Mark mark;

  const _MarkDetails({required this.mark});

  @override
  Widget build(BuildContext context) {
    final details = <String>[];
    if (mark.coef.isNotEmpty) {
      details.add('Coefficient : ${mark.coef}');
    }
    if (mark.CodeAppreciation.isNotEmpty) {
      details.add(mark.CodeAppreciation);
    }
    final markValue = double.tryParse(
      mark.valeur.trim().replaceAll(',', '.'),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            details.isEmpty ? 'Note' : details.join(' · '),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          '${mark.valeur} /20',
          style: TextStyle(
            color: markValue != null && markValue < 10
                ? Colors.red
                : CustomTheme.blue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
