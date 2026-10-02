import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/mobile_api_service.dart';

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
      className: _normalizeDisplayText(
        json['class'],
        fallback: _normalizeDisplayText(
          json['LibelleClasse'],
          fallback:
              _normalizeDisplayText(json['CodeClasse'], fallback: 'Classe'),
        ),
      ),
      subject: _normalizeDisplayText(
        json['subject'],
        fallback: _normalizeDisplayText(
          json['libelle_matiere'],
          fallback: _normalizeSubjectFallback(json['CodeMatiere']),
        ),
      ),
      teacher: _normalizeDisplayText(
        json['teacher'],
        fallback: _normalizeDisplayText(
          json['teacher_name'],
          fallback:
              _normalizeDisplayText(json['enseignant'], fallback: 'Enseignant'),
        ),
      ),
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
    final className = _normalizeDisplayText(
      json['class'],
      fallback: _normalizeDisplayText(
        json['LibelleClasse'],
        fallback: _normalizeDisplayText(json['CodeClasse'], fallback: 'Classe'),
      ),
    );
    final subject = _normalizeDisplayText(
      json['subject'],
      fallback: _normalizeDisplayText(
        json['libelle_matiere'],
        fallback: _normalizeSubjectFallback(json['CodeMatiere']),
      ),
    );
    final teacher = _normalizeDisplayText(
      json['teacher'],
      fallback: _normalizeDisplayText(
        json['teacher_name'],
        fallback:
            _normalizeDisplayText(json['enseignant'], fallback: 'Enseignant'),
      ),
    );

    return PrincipalAttendanceData(
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      codeClasse: json['CodeClasse']?.toString() ?? '',
      codeMatiere: json['CodeMatiere']?.toString() ?? '',
      codeEnseignement: json['CodeEnseignement']?.toString() ?? '',
      className: className,
      subject: subject,
      teacher: teacher,
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

String _normalizeDisplayText(Object? value, {String fallback = ''}) {
  final trimmed = value?.toString().trim();
  if (trimmed == null || trimmed.isEmpty) {
    return fallback;
  }

  final safeValue = trimmed.replaceAll(RegExp(r'^[.\s]+|[.\s]+$'), '');
  if (safeValue.isEmpty || safeValue == '.') {
    return fallback;
  }

  return safeValue;
}

String _normalizeSubjectFallback(Object? codeMatiere) {
  final code = codeMatiere?.toString().trim().toUpperCase() ?? '';
  if (code.isEmpty) return 'Matière';

  switch (code) {
    case 'MAH':
      return 'Mathématiques';
    case 'FR':
      return 'Français';
    case 'ANG':
      return 'Anglais';
    case 'SC':
      return 'Sciences';
    case 'INFO':
    case 'INFORMATIQUE':
      return 'Informatique';
    default:
      return code;
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

  factory PrincipalDashboardClassOverview.fromJson(Map<String, dynamic> json) {
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

class InvestigationAlertData {
  final int? id;
  final String eventType;
  final String codeEtablissement;
  final String codeEleve;
  final String codeClasse;
  final String codeEnseignement;
  final String codeMatiere;
  final String dateAbsence;
  final String parentStatus;
  final String teacherStatus;
  final String status;
  final String notes;
  final String studentName;
  final String studentCode;
  final String className;
  final String resolvedBy;
  final String resolvedAt;
  final String createdAt;

  const InvestigationAlertData({
    required this.id,
    required this.eventType,
    required this.codeEtablissement,
    required this.codeEleve,
    required this.codeClasse,
    required this.codeEnseignement,
    required this.codeMatiere,
    required this.dateAbsence,
    required this.parentStatus,
    required this.teacherStatus,
    required this.status,
    required this.notes,
    required this.studentName,
    required this.studentCode,
    required this.className,
    required this.resolvedBy,
    required this.resolvedAt,
    required this.createdAt,
  });

  factory InvestigationAlertData.fromJson(Map<String, dynamic> json) {
    return InvestigationAlertData(
      id: _toNullableInt(json['id']),
      eventType: json['event_type']?.toString() ?? 'investigation',
      codeEtablissement: json['CodeEtablissement']?.toString() ?? '',
      codeEleve: json['CodeEleve']?.toString() ?? '',
      codeClasse: json['CodeClasse']?.toString() ?? '',
      codeEnseignement: json['CodeEnseignement']?.toString() ?? '',
      codeMatiere: json['CodeMatiere']?.toString() ?? '',
      dateAbsence: json['date_absence']?.toString() ?? '',
      parentStatus: json['parent_status']?.toString() ?? '',
      teacherStatus: json['teacher_status']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      studentCode: json['student_code']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      resolvedBy: json['resolved_by']?.toString() ?? '',
      resolvedAt: json['resolved_at']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'validated':
        return 'Validée';
      case 'rejected':
        return 'Rejetée';
      default:
        return status;
    }
  }

  String get teacherStatusLabel {
    switch (teacherStatus.toUpperCase()) {
      case 'P':
        return 'Présent';
      case 'A':
        return 'Absent';
      case 'R':
        return 'Retard';
      default:
        return teacherStatus.isNotEmpty ? teacherStatus : 'Non renseigné';
    }
  }

  String get parentStatusLabel {
    switch (parentStatus.toUpperCase()) {
      case 'P':
        return 'Présent';
      case 'A':
        return 'Absent';
      case 'R':
        return 'Retard';
      default:
        return parentStatus.isNotEmpty ? parentStatus : 'Non renseigné';
    }
  }
}

class DashboardJustificationData {
  final int id;
  final String studentName;
  final String className;
  final String classCode;
  final String reason;
  final String absenceDate;
  final String status;
  final String explanation;
  final String createdAt;

  const DashboardJustificationData({
    required this.id,
    required this.studentName,
    required this.className,
    required this.classCode,
    required this.reason,
    required this.absenceDate,
    required this.status,
    required this.explanation,
    required this.createdAt,
  });

  factory DashboardJustificationData.fromJson(Map<String, dynamic> json) {
    return DashboardJustificationData(
      id: _toInt(json['id']),
      studentName: json['student_name']?.toString().trim() ?? '',
      className: json['class_name']?.toString().trim() ?? '',
      classCode: json['CodeClasse']?.toString().trim() ?? '',
      reason: json['reason']?.toString().trim() ?? '',
      absenceDate: (json['absence_date'] ?? json['date_absence'] ?? json['absence_date'])?.toString() ?? '',
      status: (json['status'] ?? json['statut'])?.toString().trim() ?? '',
      explanation: json['justification']?.toString().trim() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class DashboardJustificationPageData {
  final List<DashboardJustificationData> justifications;
  final int currentPage;
  final int lastPage;

  const DashboardJustificationPageData({
    required this.justifications,
    required this.currentPage,
    required this.lastPage,
  });

  factory DashboardJustificationPageData.fromJson(
    Map<String, dynamic> json,
  ) {
    final records = json['data'];
    if (records is! List) {
      throw const FormatException('Invalid dashboard justifications response');
    }

    return DashboardJustificationPageData(
      justifications: records
          .whereType<Map>()
          .map(
            (record) => DashboardJustificationData.fromJson(
              Map<String, dynamic>.from(record),
            ),
          )
          .toList(),
      currentPage: _toInt(json['current_page']),
      lastPage: _toInt(json['last_page']),
    );
  }
}

class PrincipalService {
  static const root = 'https://mobischo.com/api/school_manager';
  static final teacherClassesEndpoint =
      Uri.parse('https://mobischo.com/api/principal/teacher-classes');
  static const getDashboardAction = 'GET_PRINCIPAL_DASHBOARD';
  static const getClassesAction = 'GET_PRINCIPAL_CLASSES';
  static const getAttendanceAction = 'GET_PRINCIPAL_ATTENDANCE';

  static Future<DashboardJustificationPageData> getDashboardJustifications({
    int page = 1,
    int perPage = 3,
  }) async {
    final response = await MobileApiService.post(
      '/dashboard/alerts',
      headers: const {'Accept': 'application/json'},
      body: {
        'action': 'GET_DASHBOARD_JUSTIFICATIONS',
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Impossible de charger les justifications (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid dashboard justifications response');
    }

    return DashboardJustificationPageData.fromJson(decoded);
  }

  static Future<List<InvestigationAlertData>> getInvestigations(
    User user, {
    String? codeClasse,
  }) async {
    final response = await MobileApiService.post(
      '/dashboard/alerts',
      headers: const {'Accept': 'application/json'},
      body: {
        'action': 'GET_DASHBOARD_ALERTS',
        if (codeClasse != null && codeClasse.isNotEmpty)
          'CodeClasse': codeClasse,
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Impossible de charger les investigations (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Invalid investigations response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(InvestigationAlertData.fromJson)
        .toList();
  }

  static Future<InvestigationAlertData> updateInvestigationAlert(
    User user, {
    required String alertId,
    required String status,
    String? notes,
  }) async {
    final response = await MobileApiService.post(
      '/dashboard/alerts',
      headers: const {'Accept': 'application/json'},
      body: {
        'action': 'UPDATE_DASHBOARD_ALERT',
        'id': alertId,
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Impossible de mettre à jour l’investigation (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid investigation update response');
    }

    final alertJson = decoded['alert'];
    if (alertJson is Map<String, dynamic>) {
      return InvestigationAlertData.fromJson(alertJson);
    }

    throw const FormatException(
        'Investigation update response missing alert payload');
  }

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

    final sessionMaps = decoded.whereType<Map<String, dynamic>>().toList();
    for (final rawSession in sessionMaps) {
      final rawRecords = rawSession['records'];
      if (rawSession['class'] == 'PREMIERE A4-ESP2' &&
          rawSession['CodeEnseignement'] == '1059LIT' &&
          rawRecords is List &&
          rawRecords.length == 10) {
        print(
          '[PrincipalAttendance] RAW BEFORE fromJson: '
          '${jsonEncode(rawSession)}',
        );
      }
    }

    return sessionMaps.map(PrincipalAttendanceData.fromJson).toList();
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
      throw Exception(
          'Unable to load Principal classes (${response.statusCode})');
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

  static Future<List<PrincipalClassSummary>> getPrincipalTeacherClasses(
    User user,
  ) async {
    final token = user.aiToken.trim();
    if (token.isEmpty) {
      throw Exception(
          'Votre session doit être renouvelée. Veuillez vous reconnecter.');
    }

    final response = await http.get(
      teacherClassesEndpoint,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
          'Votre session doit être renouvelée. Veuillez vous reconnecter.');
    }
    if (response.statusCode != 200) {
      throw Exception(
          'Unable to load Principal teachers (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Invalid Principal teachers response');
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
    print(
        '[PrincipalDashboard] user CodeEtablissement: ${user.CodeEtablissement}');
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
      print(
          '[PrincipalDashboard] decoded response type: ${decoded.runtimeType}');

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
      final missingFields =
          requiredFields.where((field) => !decoded.containsKey(field)).toList();
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
