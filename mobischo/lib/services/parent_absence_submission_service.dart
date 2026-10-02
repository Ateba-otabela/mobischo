import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobischo/services/mobile_api_service.dart';

class EligibleAbsence {
  final int id;
  final String date;
  final String className;
  final String status;

  const EligibleAbsence({
    required this.id,
    required this.date,
    required this.className,
    required this.status,
  });

  factory EligibleAbsence.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse((json['id'] ?? '').toString());
    final date = (json['DateEnreg'] ?? '').toString();
    if (id == null || id <= 0 || DateTime.tryParse(date) == null) {
      throw const FormatException('Invalid eligible absence record.');
    }

    return EligibleAbsence(
      id: id,
      date: date,
      className: (json['class_name'] ?? '').toString(),
      status: (json['CodeEtatCond'] ?? '').toString(),
    );
  }
}

class ParentAbsenceSubmissionService {
  static const _endpoint = '/parent/absence-justifications';

  static Future<List<EligibleAbsence>> getEligibleAbsences(
    String studentCode,
  ) async {
    final response = await MobileApiService.post(
      _endpoint,
      headers: const {'Accept': 'application/json'},
      body: {
        'action': 'GET_PARENT_CHILD_ABSENCES',
        'CodeEleve': studentCode,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'Loading eligible absence records failed (HTTP ${response.statusCode}).',
      );
      throw StateError('Unable to load eligible absence records.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Eligible absences response is not a list.');
    }

    return decoded
        .whereType<Map>()
        .map((record) => EligibleAbsence.fromJson(
              Map<String, dynamic>.from(record),
            ))
        .toList();
  }

  static Future<void> submit({
    required String studentCode,
    required int absenceId,
    required String reason,
    required String reasonDetail,
    required String explanation,
    Uint8List? documentBytes,
    String? documentName,
  }) async {
    final fields = <String, String>{
      'action': 'SUBMIT_ABSENCE_JUSTIFICATION',
      'CodeEleve': studentCode,
      'absence_id': absenceId.toString(),
      'reason': reason,
      'reason_detail': reasonDetail,
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
