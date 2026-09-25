class PrincipalStudent {
  final String name;
  final String code;
  final String className;
  final bool boy;
  final String photo;
  final int present;
  final int absent;
  final int late;

  const PrincipalStudent({
    required this.name,
    required this.code,
    required this.className,
    required this.boy,
    required this.photo,
    required this.present,
    required this.absent,
    required this.late,
  });

  int get total => present + absent + late;
  double get attendance => total == 0 ? 0 : present / total;
}

class PrincipalClass {
  final String name;
  final List<PrincipalStudent> students;

  const PrincipalClass(this.name, this.students);

  int get boys => students.where((student) => student.boy).length;
  int get girls => students.length - boys;
  int get present => students.fold(0, (sum, student) => sum + student.present);
  int get absent => students.fold(0, (sum, student) => sum + student.absent);
  int get late => students.fold(0, (sum, student) => sum + student.late);
  double get attendance => students.isEmpty ? 0 : present / (present + absent + late);
}

class PrincipalAttendance {
  final PrincipalStudent student;
  final String date;
  final String subject;
  final String teacher;
  final String time;
  final String status;

  const PrincipalAttendance({
    required this.student,
    required this.date,
    required this.subject,
    required this.teacher,
    required this.time,
    required this.status,
  });
}

class PrincipalAttendanceSession {
  final String date;
  final String time;
  final PrincipalClass schoolClass;
  final String subject;
  final String teacher;
  final List<PrincipalAttendance> records;

  const PrincipalAttendanceSession({
    required this.date,
    required this.time,
    required this.schoolClass,
    required this.subject,
    required this.teacher,
    required this.records,
  });

  int get present => records.where((record) => record.status == 'Présent').length;
  int get absent => records.where((record) => record.status == 'Absent').length;
  int get late => records.where((record) => record.status == 'Retard').length;
  int get total => records.length;
  double? get attendance => total == 0 ? null : present / total;
}

class ParentReport {
  final PrincipalStudent student;
  final String parent;
  final String date;
  final String reason;
  final String message;
  String status;

  ParentReport({
    required this.student,
    required this.parent,
    required this.date,
    required this.reason,
    required this.message,
    required this.status,
  });
}

class TeacherCall {
  final String date;
  final String time;
  final PrincipalClass schoolClass;
  final String teacher;
  final String subject;
  final String status;

  const TeacherCall({
    required this.date,
    required this.time,
    required this.schoolClass,
    required this.teacher,
    required this.subject,
    required this.status,
  });
}

class PrincipalMockService {
  static const credentials = <String, String>{
    'login': 'principal.demo',
    'password': 'mobischo2026',
  };

  static bool isValidCredentials(String login, String password) =>
      login.trim() == credentials['login'] && password == credentials['password'];

  static final classes = <PrincipalClass>[
    PrincipalClass('6e A', [
      PrincipalStudent(name: 'Aminata Diallo', code: 'ELV-0601', className: '6e A', boy: false, photo: 'assets/images/avatar-s-19.jpg', present: 18, absent: 1, late: 1),
      PrincipalStudent(name: 'Moussa Traore', code: 'ELV-0602', className: '6e A', boy: true, photo: 'assets/images/avatar-s-19.jpg', present: 17, absent: 2, late: 1),
      PrincipalStudent(name: 'Claire Nguessan', code: 'ELV-0603', className: '6e A', boy: false, photo: 'assets/images/avatar-s-19.jpg', present: 19, absent: 0, late: 1),
    ]),
    PrincipalClass('5e B', [
      PrincipalStudent(name: 'Jean Kouassi', code: 'ELV-0501', className: '5e B', boy: true, photo: 'assets/images/avatar-s-19.jpg', present: 16, absent: 2, late: 2),
      PrincipalStudent(name: 'Fatou Kone', code: 'ELV-0502', className: '5e B', boy: false, photo: 'assets/images/avatar-s-19.jpg', present: 18, absent: 1, late: 1),
      PrincipalStudent(name: 'Nadia Yao', code: 'ELV-0503', className: '5e B', boy: false, photo: 'assets/images/avatar-s-19.jpg', present: 20, absent: 0, late: 0),
    ]),
    PrincipalClass('4e C', [
      PrincipalStudent(name: 'Paul Niamke', code: 'ELV-0401', className: '4e C', boy: true, photo: 'assets/images/avatar-s-19.jpg', present: 15, absent: 3, late: 2),
      PrincipalStudent(name: 'Sarah Bamba', code: 'ELV-0402', className: '4e C', boy: false, photo: 'assets/images/avatar-s-19.jpg', present: 17, absent: 1, late: 2),
    ]),
  ];

  static final reports = <ParentReport>[
    ParentReport(student: classes[0].students[0], parent: 'Mme Diallo', date: '24/09/2026', reason: 'Maladie', message: 'Aminata sera absente ce matin.', status: 'Signalée'),
    ParentReport(student: classes[1].students[1], parent: 'M. Kone', date: '23/09/2026', reason: 'Rendez-vous médical', message: 'Retour prévu après le rendez-vous.', status: 'Vue'),
  ];

  static final calls = <TeacherCall>[
    TeacherCall(date: '24/09/2026', time: '08:05', schoolClass: classes[0], teacher: 'M. Kouame', subject: 'Mathématiques', status: 'Appel effectué'),
    TeacherCall(date: '24/09/2026', time: '10:00', schoolClass: classes[0], teacher: 'Mme Yao', subject: 'Français', status: 'Appel effectué'),
    TeacherCall(date: '24/09/2026', time: '13:00', schoolClass: classes[0], teacher: 'M. Kouame', subject: 'Informatique', status: 'Appel effectué'),
    TeacherCall(date: '24/09/2026', time: '08:12', schoolClass: classes[1], teacher: 'Mme Yao', subject: 'Français', status: 'Appel effectué'),
    TeacherCall(date: '23/09/2026', time: '10:00', schoolClass: classes[2], teacher: 'M. Koffi', subject: 'Sciences', status: 'Appel effectué'),
  ];

  static List<PrincipalAttendance> get attendance {
    final result = <PrincipalAttendance>[];
    final sessions = <Map<String, String>>[
      {'class': '6e A', 'subject': 'Mathématiques', 'teacher': 'M. Kouame', 'time': '08:05'},
      {'class': '6e A', 'subject': 'Français', 'teacher': 'Mme Yao', 'time': '10:00'},
      {'class': '6e A', 'subject': 'Informatique', 'teacher': 'M. Kouame', 'time': '13:00'},
      {'class': '5e B', 'subject': 'Français', 'teacher': 'Mme Yao', 'time': '08:12'},
      {'class': '4e C', 'subject': 'Sciences', 'teacher': 'M. Koffi', 'time': '10:00'},
    ];

    for (final session in sessions) {
      final schoolClass = classes.firstWhere((item) => item.name == session['class']);
      for (var index = 0; index < schoolClass.students.length; index++) {
        final student = schoolClass.students[index];
        final status = index % 3 == 1
            ? 'Absent'
            : index % 3 == 2
                ? 'Retard'
                : 'Présent';
        result.add(PrincipalAttendance(
          student: student,
          date: '24/09/2026',
          subject: session['subject']!,
          teacher: session['teacher']!,
          time: session['time']!,
          status: status,
        ));
      }
    }
    return result;
  }

  static List<PrincipalAttendanceSession> get attendanceSessions {
    final grouped = <String, List<PrincipalAttendance>>{};
    for (final record in attendance) {
      final key =
          '${record.date}|${record.student.className}|${record.subject}|${record.teacher}|${record.time}';
      grouped.putIfAbsent(key, () => []).add(record);
    }

    return grouped.entries.map((entry) {
      final records = entry.value;
      final first = records.first;
      final schoolClass = classes.firstWhere(
        (item) => item.name == first.student.className,
      );
      return PrincipalAttendanceSession(
        date: first.date,
        time: first.time,
        schoolClass: schoolClass,
        subject: first.subject,
        teacher: first.teacher,
        records: records,
      );
    }).toList();
  }
}
