import 'dart:convert';

import 'package:mobischo/services/mobile_api_service.dart';

class ParentAbsenceHistoryService {
  static Future<List<Map<String, dynamic>>> getRecentJustifications() async {
    final response = await MobileApiService.post(
      '/parent/absence-justifications',
      headers: const {'Accept': 'application/json'},
      body: const {'action': 'GET_PARENT_ABSENCE_JUSTIFICATIONS'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Impossible de charger l’historique (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Invalid absence history response.');
    }

    return decoded
        .whereType<Map>()
        .map((record) => Map<String, dynamic>.from(record))
        .toList();
  }
}
