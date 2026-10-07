import 'package:flutter_test/flutter_test.dart';
import 'package:mobischo/models/mobile_notification.dart';

void main() {
  group('MobileNotificationPage.fromJson', () {
    test('accepts an empty collection and zero unread count', () {
      final page = MobileNotificationPage.fromJson({
        'data': <dynamic>[],
        'unread_count': 0,
      });

      expect(page.notifications, isEmpty);
      expect(page.unreadCount, 0);
    });

    test('keeps unread count separate from total notification count', () {
      final page = MobileNotificationPage.fromJson({
        'data': [
          {
            'id': 'read-1',
            'title': 'Info',
            'body': 'Already read',
            'data': <String, dynamic>{},
            'created_at': null,
            'read_at': '2026-10-07T10:00:00Z',
            'is_read': true,
          },
          {
            'id': 'unread-1',
            'title': 'Info',
            'body': 'Unread',
            'data': <String, dynamic>{},
            'created_at': null,
            'read_at': null,
            'is_read': false,
          },
        ],
        'unread_count': 1,
      });

      expect(page.notifications, hasLength(2));
      expect(page.unreadCount, 1);
    });

    test('rejects a malformed response instead of treating it as empty', () {
      expect(
        () => MobileNotificationPage.fromJson({
          'message': 'Unauthenticated.',
        }),
        throwsFormatException,
      );
    });

    test('rejects malformed notification entries', () {
      expect(
        () => MobileNotificationPage.fromJson({
          'data': ['not a notification'],
          'unread_count': 0,
        }),
        throwsFormatException,
      );
    });
  });
}
