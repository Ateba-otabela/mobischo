// ignore_for_file: import_of_legacy_library_into_null_safe, constant_identifier_names, avoid_print, unnecessary_null_comparison, non_constant_identifier_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobischo/models/HistoriqueInscription.dart';
import 'package:mobischo/models/inscription.dart';

class InscriptionServices {
  static const ROOT = 'https://mobischo.com/api/school_manager';
  static const GET_STUDENT_INSCRIPTIONS_ACTION = 'GET_STUDENT_INSCRIPTIONS';
  static const GET_SUM_INSCRIPTIONS_ACTION = 'GET_SUM_INSCRIPTIONS';
  static const GET_STUDENT_HISTORIQUE_INSCRIPTIONS_ACTION =
      'GET_STUDENT_HISTORIQUE_INSCRIPTIONS';

  static Future<List<Inscription>> getStudentInscription(
      String CodeEleve) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_STUDENT_INSCRIPTIONS_ACTION;
      map['CodeEleve'] = CodeEleve;

      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get student inscriptions Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Inscription> inscriptions =
              parseInscriptionResponse(response.body);
          return inscriptions;
        } catch (e) {
          print(e.toString());
          return <Inscription>[];
        }
      } else {
        return <Inscription>[];
      }
    } catch (e) {
      print(e.toString());
      return <Inscription>[];
    }
  }

  static Future<String> getSumInscription(
      String CodeEleve, String NUMFAC) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_SUM_INSCRIPTIONS_ACTION;
      map['NUMFAC'] = NUMFAC;
      map['CodeEleve'] = CodeEleve;

      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get sum inscriptions Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          var sum = jsonDecode(response.body).toString();
          return sum;
        } catch (e) {
          print(e.toString());
          return '0';
        }
      } else {
        return '0';
      }
    } catch (e) {
      print(e.toString());
      return '0';
    }
  }

  static Future<List<HistoriqueInscription>> getStudentHistoriqueInscription(
      String CodeEleve, String NUMFAC) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_STUDENT_HISTORIQUE_INSCRIPTIONS_ACTION;
      map['CodeEleve'] = CodeEleve;
      map['NUMFAC'] = NUMFAC;

      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get student historique inscriptions Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<HistoriqueInscription> historique_inscriptions =
              parseHistoriqueInscriptionResponse(response.body);
          return historique_inscriptions;
        } catch (e) {
          print(e.toString());
          return <HistoriqueInscription>[];
        }
      } else {
        return <HistoriqueInscription>[];
      }
    } catch (e) {
      print(e.toString());
      return <HistoriqueInscription>[];
    }
  }

  static List<Inscription> parseInscriptionResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed
        .map<Inscription>((json) => Inscription.fromJson(json))
        .toList();
  }

  static List<HistoriqueInscription> parseHistoriqueInscriptionResponse(
      String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed
        .map<HistoriqueInscription>(
            (json) => HistoriqueInscription.fromJson(json))
        .toList();
  }
}
