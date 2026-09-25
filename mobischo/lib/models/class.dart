// ignore_for_file: non_constant_identifier_names

class Classe {
  String LibelleClasse;
  String CodeClasse;
  String CodeTypeClasse;
  String CodeCycle;
  String CodeSpecialite;
  String codetypeinscrip;
  String CodeEtablissement;

  Classe(
      {required this.LibelleClasse,
      required this.CodeClasse,
      required this.CodeTypeClasse,
      required this.CodeCycle,
      required this.CodeSpecialite,
      required this.codetypeinscrip,
      required this.CodeEtablissement});

  factory Classe.fromJson(Map<String, dynamic> json) {
    return Classe(
        LibelleClasse: json['LibelleClasse']?.toString() ?? '',
        CodeClasse: json['CodeClasse']?.toString() ?? '',
        CodeTypeClasse: json['CodeTypeClasse']?.toString() ?? '',
        CodeCycle: json['CodeCycle']?.toString() ?? '',
        CodeSpecialite: json['CodeSpecialite']?.toString() ?? '',
        codetypeinscrip: json['codetypeinscrip']?.toString() ?? '',
        CodeEtablissement: json['CodeEtablissement']?.toString() ?? ''
        );
  }
}
