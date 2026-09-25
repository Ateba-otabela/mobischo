// ignore_for_file: non_constant_identifier_names

class School {
  String CodeEtablissement;
  String Pays;
  String Nom;
  String Adresse;
  String Tel;
  String Fax;
  String REPPHOTO;

  School(
      {required this.CodeEtablissement,
      required this.Pays,
      required this.Nom,
      required this.Adresse,
      required this.Tel,
      required this.Fax,
      required this.REPPHOTO});

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
        CodeEtablissement: json['CodeEtablissement'] as String,
        Pays: json['Pays'] as String,
        Nom: json['Nom'] as String,
        Adresse: json['Adresse'] as String,
        Tel: json['Tel'] as String,
        Fax: json['Fax'] as String,
        REPPHOTO: json['REPPHOTO'] as String
        );
  }
}
