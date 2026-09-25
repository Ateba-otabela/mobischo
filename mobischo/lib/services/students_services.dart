// ignore_for_file: constant_identifier_names, avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobischo/models/student.dart';

class StudentServices {
  static const ROOT = 'https://mobischo.com/api/school_manager';
  static const GET_ALL_ACTION = 'GET_ALL_STUDENTS';
  static const GET_COURSE_STUDENTS_ACTION = 'GET_COURSE_STUDENTS';
  static const GET_MAIN_STUDENT_ACTION = 'GET_MAIN_STUDENT';
  static const GET_PARENT_STUDENTS_ACTION = 'GET_PARENT_STUDENTS';

  static Future<List<Student>> getCourseStudents(String codeClasse) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_COURSE_STUDENTS_ACTION;
      map['codeClasse'] = codeClasse;
      // print("Code classe $codeClasse");
      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get course students Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          if (response.body.isNotEmpty) {
            List<Student> students = parseResponse(response.body);
            return students;
          } else {
            print('empty responcse');
            return <Student>[];
          }
        } catch (e) {
          // print("herer");
          print(e.toString());
          return <Student>[];
        }
      } else {
        return <Student>[];
      }
    } catch (e) {
      print(e.toString());
      return <Student>[];
    }
  }

  static Future<List<Student>> getParentStudents(String code) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_PARENT_STUDENTS_ACTION;
      print(code);
      map['code'] = code;
      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get parent students Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Student> students = parseResponse(response.body);
          print("students : ");
          print(students);
          return students;
        } catch (e) {
          print(e.toString());
          return <Student>[];
        }
      } else {
        return <Student>[];
      }
    } catch (e) {
      print(e.toString());
      return <Student>[];
    }
  }

  static Future<List<Student>> getAllStudents(String codeEtablissement) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_ALL_ACTION;
      map['CodeEtablissement'] = codeEtablissement;

      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get all students Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Student> students = parseResponse(response.body);
          print("students : ");
          print(students);
          return students;
        } catch (e) {
          print(e.toString());
          return <Student>[];
        }
      } else {
        return <Student>[];
      }
    } catch (e) {
      print(e.toString());
      return <Student>[];
    }
  }

  static Future<String> getMainStudent(String codeEleve) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_MAIN_STUDENT_ACTION;
      map['codeEleve'] = codeEleve;
      // print('codeEleve : $codeEleve');
      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get main student Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Student> students = parseResponse(response.body);
          Student student = students.first;
          return "${student.Nom} ${student.Prenom}";
        } catch (e) {
          print(e.toString());
          return "hello1";
        }
      } else {
        return "hello2";
      }
    } catch (e) {
      print(e.toString());
      return "";
    }
  }

  static List<Student> parseResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Student>((json) => Student.fromJson(json)).toList();
  }
}
