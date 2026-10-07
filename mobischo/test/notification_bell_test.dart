import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobischo/components/screens/notifications/notification_bell.dart';

Widget _bellApp(int unreadCount, VoidCallback onPressed) {
  return MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: NotificationBell(
        unreadCount: unreadCount,
        onPressed: onPressed,
      ),
    ),
  );
}

void main() {
  testWidgets('bell hides zero badge and opens notification inbox',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(_bellApp(0, () => opened = true));

    expect(find.text('0'), findsNothing);
    await tester.tap(find.byIcon(Icons.notifications_none));
    expect(opened, isTrue);
  });

  testWidgets('bell displays one and multiple unread counts', (tester) async {
    await tester.pumpWidget(_bellApp(1, () {}));
    expect(find.text('1'), findsOneWidget);

    await tester.pumpWidget(_bellApp(5, () {}));
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('bell caps large unread counts at 99+', (tester) async {
    await tester.pumpWidget(_bellApp(130, () {}));
    expect(find.text('99+'), findsOneWidget);
  });
}
