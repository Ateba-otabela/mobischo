import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobischo/models/user.dart';

class PrincipalDashboardSession {
  final String date;
  final String time;
  final String className;
  final String subject;
  final String teacher;
  final int present;
  final int absent;
  final int late;
  final int studentCount;
  final int? attendancePercentage;

  const PrincipalDashboardSession({
    required this.date,
    required this.time,
    required this.className,
    required this.subject,
    required this.teacher,
    required this.present,
    required this.absent,
    required this.late,
    required this.studentCount,
    required this.attendancePercentage,
  });

  factory PrincipalDashboardSession.fromJson(Map<String, dynamic> json) {
    return PrincipalDashboardSession(
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      className: json['class']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      teacher: json['teacher']?.toString() ?? '',
      present: _toInt(json['present']),
      absent: _toInt(json['absent']),
      late: _toInt(json['late']),
      studentCount: _toInt(json['student_count']),
      attendancePercentage: _toNullableInt(json['attendance_percentage']),
    );
  }
}

class PrincipalAttendanceRecordData {
  final String codeEleve;
  final String studentName;
  final String status;

  const PrincipalAttendanceRecordData({
    required this.codeEleve,
    required this.studentName,
    required this.status,
  });

  factory PrincipalAttendanceRecordData.fromJson(Map<String, dynamic> json) {
    return PrincipalAttendanceRecordData(
      codeEleve: json['CodeEleve']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class PrincipalAttendanceData {
  final String date;
  final String time;
  final String codeClasse;
  final String codeMatiere;
  final String codeEnseignement;
  final String className;
  final String subject;
  final String teacher;
  final int present;
  final int absent;
  final int late;
  final int studentCount;
  final bool hasValidTotals;
  final int? attendancePercentage;
  final List<PrincipalAttendanceRecordData> records;

  const PrincipalAttendanceData({
    required this.date,
    required this.time,
    required this.codeClasse,
    required this.codeMatiere,
    required this.codeEnseignement,
    required this.className,
    required this.subject,
    required this.teacher,
    required this.present,
    required this.absent,
    required this.late,
    required this.studentCount,
    required this.hasValidTotals,
    required this.attendancePercentage,
    required this.records,
  });

  factory PrincipalAttendanceData.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'];
    final present = _toStrictInt(json['present']);
    final studentCount = _toStrictInt(json['student_count']);
    return PrincipalAttendanceData(
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      codeClasse: json['CodeClasse']?.toString() ?? '',
      codeMatiere: json['CodeMatiere']?.toString() ?? '',
      codeEnseignement: json['CodeEnseignement']?.toString() ?? '',
      className: json['class']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      teacher: json['teacher']?.toString() ?? '',
      present: present ?? 0,
      absent: _toInt(json['absent']),
      late: _toInt(json['late']),
      studentCount: studentCount ?? 0,
      hasValidTotals: present != null && studentCount != null,
      attendancePercentage: _toNullableInt(json['attendance_percentage']),
      records: rawRecords is List
          ? rawRecords
              .whereType<Map<String, dynamic>>()
              .map(PrincipalAttendanceRecordData.fromJson)
              .toList()
          : <PrincipalAttendanceRecordData>[],
    );
  }

  int? get calculatedAttendancePercentage {
    if (!hasValidTotals ||
        studentCount <= 0 ||
        present < 0 ||
        present > studentCount) {
      return null;
    }

    return (present / studentCount * 100).round();
  }
}

class PrincipalDashboardClassOverview {
  final String codeClasse;
  final String name;
  final int studentCount;
  final int boys;
  final int girls;
  final int subjectCount;
  final int sessionsToday;
  final int? attendancePercentage;

  const PrincipalDashboardClassOverview({
    required this.codeClasse,
    required this.name,
    required this.studentCount,
    required this.boys,
    required this.girls,
    required this.subjectCount,
    required this.sessionsToday,
    required this.attendancePercentage,
  });

  factory PrincipalDashboardClassOverview.fromJson(
      Map<String, dynamic> json) {
    return PrincipalDashboardClassOverview(
      codeClasse: json['CodeClasse']?.toString() ?? '',
      name: json['LibelleClasse']?.toString() ?? '',
      studentCount: _toInt(json['effectif']),
      boys: _toInt(json['garcons']),
      girls: _toInt(json['filles']),
      subjectCount: _toInt(json['total_matieres']),
      sessionsToday: _toInt(json['seances_du_jour']),
      attendancePercentage: _toNullableInt(json['taux_presence']),
    );
  }
}

class PrincipalClassTeacher {
  final String code;
  final String fullName;

  const PrincipalClassTeacher({required this.code, required this.fullName});

  factory PrincipalClassTeacher.fromJson(Map<String, dynamic> json) {
    return PrincipalClassTeacher(
      code: json['code']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
    );
  }
}

class PrincipalClassSubject {
  final String code;
  final String name;

  const PrincipalClassSubject({required this.code, required this.name});

  factory PrincipalClassSubject.fromJson(Map<String, dynamic> json) {
    return PrincipalClassSubject(
      code: json['CodeMatiere']?.toString() ?? '',
      name: json['LibelleMatiere']?.toString() ?? '',
    );
  }
}

class PrincipalClassSummary {
  final String codeClasse;
  final String name;
  final int studentCount;
  final int boys;
  final int girls;
  final int subjectCount;
  final List<PrincipalClassTeacher> teachers;
  final List<PrincipalClassSubject> subjects;
  final int sessionsToday;
  final int? attendancePercentage;

  const PrincipalClassSummary({
    required this.codeClasse,
    required this.name,
    required this.studentCount,
    required this.boys,
    required this.girls,
    required this.subjectCount,
    required this.teachers,
    required this.subjects,
    required this.sessionsToday,
    required this.attendancePercentage,
  });

  factory PrincipalClassSummary.fromJson(Map<String, dynamic> json) {
    final rawTeachers = json['enseignants'];
    final rawSubjects = json['matieres'];

    return PrincipalClassSummary(
      codeClasse: json['CodeClasse']?.toString() ?? '',
      name: json['LibelleClasse']?.toString() ?? '',
      studentCount: _toInt(json['effectif']),
      boys: _toInt(json['garcons']),
      girls: _toInt(json['filles']),
      subjectCount: _toInt(json['total_matieres']),
      teachers: rawTeachers is List
          ? rawTeachers
              .whereType<Map<String, dynamic>>()
              .map(PrincipalClassTeacher.fromJson)
              .toList()
          : <PrincipalClassTeacher>[],
      subjects: rawSubjects is List
          ? rawSubjects
              .whereType<Map<String, dynamic>>()
              .map(PrincipalClassSubject.fromJson)
              .toList()
          : <PrincipalClassSubject>[],
      sessionsToday: _toInt(json['seances_du_jour']),
      attendancePercentage: _toNullableInt(json['taux_presence']),
    );
  }
}

class PrincipalDashboardData {
  final int classes;
  final int teachers;
  final int students;
  final int? todayAttendancePercentage;
  final List<PrincipalDashboardClassOverview> classOverview;
  final List<PrincipalDashboardSession> todaySessions;

  const PrincipalDashboardData({
    required this.classes,
    required this.teachers,
    required this.students,
    required this.todayAttendancePercentage,
    this.classOverview = const [],
    required this.todaySessions,
  });

  factory PrincipalDashboardData.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['today_sessions'];
    final sessions = rawSessions is List
        ? rawSessions
            .whereType<Map<String, dynamic>>()
            .map(PrincipalDashboardSession.fromJson)
            .toList()
        : <PrincipalDashboardSession>[];

    return PrincipalDashboardData(
      classes: _toInt(json['classes']),
      teachers: _toInt(json['teachers']),
      students: _toInt(json['students']),
      todayAttendancePercentage:
          _toNullableInt(json['today_attendance_percentage']),
      classOverview: (json['class_overview'] as List<dynamic>? ?? [])
          .map((item) => PrincipalDashboardClassOverview.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
      todaySessions: sessions,
    );
  }
}

class PrincipalService {
  static const root = 'https://mobischo.com/api/school_manager';
  static const getDashboardAction = 'GET_PRINCIPAL_DASHBOARD';
  static const getClassesAction = 'GET_PRINCIPAL_CLASSES';
  static const getAttendanceAction = 'GET_PRINCIPAL_ATTENDANCE';

  static Future<List<PrincipalAttendanceData>> getPrincipalAttendance(
    User user, {
    String? date,
  }) async {
    final requestBody = <String, String>{
      'action': getAttendanceAction,
      'code': user.code,
      'CodeEtablissement': user.CodeEtablissement,
      if (date != null && date.isNotEmpty) 'DateEnreg': date,
    };
    final response = await http.post(Uri.parse(root), body: requestBody);

    if (response.statusCode != 200) {
      throw Exception(
          'Unable to load Principal attendance (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Invalid Principal attendance response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PrincipalAttendanceData.fromJson)
        .toList();
  }

  static Future<List<PrincipalClassSummary>> getClasses(User user) async {
    final response = await http.post(
      Uri.parse(root),
      body: {
        'action': getClassesAction,
        'code': user.code,
        'CodeEtablissement': user.CodeEtablissement,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to load Principal classes (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Invalid Principal classes response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PrincipalClassSummary.fromJson)
        .toList();
  }

  static Future<PrincipalDashboardData> getDashboard(User user) async {
    final requestBody = {
      'action': getDashboardAction,
      'code': user.code,
      'CodeEtablissement': user.CodeEtablissement,
    };

    print('[PrincipalDashboard] URL: $root');
    print('[PrincipalDashboard] request body: $requestBody');
    print('[PrincipalDashboard] user code: ${user.code}');
    print('[PrincipalDashboard] user CodeEtablissement: ${user.CodeEtablissement}');
    print('[PrincipalDashboard] user admin: ${user.admin}');

    try {
      final response = await http.post(
        Uri.parse(root),
        body: requestBody,
      );

      print('[PrincipalDashboard] HTTP status: ${response.statusCode}');
      print('[PrincipalDashboard] raw response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Unable to load Principal dashboard (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      print('[PrincipalDashboard] decoded response type: ${decoded.runtimeType}');

      if (decoded is! Map<String, dynamic>) {
        print('[PrincipalDashboard] unexpected response structure: $decoded');
        throw const FormatException('Invalid Principal dashboard response');
      }

      if (decoded['error'] != null) {
        print('[PrincipalDashboard] backend error field: ${decoded['error']}');
        throw Exception(decoded['error'].toString());
      }

      const requiredFields = [
        'classes',
        'teachers',
        'students',
        'today_attendance_percentage',
        'class_overview',
        'today_sessions',
      ];
      final missingFields = requiredFields
          .where((field) => !decoded.containsKey(field))
          .toList();
      if (missingFields.isNotEmpty) {
        print('[PrincipalDashboard] missing response fields: $missingFields');
      }
      print('[PrincipalDashboard] response keys: ${decoded.keys.toList()}');

      try {
        return PrincipalDashboardData.fromJson(decoded);
      } catch (error, stackTrace) {
        print('[PrincipalDashboard] parse error type: ${error.runtimeType}');
        print('[PrincipalDashboard] parse error message: $error');
        print('[PrincipalDashboard] response structure: $decoded');
        print('[PrincipalDashboard] parse stack: $stackTrace');
        rethrow;
      }
    } catch (error, stackTrace) {
      print('[PrincipalDashboard] exception type: ${error.runtimeType}');
      print('[PrincipalDashboard] exception message: $error');
      print('[PrincipalDashboard] exception stack: $stackTrace');
      rethrow;
    }
  }
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  return _toInt(value);
}

int? _toStrictInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
