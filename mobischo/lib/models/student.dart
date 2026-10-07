// ignore_for_file: non_constant_identifier_names

String _studentField(Map<String, dynamic> json, String key) =>
    json[key]?.toString() ?? '';

class Student {
  String CodeEleve;
  String CodeAnnee;
  String CodeClasse;
  String code;
  String CodeConduite;
  String Nom;
  String Prenom;
  String DateNaissance;
  String LieuNaissance;
  String Sex;
  String Nationalite;
  String dateinscription;
  String photo;
  String Excl;
  String Nomp;
  String TelP;
  String Image;
  String strimage;
  String Nomm;
  String REGION;
  String DEPART;
  String RELIGION;
  String SITREG;
  String ACTIVEEPS;
  String PROFP;
  String NOMT;
  String PROFM;
  String ADRESSE;
  String RESIDENT;
  String TELM;
  String TELT;
  String PERSONCON;
  String RESERVE1;
  String RESERVE2;
  String RESERVE3;
  String RESERVE4;

  Student(
      {required this.CodeEleve,
      required this.CodeAnnee,
      required this.CodeClasse,
      required this.code,
      required this.CodeConduite,
      required this.Nom,
      required this.Prenom,
      required this.DateNaissance,
      required this.LieuNaissance,
      required this.Sex,
      required this.Nationalite,
      required this.dateinscription,
      required this.photo,
      required this.Excl,
      required this.Nomp,
      required this.TelP,
      required this.Image,
      required this.strimage,
      required this.Nomm,
      required this.REGION,
      required this.DEPART,
      required this.RELIGION,
      required this.SITREG,
      required this.ACTIVEEPS,
      required this.PROFP,
      required this.NOMT,
      required this.PROFM,
      required this.ADRESSE,
      required this.RESIDENT,
      required this.TELM,
      required this.TELT,
      required this.PERSONCON,
      required this.RESERVE1,
      required this.RESERVE2,
      required this.RESERVE3,
      required this.RESERVE4});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      CodeEleve: _studentField(json, 'CodeEleve'),
      CodeAnnee: _studentField(json, 'CodeAnnee'),
      CodeClasse: _studentField(json, 'CodeClasse'),
      code: _studentField(json, 'code'),
      CodeConduite: _studentField(json, 'CodeConduite'),
      Nom: _studentField(json, 'Nom'),
      Prenom: _studentField(json, 'Prenom'),
      DateNaissance: _studentField(json, 'DateNaissance'),
      LieuNaissance: _studentField(json, 'LieuNaissance'),
      Sex: _studentField(json, 'Sex'),
      Nationalite: _studentField(json, 'Nationalite'),
      dateinscription: _studentField(json, 'dateinscription'),
      photo: _studentField(json, 'photo'),
      Excl: _studentField(json, 'Excl'),
      Nomp: _studentField(json, 'Nomp'),
      TelP: _studentField(json, 'TelP'),
      Image: _studentField(json, 'Image'),
      strimage: _studentField(json, 'strimage'),
      Nomm: _studentField(json, 'Nomm'),
      REGION: _studentField(json, 'REGION'),
      DEPART: _studentField(json, 'DEPART'),
      RELIGION: _studentField(json, 'RELIGION'),
      SITREG: _studentField(json, 'SITREG'),
      ACTIVEEPS: _studentField(json, 'ACTIVEEPS'),
      PROFP: _studentField(json, 'PROFP'),
      NOMT: _studentField(json, 'NOMT'),
      PROFM: _studentField(json, 'PROFM'),
      ADRESSE: _studentField(json, 'ADRESSE'),
      RESIDENT: _studentField(json, 'RESIDENT'),
      TELM: _studentField(json, 'TELM'),
      PERSONCON: _studentField(json, 'PERSONCON'),
      TELT: _studentField(json, 'TELT'),
      RESERVE1: _studentField(json, 'RESERVE1'),
      RESERVE2: _studentField(json, 'RESERVE2'),
      RESERVE3: _studentField(json, 'RESERVE3'),
      RESERVE4: _studentField(json, 'RESERVE4'),
    );
  }
}
