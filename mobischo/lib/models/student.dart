// ignore_for_file: non_constant_identifier_names

class Student{
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


  Student({
    required this.CodeEleve,
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
    required this.RESERVE4
  });


  factory Student.fromJson(Map<String, dynamic> json){
    return Student(
      CodeEleve: json['CodeEleve'] as String,
      CodeAnnee:  json['CodeAnnee'],
      CodeClasse:  json['CodeClasse'],
      code:  json['code'],
      CodeConduite:  json['CodeConduite'],
      Nom:  json['Nom'],
      Prenom:  json['Prenom'],
      DateNaissance:  json['DateNaissance'],
      LieuNaissance:  json['LieuNaissance'], 
      Sex:  json['Sex'],
      Nationalite:  json['Nationalite'],
      dateinscription:  json['dateinscription'],
      photo:  json['photo'],
      Excl:  json['Excl'],
      Nomp:  json['Nomp'],
      TelP:  json['TelP'],
      Image:  json['Image'],
      strimage:  json['strimage'],
      Nomm:  json['Nomm'],
      REGION:  json['REGION'],
      DEPART:  json['DEPART'],
      RELIGION:  json['RELIGION'],
      SITREG:  json['SITREG'],
      ACTIVEEPS:  json['ACTIVEEPS'],
      PROFP:  json['PROFP'],
      NOMT:  json['NOMT'],
      PROFM:  json['PROFM'],
      ADRESSE:  json['ADRESSE'],
      RESIDENT: json['RESIDENT'],
      TELM: json['TELM'],
      PERSONCON: json['PERSONCON'],
      TELT: json['TELT'],
      RESERVE1: json['RESERVE1'],
      RESERVE2: json['RESERVE2'],
      RESERVE3: json['RESERVE3'],
      RESERVE4: json['RESERVE4'],

      );
  }
}