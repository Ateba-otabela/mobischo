import 'package:mobischo/models/student.dart';

String getStudentDisplayName(Student student) {
  final dynamic rawNom = student.Nom;
  final dynamic rawPrenom = student.Prenom;
  final nom = rawNom is String ? rawNom.trim() : '';
  final prenom = rawPrenom is String ? rawPrenom.trim() : '';

  if (nom.isEmpty && prenom.isEmpty) {
    return 'Student';
  }
  if (nom.isEmpty) {
    return prenom;
  }
  if (prenom.isEmpty || nom.toLowerCase() == prenom.toLowerCase()) {
    return nom;
  }
  return '$nom $prenom';
}
