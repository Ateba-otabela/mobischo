import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobischo/models/institution.dart';

class InstitutionServices {
  static const root = 'https://mobischo.com/api/school_manager';
  static const getInstitutionsAction = 'GET_INSTITUTIONS';

  static Future<List<Institution>> getInstitutions({
    String? search,
    String? type,
    String? category,
    String? location,
    int page = 1,
    int perPage = 12,
  }) async {
    try {
      final body = <String, dynamic>{
        'action': getInstitutionsAction,
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if ((search ?? '').trim().isNotEmpty) {
        body['search'] = search!.trim();
      }
      if ((type ?? '').trim().isNotEmpty) {
        body['type'] = type!.trim();
      }
      if ((category ?? '').trim().isNotEmpty) {
        body['category'] = category!.trim();
      }
      if ((location ?? '').trim().isNotEmpty) {
        body['location'] = location!.trim();
      }

      final response = await http.post(Uri.parse(root), body: body);
      if (response.statusCode != 200) {
        return <Institution>[];
      }

      if (response.body.trim().isEmpty) {
        return <Institution>[];
      }

      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final items = decoded['data'];
        if (items is List) {
          return items
              .whereType<Map<String, dynamic>>()
              .map<Institution>((item) => Institution.fromJson(item))
              .toList();
        }
      }

      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map<Institution>((item) => Institution.fromJson(item))
            .toList();
      }

      return <Institution>[];
    } catch (_) {
      return <Institution>[];
    }
  }
}
