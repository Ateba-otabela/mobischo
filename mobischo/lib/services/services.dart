// ignore_for_file: import_of_legacy_library_into_null_safe, constant_identifier_names, avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobischo/models/user.dart';

class Services {
  static const ROOT = 'https://mobischo.com/api/school_manager';
  static const GET_ALL_ACTION = 'GET_ALL';
  static const GET_MAIN_USER_ACTION = 'GET_MAIN_USER';
  static const GET_TEACHER_COLLEAGUES_ACTION = 'GET_TEACHER_COLLEAGUES';

  static Future<List<User>> getUsers() async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_ALL_ACTION;
      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get users Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<User> users = parseResponse(response.body);
          return users;
        } catch (e) {
          print(e.toString());
          return <User>[];
        }
      } else {
        return <User>[];
      }
    } catch (e) {
      print(e.toString());
      return <User>[];
    }
  }

  static Future<String> getMainUser(String code) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_MAIN_USER_ACTION;
      map['code'] = code;

      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get main user Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<User> users = parseResponse(response.body);
          User user = users.first;
          // print(matiere.LibelleMatiere.toString());
          return "${user.nom.toString()} ${user.prenom.toString()}";
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

  static Future<List<User>> getTeacherColleagues({
    required String teacherCode,
    required String schoolCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ROOT),
        body: {
          'action': GET_TEACHER_COLLEAGUES_ACTION,
          'teacher_code': teacherCode,
          'CodeEtablissement': schoolCode,
        },
      );

      if (response.statusCode != 200) {
        return <User>[];
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        return <User>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map<User>((json) => User.fromJson(json))
          .toList();
    } catch (e) {
      print(e.toString());
      return <User>[];
    }
  }

  static List<User> parseResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<User>((json) => User.fromJson(json)).toList();
  }
}
