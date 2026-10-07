// ignore_for_file: constant_identifier_names, avoid_print, non_constant_identifier_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobischo/models/mark.dart';

class MarkServices {
  static const ROOT = 'https://mobischo.com/api/school_manager';
  static const GET_ALL_ACTION = 'GET_ALL';
  static const GET_COURSE_MARKS_ACTION = 'GET_COURSE_MARKS';
  static const GET_STUDENT_MARKS_ACTION = 'GET_STUDENT_MARKS';
  static const GET_SORTED_STUDENT_MARKS_ACTION = 'GET_SORTED_STUDENT_MARKS';
  static const GET_SORTED_COURSE_MARKS_ACTION = 'GET_SORTED_COURSE_MARKS';
  static const GET_STUDENT_YEAR_MARKS_ACTION = 'GET_STUDENT_YEAR_MARKS';
  static const GET_COURSE_YEAR_MARKS_ACTION = 'GET_COURSE_YEAR_MARKS';
  static const _notesRequestTimeout = Duration(seconds: 20);

  static Future<List<Mark>> getCourseMarks(String codeEnseignement) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_COURSE_MARKS_ACTION;
      map['CodeEnseignement'] = codeEnseignement;

      var response = await http
          .post(Uri.parse(ROOT), body: map)
          .timeout(_notesRequestTimeout);

      // print("get course marks Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Mark> marks = parseResponse(response.body);
          return marks;
        } catch (e) {
          print(e.toString());
          return <Mark>[];
        }
      } else {
        return <Mark>[];
      }
    } catch (e) {
      print((e).toString());
      return <Mark>[];
    }
  }

  static Future<List<Mark>> getCourseMarksForNotes(
      String codeEnseignement) async {
    final response = await http.post(Uri.parse(ROOT), body: {
      'action': GET_COURSE_MARKS_ACTION,
      'CodeEnseignement': codeEnseignement,
    }).timeout(_notesRequestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Unable to load course marks');
    }
    try {
      return parseResponse(response.body);
    } catch (_) {
      throw Exception('Invalid course marks response');
    }
  }

  static Future<List<Mark>> getStudentYearMarksForNotes(
      String codeEleve, String codeAnnee) async {
    final response = await http.post(Uri.parse(ROOT), body: {
      'action': GET_STUDENT_YEAR_MARKS_ACTION,
      'codeEleve': codeEleve,
      'codeAnnee': codeAnnee,
    }).timeout(_notesRequestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Unable to load student notes');
    }
    try {
      return parseResponse(response.body);
    } catch (_) {
      throw Exception('Invalid student notes response');
    }
  }

  static Future<List<Mark>> getCourseYearMarksForNotes(
      String codeEnseignement, String codeAnnee) async {
    final response = await http.post(Uri.parse(ROOT), body: {
      'action': GET_COURSE_YEAR_MARKS_ACTION,
      'codeEnseignement': codeEnseignement,
      'codeAnnee': codeAnnee,
    }).timeout(_notesRequestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Unable to load course notes');
    }
    try {
      return parseResponse(response.body);
    } catch (_) {
      throw Exception('Invalid course notes response');
    }
  }

  static Future<List<Mark>> getStudentMarks(
      String CodeEleve, String CodeEnseignement) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_STUDENT_MARKS_ACTION;
      map['CodeEleve'] = CodeEleve;
      map['CodeEnseignement'] = CodeEnseignement;

      // print('code eleve: $CodeEleve');
      // print('code enseignement: $CodeEnseignement');

      final response = await http
          .post(Uri.parse(ROOT), body: map)
          .timeout(_notesRequestTimeout);
      print("get student marks Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Mark> marks = parseResponse(response.body);
          return marks;
        } catch (e) {
          print(e.toString());
          return <Mark>[];
        }
      } else {
        return <Mark>[];
      }
    } catch (e) {
      print(e.toString());
      return <Mark>[];
    }
  }

  static Future<List<Mark>> getSortedStudentMarks(String CodeEleve,
      String CodeEnseignement, String sequence, String year) async {
    try {
      // print('here');
      var map = <String, dynamic>{};
      map['action'] = GET_SORTED_STUDENT_MARKS_ACTION;
      map['codeEleve'] = CodeEleve;
      map['codeAnnee'] = year;
      map['codeEvaluation'] = sequence;
      // print("sequence : ${sequence}");z
      map['codeEnseignement'] = CodeEnseignement;

      final response = await http
          .post(Uri.parse(ROOT), body: map)
          .timeout(_notesRequestTimeout);
      print("get sorted student marks Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Mark> marks = parseResponse(response.body);
          return marks;
        } catch (e) {
          print(e.toString());
          return <Mark>[];
        }
      } else {
        return <Mark>[];
      }
    } catch (e) {
      print(e.toString());
      return <Mark>[];
    }
  }

  static Future<List<Mark>> getSortedCourseMarks(String codeEnseignement,
      String sequenceEvaluation, String codeAnnee) async {
    try {
      var map = <String, dynamic>{};

      map['action'] = GET_SORTED_COURSE_MARKS_ACTION;
      map['codeEnseignement'] = codeEnseignement;
      map['codeAnnee'] = codeAnnee.toString();
      map['codeEvaluation'] = sequenceEvaluation;
      final response = await http
          .post(Uri.parse(ROOT), body: map)
          .timeout(_notesRequestTimeout);
      print("get sorted marks Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Mark> marks = parseResponse(response.body);
          return marks;
        } catch (e) {
          print(e.toString());
          return <Mark>[];
        }
      } else {
        return <Mark>[];
      }
    } catch (e) {
      print(e.toString());
      return <Mark>[];
    }
  }

  static List<Mark> parseResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Mark>((json) => Mark.fromJson(json)).toList();
  }
}
