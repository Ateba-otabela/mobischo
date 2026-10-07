import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mobischo/models/mobile_notification.dart';
import 'package:mobischo/services/mobile_api_service.dart';

class NotificationInboxService {
  static Future<MobileNotificationPage> load() async {
    const path = '/notifications';
    try {
      final response = await MobileApiService.get(
        path,
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) {
        _logResponse(path, response.statusCode, response.body);
        throw Exception(
          'Unable to load notifications (${response.statusCode}).',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        _logResponse(path, response.statusCode, response.body);
        rethrow;
      }
      if (decoded is! Map<String, dynamic>) {
        _logResponse(path, response.statusCode, response.body);
        throw const FormatException('Invalid notifications response.');
      }
      late MobileNotificationPage page;
      try {
        page = MobileNotificationPage.fromJson(decoded);
      } on FormatException {
        _logResponse(path, response.statusCode, response.body);
        rethrow;
      }
      if (kDebugMode) {
        debugPrint(
          'Notification inbox GET $path: HTTP ${response.statusCode}; '
          'data_type=${decoded['data'].runtimeType}; '
          'items=${page.notifications.length}; '
          'unread_count=${page.unreadCount}.',
        );
      }
      return page;
    } on Exception catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Notification inbox GET $path failed: '
          '${error.runtimeType}: ${_redact(error.toString())}',
        );
      }
      rethrow;
    }
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

  static void _logResponse(String path, int statusCode, String body) {
    if (!kDebugMode) return;
    final safeBody = _redact(body);
    debugPrint(
      'Notification inbox GET $path: HTTP $statusCode; '
      'response_body=${safeBody.substring(0, safeBody.length > 500 ? 500 : safeBody.length)}',
    );
  }

  static String _redact(String value) {
    return value
        .replaceAll(
          RegExp(
            r'("(?:access_token|refresh_token|token|password|secret|api_key)"\s*:\s*)"[^"]*"',
            caseSensitive: false,
          ),
          r'$1"[REDACTED]"',
        )
        .replaceAll(
          RegExp(r'Bearer\s+\S+', caseSensitive: false),
          'Bearer [REDACTED]',
        );
  }
}
