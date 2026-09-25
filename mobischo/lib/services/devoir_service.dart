// ignore_for_file: avoid_print, non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobischo/models/devoir.dart';

class DevoirServices {
  static const ROOT = 'https://mobischo.com/api/school_manager';
  static const GET_PARENT_DEVOIRS_ACTION = 'GET_PARENT_DEVOIRS';
  static const GET_TEACHER_DEVOIRS_ACTION = 'GET_TEACHER_DEVOIRS';
  static const CREATE_TEACHER_DEVOIR_ACTION = 'CREATE_TEACHER_DEVOIR';

  static Future<List<Devoir>> getParentDevoirs(
    String code, {
    String? codeEleve,
  }) async {
    try {
      final map = <String, dynamic>{
        'action': GET_PARENT_DEVOIRS_ACTION,
        'code': code,
      };
      if (codeEleve != null) {
        map['CodeEleve'] = codeEleve;
      }

      final response = await http.post(Uri.parse(ROOT), body: map);
      if (response.statusCode != 200) {
        return <Devoir>[];
      }
      return parseResponse(response.body);
    } catch (e) {
      print(e.toString());
      return <Devoir>[];
    }
  }

  static Future<List<Devoir>> getTeacherDevoirs({
    required String teacherCode,
    String? codeEnseignement,
    String? codeClasse,
    String? codeMatiere,
  }) async {
    final body = <String, dynamic>{
      'action': GET_TEACHER_DEVOIRS_ACTION,
      'teacher_code': teacherCode,
    };

    if (codeEnseignement != null && codeEnseignement.isNotEmpty) {
      body['CodeEnseignement'] = codeEnseignement;
    }
    if (codeClasse != null && codeClasse.isNotEmpty) {
      body['CodeClasse'] = codeClasse;
    }
    if (codeMatiere != null && codeMatiere.isNotEmpty) {
      body['CodeMatiere'] = codeMatiere;
    }

    final response = await http.post(Uri.parse(ROOT), body: body);
    if (response.statusCode != 200) {
      throw Exception('Unable to load teacher devoirs');
    }
    return parseResponse(response.body);
  }

  static Future<bool> createTeacherDevoir({
    required String teacherCode,
    required String codeEnseignement,
    required String titre,
    required String description,
    required String dateDuDevoir,
  }) async {
    final response = await http.post(Uri.parse(ROOT), body: {
      'action': CREATE_TEACHER_DEVOIR_ACTION,
      'teacher_code': teacherCode,
      'CodeEnseignement': codeEnseignement,
      'titre': titre,
      'description': description,
      'dateDuDevoir': dateDuDevoir,
    });
    if (response.statusCode != 201) return false;
    final decoded = json.decode(response.body);
    return decoded is Map<String, dynamic> && decoded['id'] != null;
  }

  static List<Devoir> parseResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Devoir>((json) => Devoir.fromJson(json)).toList();
  }
}
