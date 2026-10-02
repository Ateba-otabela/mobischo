import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobischo/services/mobile_api_service.dart';

class ParentAbsenceSubmissionService {
  static const _endpoint = '/parent/absence-justifications';

  static Future<void> submit({
    required String studentCode,
    required DateTime absenceDate,
    required String reason,
    required String explanation,
    Uint8List? documentBytes,
    String? documentName,
  }) async {
    final date = '${absenceDate.year.toString().padLeft(4, '0')}-'
        '${absenceDate.month.toString().padLeft(2, '0')}-'
        '${absenceDate.day.toString().padLeft(2, '0')}';
    final fields = <String, String>{
      'action': 'SUBMIT_ABSENCE_JUSTIFICATION',
      'CodeEleve': studentCode,
      'date_absence': date,
      'reason': reason,
      'justification': explanation,
    };
    final file = documentBytes == null
        ? null
        : http.MultipartFile.fromBytes(
            'document',
            documentBytes,
            filename: documentName,
          );

    final response = await MobileApiService.postMultipart(
      _endpoint,
      fields: fields,
      file: file,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'Submitting absence justification failed '
        '(HTTP ${response.statusCode}).',
      );
      throw StateError('Unable to submit absence justification.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['status'] != 'success') {
      throw const FormatException('Invalid justification submission response.');
    }
  }
}
