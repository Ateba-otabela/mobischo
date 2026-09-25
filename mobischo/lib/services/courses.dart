// ignore_for_file: import_of_legacy_library_into_null_safe, constant_identifier_names, avoid_print, non_constant_identifier_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobischo/models/class.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/matiere.dart';

class CourseServices {
  static const ROOT = 'https://mobischo.com/api/school_manager';
  static const GET_ALL_ACTION = 'GET_ALL_COURSES';
  static const GET_TEACHER_COURSES_ACTION = 'GET_TEACHER_COURSES';
  static const GET_CLASS_COURSES_ACTION = 'GET_CLASS_COURSES';
  static const GET_MAIN_COURSE_ACTION = 'GET_MAIN_COURSE';
  static const GET_MAIN_CLASS_ACTION = 'GET_MAIN_CLASS';

  static Future<List<Course>> getAllCourses() async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_ALL_ACTION;
      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get all Courses Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Course> courses = parseResponse(response.body);
          return courses;
        } catch (e) {
          print(e);
          return <Course>[];
        }
      } else {
        return <Course>[];
      }
    } catch (e) {
      return <Course>[];
    }
  }

  static Future<List<Course>> getTeacherCourses(String teacherCode) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_TEACHER_COURSES_ACTION;
      map['teacher_code'] = teacherCode;

      print('teacher code : $teacherCode');

      var response = await http.post(Uri.parse(ROOT), body: map);
      // print("get teacher Courses Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Course> courses = parseResponse(response.body);
          return courses;
        } catch (e) {
          print(e);
          return <Course>[];
        }
      } else {
        return <Course>[];
      }
    } catch (e) {
      return <Course>[];
    }
  }

  static Future<List<Course>> getTeacherCoursesForNotes(
      String teacherCode) async {
    final response = await http.post(Uri.parse(ROOT), body: {
      'action': GET_TEACHER_COURSES_ACTION,
      'teacher_code': teacherCode,
    });
    if (response.statusCode != 200) {
      throw Exception('Unable to load teacher subjects');
    }
    try {
      return parseResponse(response.body);
    } catch (_) {
      throw Exception('Invalid teacher subjects response');
    }
  }

  static Future<List<Course>> getClassCourses(String CodeClasse) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_CLASS_COURSES_ACTION;
      map['CodeClasse'] = CodeClasse;

      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get class Courses Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Course> courses = parseResponse(response.body);
          return courses;
        } catch (e) {
          print(e);
          return <Course>[];
        }
      } else {
        return <Course>[];
      }
    } catch (e) {
      return <Course>[];
    }
  }

  static Future<String> getMainCourse(String codeMatiere) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_MAIN_COURSE_ACTION;
      map['code_matiere'] = codeMatiere;
      // print("code matiere : $codeMatiere");

      var response = await http.post(Uri.parse(ROOT), body: map);
      // print("get main Course Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Matiere> courses = parseMatiereResponse(response.body);
          Matiere matiere = courses.first;
          // print(matiere.LibelleMatiere.toString());
          return matiere.LibelleMatiere.toString();
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

  static Future<String> getMainClass(String codeClasse) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_MAIN_CLASS_ACTION;
      map['code_classe'] = codeClasse;

      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get main Class Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Classe> classes = parseClasseResponse(response.body);
          Classe classe = classes.first;
          // print(matiere.LibelleMatiere.toString());
          return classe.LibelleClasse.toString();
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

  static List<Course> parseResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Course>((json) => Course.fromJson(json)).toList();
  }

  static List<Matiere> parseMatiereResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Matiere>((json) => Matiere.fromJson(json)).toList();
  }

  static List<Classe> parseClasseResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Classe>((json) => Classe.fromJson(json)).toList();
  }
}
