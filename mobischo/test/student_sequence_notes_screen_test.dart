import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobischo/components/screens/students/student_sequence_notes_screen.dart';
import 'package:mobischo/models/mark.dart';
import 'package:mobischo/models/sequence_evaluation.dart';
import 'package:mobischo/models/student.dart';

Student _student() => Student.fromJson(<String, dynamic>{
      'CodeEleve': 'STUDENT-1',
      'Nom': 'Alpha',
      'Prenom': 'One',
    });

Widget _screen({
  required Future<List<Mark>> Function(String, String) loadMarks,
  bool includeScaffold = true,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: includeScaffold
        ? Scaffold(
            body: StudentSequenceNotesScreen(
              student: _student(),
              loadSequences: () async => <SequenceEvaluation>[
                SequenceEvaluation(
                  CodeEvaluation: 1,
                  LibelleEvaluation: 'Sequence 1',
                  hasMarks: true,
                ),
                SequenceEvaluation(
                  CodeEvaluation: 2,
                  LibelleEvaluation: 'Sequence 2',
                ),
              ],
              loadMarks: loadMarks,
            ),
          )
        : StudentSequenceNotesScreen(
            student: _student(),
            loadSequences: () async => <SequenceEvaluation>[
              SequenceEvaluation(
                CodeEvaluation: 1,
                LibelleEvaluation: 'Sequence 1',
                hasMarks: true,
              ),
              SequenceEvaluation(
                CodeEvaluation: 2,
                LibelleEvaluation: 'Sequence 2',
              ),
            ],
            loadMarks: loadMarks,
          ),
  );
}

Mark _mark({String value = '14'}) => Mark(
      Codeenseignement: 'TEACH-MATH',
      CodeEleve: 'STUDENT-1',
      CodeEvaluation: '1',
      CodeAppreciation: '',
      valeur: value,
      coef: '2',
      total: value,
      Dateeng: '',
      codeannee: '',
      CodeMatiere: 'MAT-MATH',
      LibelleMatiere: 'Mathematics',
    );

void main() {
  testWidgets('selecting a sequence performs one consolidated marks request',
      (tester) async {
    var requestCount = 0;
    await tester.pumpWidget(_screen(loadMarks: (studentCode, sequenceCode) {
      requestCount++;
      expect(studentCode, 'STUDENT-1');
      expect(sequenceCode, '1');
      return Future<List<Mark>>.value(<Mark>[_mark()]);
    }));
    await tester.pumpAndSettle();

    expect(find.text('Sequence 1'), findsOneWidget);
    expect(requestCount, 0);
    final enabledTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Sequence 1'),
        matching: find.byType(ListTile),
      ),
    );
    expect(enabledTile.enabled, isTrue);
    expect(find.text('Grades available'), findsOneWidget);
    expect(find.text('No grades available'), findsOneWidget);

    await tester.tap(find.text('Sequence 1'));
    await tester.pumpAndSettle();

    expect(requestCount, 1);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('14 /20'), findsOneWidget);
  });

  testWidgets('unavailable sequence message is localized in French',
      (tester) async {
    await tester.pumpWidget(_screen(
      locale: const Locale('fr'),
      loadMarks: (_, __) async => <Mark>[],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Aucune note disponible'), findsOneWidget);
  });

  testWidgets('unavailable sequences are disabled and do not navigate',
      (tester) async {
    var requestCount = 0;
    await tester.pumpWidget(_screen(loadMarks: (_, __) async {
      requestCount++;
      return <Mark>[_mark()];
    }));
    await tester.pumpAndSettle();

    final disabledTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Sequence 2'),
        matching: find.byType(ListTile),
      ),
    );
    expect(disabledTile.enabled, isFalse);
    expect(find.text('No grades available'), findsOneWidget);

    await tester.tap(find.text('Sequence 2'));
    await tester.pumpAndSettle();

    expect(requestCount, 0);
    expect(find.text('Sequence 1'), findsOneWidget);
    expect(find.text('Mathematics'), findsNothing);
  });

  testWidgets('shared Notes route supplies Material when embedded directly',
      (tester) async {
    await tester.pumpWidget(_screen(
      includeScaffold: false,
      loadMarks: (_, __) async => <Mark>[_mark()],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sequence 1'), findsOneWidget);
    expect(find.text('Sequence 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty sequence result has a localized empty state',
      (tester) async {
    await tester.pumpWidget(_screen(
      loadMarks: (_, __) async => <Mark>[],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sequence 1'));
    await tester.pumpAndSettle();

    expect(find.text('No grades recorded'), findsOneWidget);
    expect(find.text('No grades are available yet.'), findsOneWidget);
  });
}
