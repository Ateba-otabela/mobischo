import 'package:flutter_test/flutter_test.dart';
import 'package:mobischo/services/principal_service.dart';

void main() {
  group('PrincipalDashboardSession', () {
    test('normalizes missing teacher and subject labels for today calls', () {
      final session = PrincipalDashboardSession.fromJson({
        'date': '2026-09-24',
        'time': '08:05',
        'class': '.',
        'CodeClasse': '6A',
        'subject': '',
        'CodeMatiere': 'MAH',
        'teacher': '.',
        'present': 7,
        'absent': 1,
        'late': 0,
        'student_count': 8,
        'attendance_percentage': 88,
      });

      expect(session.className, '6A');
      expect(session.subject, 'Mathématiques');
      expect(session.teacher, 'Enseignant');
    });
  });

  group('PrincipalAttendanceData', () {
    test('normalizes blank and dotted values to readable labels', () {
      final session = PrincipalAttendanceData.fromJson({
        'date': '2026-09-24',
        'time': '08:05',
        'CodeClasse': '6A',
        'CodeMatiere': 'MAH',
        'CodeEnseignement': 'ENS-1',
        'class': '6e A',
        'subject': '.',
        'teacher': '.',
        'present': 7,
        'absent': 1,
        'late': 0,
        'student_count': 8,
        'attendance_percentage': 88,
        'records': [
          {'CodeEleve': 'E-1', 'student_name': 'Aminata Diallo', 'status': 'P'},
          {'CodeEleve': 'E-2', 'student_name': 'Moussa Traore', 'status': 'A'},
        ],
      });

      expect(session.className, '6e A');
      expect(session.subject, 'Mathématiques');
      expect(session.teacher, 'Enseignant');
      expect(session.calculatedAttendancePercentage, 88);
    });

    test('preserves backend labels when they are populated', () {
      final session = PrincipalAttendanceData.fromJson({
        'date': '2026-09-24',
        'time': '08:05',
        'CodeClasse': '6A',
        'CodeMatiere': 'MAH',
        'CodeEnseignement': 'ENS-1',
        'class': '6e A',
        'subject': 'Mathématiques',
        'teacher': 'M. Kouame',
        'present': 6,
        'absent': 1,
        'late': 1,
        'student_count': 8,
        'attendance_percentage': 75,
        'records': [
          {'CodeEleve': 'E-1', 'student_name': 'Aminata Diallo', 'status': 'P'},
        ],
      });

      expect(session.subject, 'Mathématiques');
      expect(session.teacher, 'M. Kouame');
    });
  });
}
