import 'dart:convert';

import 'package:mobischo/models/mobile_notification.dart';
import 'package:mobischo/services/mobile_api_service.dart';

class NotificationInboxService {
  static Future<MobileNotificationPage> load() async {
    final response = await MobileApiService.get(
      '/notifications',
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to load notifications (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid notifications response.');
    }
    return MobileNotificationPage.fromJson(decoded);
  }

  static Future<int> markAsRead(String id) async {
    final response = await MobileApiService.patch(
      '/notifications/${Uri.encodeComponent(id)}/read',
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Unable to mark notification as read (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid notification read response.');
    }
    return _responseUnreadCount(decoded);
  }

  static Future<int> markAllAsRead() async {
    final response = await MobileApiService.post(
      '/notifications/read-all',
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Unable to mark all notifications as read (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid notifications read response.');
    }
    return _responseUnreadCount(decoded);
  }

  static int _responseUnreadCount(Map<String, dynamic> json) {
    final value = json['unread_count'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
