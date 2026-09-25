// ignore_for_file: non_constant_identifier_names

class Conduite {
  String CodeConduite;
  String DateEnreg;
  String CodeEleve;
  String Nombre;
  String CodeEtatCond;
  String CodeClasse;
  String CodeAnnee;
  String CodeMatiere;
  String HeureMatiere;
  String created_at;

  Conduite(
      {required this.CodeConduite,
      required this.DateEnreg,
      required this.CodeEleve,
      required this.Nombre,
      required this.CodeEtatCond,
      required this.CodeClasse,
      required this.CodeAnnee,
      required this.CodeMatiere,
      required this.HeureMatiere,
      required this.created_at});

  factory Conduite.fromJson(Map<String, dynamic> json) {
    return Conduite(
        CodeConduite: json['id']?.toString() ?? '',
        DateEnreg: json['DateEnreg']?.toString() ?? '',
        CodeEleve: json['CodeEleve']?.toString() ?? '',
        Nombre: json['Nombre']?.toString() ?? '',
        CodeEtatCond: json['CodeEtatCond']?.toString() ?? '',
        CodeClasse: json['CodeClasse']?.toString() ?? '',
        CodeAnnee: json['CodeAnnee']?.toString() ?? '',
        CodeMatiere: json['CodeMatiere']?.toString() ?? '',
        HeureMatiere: json['HeureMatiere']?.toString() ?? '',
        created_at: json['created_at']?.toString() ?? '');
  }
}
