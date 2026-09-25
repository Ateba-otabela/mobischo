// ignore_for_file: constant_identifier_names, avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobischo/models/school.dart';

class SchoolServices {
  static const ROOT = 'https://mobischo.com/api/school_manager';
  static const GET_ALL_ACTION = 'GET_ALL';
  static const GET_MAIN_SCHOOL_ACTION = 'GET_MAIN_SCHOOL';

  static Future<String> getMainSchool(String codeEtablissement) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_MAIN_SCHOOL_ACTION;
      map['codeEtablissement'] = codeEtablissement;

      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get main School Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<School> schools = parseResponse(response.body);
          School school = schools.first;
          // print(matiere.LibelleMatiere.toString());
          return school.Nom.toString();
        } catch (e) {
          print(e);
          return "";
        }
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }

  static List<School> parseResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<School>((json) => School.fromJson(json)).toList();
  }
}
