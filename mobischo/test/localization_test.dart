import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/main.dart';

void main() {
  test('resolves French, English, and unsupported device languages', () {
    expect(resolveMobischoLocale(const Locale('fr', 'CA')), const Locale('fr'));
    expect(resolveMobischoLocale(const Locale('en', 'US')), const Locale('en'));
    expect(resolveMobischoLocale(const Locale('es')), const Locale('fr'));
    expect(resolveMobischoLocale(null), const Locale('fr'));
  });

  testWidgets('localizes parent and principal navigation labels in English',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Column(
            children: [
              Text(AppLocalizations.of(context).myChildren),
              Text(uiText(context, 'signOut')),
              Text(localizedMenuTitle(context, 'Présence')),
              Text(localizedMenuTitle(context, 'Élèves')),
              Text(localizedMenuTitle(context, 'Rapports des professeurs')),
              Text(localizedMenuTitle(context, 'Alertes d’investigation')),
              Text(localizedMenuTitle(context, 'Appels des professeurs')),
              Text(localizedMenuTitle(context, 'Convoquer')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('My children'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Teacher reports'), findsOneWidget);
    expect(find.text('Investigation alerts'), findsOneWidget);
    expect(find.text('Teacher calls'), findsOneWidget);
    expect(find.text('Convene'), findsOneWidget);
  });
}
