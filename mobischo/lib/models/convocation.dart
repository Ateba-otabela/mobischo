// ignore_for_file: non_constant_identifier_names

class Convocation {
  int id;
  String code;
  String CodeEleve;
  String motif;
  String description;
  String CodeEnseignement;
  String CodeMatiere;
  String dateConvocation;
  String created_at;
  String? teacherCode;
  String? teacherName;

  Convocation({
    required this.id,
    required this.code,
    required this.CodeEleve,
    required this.motif,
    required this.description,
    required this.CodeEnseignement,
    required this.dateConvocation,
    required this.CodeMatiere,
    required this.created_at,
    this.teacherCode,
    this.teacherName,
  });

  factory Convocation.fromJson(Map<String, dynamic> json) {
    return Convocation(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      CodeEleve: json['CodeEleve'] as String? ?? '',
      motif: json['motif'] as String? ?? '',
      description: json['description'] as String? ?? '',
      CodeEnseignement: json['CodeEnseignement'] as String? ?? '',
      dateConvocation: json['dateConvocation'] as String? ?? '',
      CodeMatiere: json['CodeMatiere'] as String? ?? '',
      created_at: json['created_at'] as String? ?? '',
      teacherCode: json['teacher_code']?.toString(),
      teacherName: json['teacher_name']?.toString(),
    );
  }
}
