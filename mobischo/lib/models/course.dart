// ignore_for_file: non_constant_identifier_names

class Course {
  String CodeEnseignement;
  String CodeMatiere;
  String code;
  String CodeClasse;
  String CodeEtablissement;
  String Coefficient;
  String CodeSpecialite;
  String CodeCycle;
  String Dateens;
  String CodeEnseignant2;
  String DateModif;
  String NBRHEURE;
  String RESERVE1;
  String RESERVE2;
  String RESERVE3;
  String RESERVE4;
  String RESERVE5;

  Course({
    required this.CodeEnseignement,
    required this.CodeMatiere,
    required this.code,
    required this.CodeClasse,
    required this.CodeEtablissement,
    required this.Coefficient,
    required this.CodeSpecialite,
    required this.CodeCycle,
    required this.Dateens,
    required this.CodeEnseignant2,
    required this.DateModif,
    required this.NBRHEURE,
    required this.RESERVE1,
    required this.RESERVE2,
    required this.RESERVE3,
    required this.RESERVE4,
    required this.RESERVE5,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
        CodeEnseignement: json['CodeEnseignement']?.toString() ?? '',
        CodeMatiere: json['CodeMatiere']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        CodeClasse: json['CodeClasse']?.toString() ?? '',
        CodeEtablissement: json['CodeEtablissement']?.toString() ?? '',
        Coefficient: json['Coefficient']?.toString() ?? '',
        CodeSpecialite: json['CodeSpecialite']?.toString() ?? '',
        CodeCycle: json['CodeCycle']?.toString() ?? '',
        Dateens: json['Dateens']?.toString() ?? '',
        CodeEnseignant2: json['CodeEnseignant2']?.toString() ?? '',
        DateModif: json['DateModif']?.toString() ?? '',
        NBRHEURE: json['NBRHEURE']?.toString() ?? '',
        RESERVE1: json['RESERVE1']?.toString() ?? '',
        RESERVE2: json['RESERVE2']?.toString() ?? '',
        RESERVE3: json['RESERVE3']?.toString() ?? '',
        RESERVE4: json['RESERVE4']?.toString() ?? '',
        RESERVE5: json['RESERVE5']?.toString() ?? '');
  }
}
