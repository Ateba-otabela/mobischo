import 'package:flutter/material.dart';
import 'package:mobischo/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobischo/components/screens/notifications/notification_list_screen.dart';
import 'package:mobischo/models/mobile_notification.dart';
import 'package:mobischo/models/user.dart';

User _testUser() => User(
      nom: 'Test',
      prenom: 'User',
      contacts: '',
      sex: '',
      email: '',
      login: 'test-user',
      code: 'test-user',
      account_type: 'parent',
      text_password: '',
      address: '',
      admin: '0',
      CodeEtablissement: 'school-1',
    );

Widget _screen({
  required Locale locale,
  required Future<MobileNotificationPage> Function() loadNotifications,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: NotificationListScreen(
      user: _testUser(),
      onUnreadCountChanged: (_) {},
      loadNotifications: loadNotifications,
    ),
  );
}

void main() {
  testWidgets('empty inbox shows localized empty state without retry',
      (tester) async {
    await tester.pumpWidget(_screen(
      locale: const Locale('fr'),
      loadNotifications: () async => const MobileNotificationPage(
        notifications: <MobileNotification>[],
        unreadCount: 0,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Aucune notification'), findsOneWidget);
    expect(
      find.text('Vous n’avez aucune notification pour le moment.'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsNothing);
    expect(find.text('Impossible de charger les notifications.'), findsNothing);
  });

  testWidgets('genuine load failure shows error and retry action',
      (tester) async {
    var loadCount = 0;
    await tester.pumpWidget(_screen(
      locale: const Locale('en'),
      loadNotifications: () {
        loadCount++;
        return Future<MobileNotificationPage>.error(
          Exception('HTTP 500'),
        );
      },
    ));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load notifications.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No notifications'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
    expect(find.text('Unable to load notifications.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
