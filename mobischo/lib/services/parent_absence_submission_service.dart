import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobischo/services/mobile_api_service.dart';

class ParentAbsenceSubmissionException implements Exception {
  final String message;
  final int statusCode;

  const ParentAbsenceSubmissionException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class ParentAbsenceSubmissionService {
  static const _endpoint = '/parent/absence-justifications';

  static Future<void> submit({
    required String studentCode,
    required DateTime absenceDate,
    required String reason,
    required String explanation,
  }) async {
    final date = '${absenceDate.year.toString().padLeft(4, '0')}-'
        '${absenceDate.month.toString().padLeft(2, '0')}-'
        '${absenceDate.day.toString().padLeft(2, '0')}';
    final body = <String, String>{
      'action': 'SUBMIT_ABSENCE_JUSTIFICATION',
      'CodeEleve': studentCode,
      'date_absence': date,
      'reason': reason,
      'justification': explanation,
    };

    final response = await MobileApiService.post(
      _endpoint,
      body: body,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 409) {
        final error = _responseError(response);
        throw ParentAbsenceSubmissionException(
          error.isNotEmpty
              ? error
              : 'Une justification est déjà en attente pour cet élève à cette date.',
          response.statusCode,
        );
      }
      debugPrint(
        'Submitting absence justification failed '
        '(HTTP ${response.statusCode}).',
      );
      throw ParentAbsenceSubmissionException(
        _responseError(response),
        response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['status'] != 'success') {
      throw const FormatException('Invalid justification submission response.');
    }
  }

  static String _responseError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return '';

      final error = decoded['error']?.toString().trim() ?? '';
      if (error.isNotEmpty) return error;

      final errors = decoded['errors'];
      if (errors is Map) {
        for (final messages in errors.values) {
          if (messages is Iterable) {
            for (final message in messages) {
              final text = message.toString().trim();
              if (text.isNotEmpty) return text;
            }
          }
        }
      }

      final message = decoded['message']?.toString().trim() ?? '';
      if (message.isNotEmpty && message != 'The given data was invalid.') {
        return message;
      }
    } on FormatException {
      return '';
    }

    return '';
  }
}
