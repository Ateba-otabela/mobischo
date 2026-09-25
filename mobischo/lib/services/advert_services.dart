// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobischo/models/advert.dart';

class AdvertServices {
  static const ROOT = 'https://mobischo.com/api/school_manager';
  static const GET_ADVERTS_ACTION = 'GET_ADVERTS';

  static Future<List<Advert>> getSchoolAdverts() async {
    try {
      final map = <String, dynamic>{};
      map['action'] = GET_ADVERTS_ACTION;

      final response = await http.post(Uri.parse(ROOT), body: map);

      if (response.statusCode != 200) {
        return <Advert>[];
      }

      if (response.body.trim().isEmpty) {
        return <Advert>[];
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        return <Advert>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map<Advert>((item) => Advert.fromJson(item))
          .toList();
    } catch (_) {
      return <Advert>[];
    }
  }
}
