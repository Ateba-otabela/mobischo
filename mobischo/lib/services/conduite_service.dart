// ignore_for_file: constant_identifier_names, avoid_print, non_constant_identifier_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobischo/models/conduite.dart';
import 'package:mobischo/models/student.dart';

class ConduiteServices {
  static const ROOT = 'https://mobischo.com/api/school_manager';
  // static const GET_ALL_ACTION = 'GET_ALL_ABSENCES';
  static const ADD_ACTION = 'ADD_CONDUITE';
  static const GET_TEACHER_ATTENDANCE_ACTION = 'GET_TEACHER_ATTENDANCE';
  static const SAVE_TEACHER_ATTENDANCE_ACTION = 'SAVE_TEACHER_ATTENDANCE';
  static const UPDATE_TEACHER_ATTENDANCE_ACTION = 'UPDATE_TEACHER_ATTENDANCE';
  static const GET_COURSE_ABSENCES_ACTION = 'GET_COURSE_ABSENCES';

  static const GET_COURSE_STUDENT_ABSENCES_ACTION =
      'GET_COURSE_STUDENT_ABSENCES';

  static const GET_ALL_STUDENT_ABSENCES_ACTION = 'GET_ALL_STUDENT_ABSENCES';

  static const GET_SORTED_COURSE_ABSENCES_ACTION = 'GET_SORTED_COURSE_ABSENCES';

  static const GET_SORTED_STUDENT_ABSENCES_ACTION =
      'GET_SORTED_STUDENT_ABSENCES';

  static const GET_SORTED_ALL_STUDENT_ABSENCES_ACTION =
      'GET_SORTED_ALL_STUDENT_ABSENCES';
  static const GET_SORTED_COURSE_ABSENT_STUDENTS_ACTION =
      'GET_SORTED_COURSE_ABSENT_STUDENTS';
  static const CLEAR_ACTION = 'CLEAR';

  static Future<List<Conduite>> getTeacherAttendance(
      String teacherCode, String codeEnseignement,
      [String? date]) async {
    final requestBody = <String, String>{
      'action': GET_TEACHER_ATTENDANCE_ACTION,
      'teacher_code': teacherCode,
      'CodeEnseignement': codeEnseignement,
      if (date != null && date.isNotEmpty) 'DateEnreg': date,
    };
    final response = await http.post(Uri.parse(ROOT), body: requestBody);
    print('GET_TEACHER_ATTENDANCE status: ${response.statusCode}');
    print(
        'GET_TEACHER_ATTENDANCE content-type: ${response.headers['content-type']}');
    print('GET_TEACHER_ATTENDANCE request action: ${requestBody['action']}');
    print('GET_TEACHER_ATTENDANCE teacher_code: $teacherCode');
    print('GET_TEACHER_ATTENDANCE CodeEnseignement: $codeEnseignement');
    print('GET_TEACHER_ATTENDANCE DateEnreg: ${date ?? '<not sent>'}');
    print('GET_TEACHER_ATTENDANCE body: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Unable to load attendance (${response.statusCode})');
    }
    try {
      final decoded = jsonDecode(response.body);
      print('GET_TEACHER_ATTENDANCE decoded type: ${decoded.runtimeType}');
      if (decoded is! List) {
        throw const FormatException('Attendance response is not a JSON array');
      }
      return parseResponse(response.body);
    } catch (error) {
      print('GET_TEACHER_ATTENDANCE parse error: $error');
      throw Exception('Invalid attendance response');
    }
  }

  static Future<bool> saveTeacherAttendance({
    required String teacherCode,
    required String date,
    required String codeAnnee,
    required String codeEnseignement,
    required List<Map<String, String>> statuses,
  }) async {
    final response = await http.post(Uri.parse(ROOT), body: {
      'action': SAVE_TEACHER_ATTENDANCE_ACTION,
      'teacher_code': teacherCode,
      'DateEnreg': date,
      'CodeAnnee': codeAnnee,
      'CodeEnseignement': codeEnseignement,
      'statuses': jsonEncode(statuses),
    });
    return response.statusCode == 200;
  }

  static Future<bool> updateTeacherAttendance({
    required String teacherCode,
    required String codeEnseignement,
    required String date,
    required List<Map<String, String>> records,
  }) async {
    final response = await http.post(Uri.parse(ROOT), body: {
      'action': UPDATE_TEACHER_ATTENDANCE_ACTION,
      'teacher_code': teacherCode,
      'CodeEnseignement': codeEnseignement,
      'DateEnreg': date,
      'records': jsonEncode(records),
    });
    return response.statusCode == 200;
  }

  static Future<String> AddConduite(
      String DateEnreg,
      String CodeEleve,
      String Nombre,
      String CodeClasse,
      String CodeAnnee,
      String CodeMatiere,
      String CodeEnseignement,
      String HeureMatiere) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = ADD_ACTION;
      map['DateEnreg'] = DateEnreg;
      map['CodeEleve'] = CodeEleve;
      map['Nombre'] = Nombre;
      map['CodeEtatCond'] = "";
      map['CodeClasse'] = CodeClasse;
      map['CodeAnnee'] = CodeAnnee;
      map['CodeMatiere'] = CodeMatiere;
      map['CodeEnseignement'] = CodeEnseignement;
      map['HeureMatiere'] = HeureMatiere;

      print('CodeClasse: $CodeClasse');
      final response = await http.post(Uri.parse(ROOT), body: map);

      print("insert Conduite Response : ${response.body}");
      print(json.decode(response.body));

      if (200 == response.statusCode) {
        try {
          var parsed = json.decode(response.body);
          if (parsed == 'Error') {
            print("ERROR INSERTING INTO DATABASE");
          } else {
            print('RECORD INSERTED SUCCESSFULLY !');
          }
          // List<Conduite> conduites = parseResponse(response.body);
          // Conduite conduite = conduites.first;
          // print(matiere.LibelleMatiere.toString());
          return "Success";
        } catch (e) {
          print(e);
          return "Error";
        }
      } else {
        return "Error";
      }
    } catch (e) {
      return "Error";
    }
  }

  static Future<String> clearConduite(
    String CodeEnseignement,
    String DateEnreg,
  ) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = CLEAR_ACTION;
      map['sortedDate'] = DateEnreg;
      map['CodeEnseignement'] = CodeEnseignement;

      print(DateEnreg);
      print(CodeEnseignement);

      final response = await http.post(Uri.parse(ROOT), body: map);

      print("clear Conduite Response : ${response.body}");
      print(json.decode(response.body));

      if (200 == response.statusCode) {
        try {
          var parsed = json.decode(response.body);
          if (parsed == 'Error') {
            print("ERROR DELETING INTO DATABASE");
          } else {
            print('RECORD DELETED SUCCESSFULLY !');
          }
          // List<Conduite> conduites = parseResponse(response.body);
          // Conduite conduite = conduites.first;
          // print(matiere.LibelleMatiere.toString());
          return "Success";
        } catch (e) {
          print(e);
          return "Error";
        }
      } else {
        return "Error";
      }
    } catch (e) {
      return "Error";
    }
  }

  static Future<List<Conduite>> getCourseAbsences(
      String codeEnseignement) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_COURSE_ABSENCES_ACTION;
      map['CodeEnseignement'] = codeEnseignement;
      print(codeEnseignement);
      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get course absences Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Conduite> absences = parseResponse(response.body);
          return absences;
        } catch (e) {
          print(e.toString());
          return <Conduite>[];
        }
      } else {
        return <Conduite>[];
      }
    } catch (e) {
      print(e.toString());
      return <Conduite>[];
    }
  }

  static Future<List<Conduite>> getStudentAbsences(
      String codeEnseignement, String codeEleve) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_COURSE_STUDENT_ABSENCES_ACTION;
      map['CodeEnseignement'] = codeEnseignement;
      map['CodeEleve'] = codeEleve;
      print(codeEleve);

      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get course student absences Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Conduite> absences = parseResponse(response.body);
          return absences;
        } catch (e) {
          print(e.toString());
          return <Conduite>[];
        }
      } else {
        return <Conduite>[];
      }
    } catch (e) {
      print(e.toString());
      return <Conduite>[];
    }
  }

  static Future<List<Conduite>> getAllStudentAbsences(String codeEleve) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_ALL_STUDENT_ABSENCES_ACTION;
      // map['CodeEnseignement'] = codeEnseignement;
      map['CodeEleve'] = codeEleve;
      print(codeEleve);

      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get course student absences Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Conduite> absences = parseResponse(response.body);
          return absences;
        } catch (e) {
          print(e.toString());
          return <Conduite>[];
        }
      } else {
        return <Conduite>[];
      }
    } catch (e) {
      print(e.toString());
      return <Conduite>[];
    }
  }

  static Future<List<Conduite>> getSortedAllStudentAbsences(
      String codeEleve, String sortedDate) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_SORTED_ALL_STUDENT_ABSENCES_ACTION;
      map['CodeEleve'] = codeEleve;
      map['sortedDate'] = sortedDate;

      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get sorted all student absences Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Conduite> absences = parseResponse(response.body);
          return absences;
        } catch (e) {
          print(e.toString());
          return <Conduite>[];
        }
      } else {
        return <Conduite>[];
      }
    } catch (e) {
      print(e.toString());
      return <Conduite>[];
    }
  }

  static Future<List<Conduite>> getSortedStudentAbsences(
      String codeEnseignement, String codeEleve, String sortedDate) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_SORTED_STUDENT_ABSENCES_ACTION;
      map['CodeEnseignement'] = codeEnseignement;
      map['CodeEleve'] = codeEleve;
      map['sortedDate'] = sortedDate;
      print("sorted date : $sortedDate");

      print(codeEnseignement);
      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get sorted student absences Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Conduite> absences = parseResponse(response.body);
          return absences;
        } catch (e) {
          print(e.toString());
          return <Conduite>[];
        }
      } else {
        return <Conduite>[];
      }
    } catch (e) {
      print(e.toString());
      return <Conduite>[];
    }
  }

  static Future<List<Conduite>> getSortedCourseAbsences(
      String codeEnseignement, String sortedDate) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_SORTED_COURSE_ABSENCES_ACTION;
      map['CodeEnseignement'] = codeEnseignement;
      map['sortedDate'] = sortedDate;

      print(codeEnseignement);
      final response = await http.post(Uri.parse(ROOT), body: map);
      // print("get sorted course absences Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Conduite> absences = parseResponse(response.body);
          return absences;
        } catch (e) {
          print(e.toString());
          return <Conduite>[];
        }
      } else {
        return <Conduite>[];
      }
    } catch (e) {
      print(e.toString());
      return <Conduite>[];
    }
  }

  static Future<List<Student>> getSortedCourseAbsentStudents(
      String codeEnseignement, String sortedDate) async {
    try {
      var map = <String, dynamic>{};
      map['action'] = GET_SORTED_COURSE_ABSENT_STUDENTS_ACTION;
      map['CodeEnseignement'] = codeEnseignement;
      map['sortedDate'] = sortedDate;

      print(codeEnseignement);
      final response = await http.post(Uri.parse(ROOT), body: map);
      print("get sorted course absent students Response : ${response.body}");

      if (200 == response.statusCode) {
        try {
          List<Student> students = parseStudentResponse(response.body);
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

  static List<Conduite> parseResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Conduite>((json) => Conduite.fromJson(json)).toList();
  }

  static List<Student> parseStudentResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Student>((json) => Student.fromJson(json)).toList();
  }
}
