import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobischo/models/absence_justification.dart';

class AbsenceJustificationService {
  static const String root = 'https://mobischo.com/api/school_manager';

  static Future<List<AbsenceJustification>> getParentJustifications(
      String parentCode) async {
    final response = await http.post(Uri.parse(root), body: {
      'action': 'GET_PARENT_ABSENCE_JUSTIFICATIONS',
      'code': parentCode,
    });
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les justificatifs.');
    }
    final data = json.decode(response.body) as List<dynamic>;
    return data
        .map((item) => AbsenceJustification.fromJson(
            item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> submit({
    required String parentCode,
    required String studentCode,
    required String absenceDate,
    required String motif,
    required String justification,
    String? attachment,
  }) async {
    final response = await http.post(Uri.parse(root), body: {
      'action': 'SUBMIT_ABSENCE_JUSTIFICATION',
      'code': parentCode,
      'CodeEleve': studentCode,
      'date_absence': absenceDate,
      'motif': motif,
      'justification': justification,
      'piece_jointe': attachment ?? '',
    });
    if (response.statusCode != 200) {
      throw Exception('La justification n’a pas pu être envoyée.');
    }
  }
}
