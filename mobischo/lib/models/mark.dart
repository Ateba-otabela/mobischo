// ignore_for_file: non_constant_identifier_names

class Mark {
  String Codeenseignement;
  String CodeEleve;
  String CodeEvaluation;
  String CodeAppreciation;
  String valeur;
  String coef;
  String total;
  String Dateeng;
  String codeannee;
  String CodeMatiere;
  String LibelleMatiere;

  Mark(
      {required this.Codeenseignement,
      required this.CodeEleve,
      required this.CodeEvaluation,
      required this.CodeAppreciation,
      required this.valeur,
      required this.coef,
      required this.total,
      required this.Dateeng,
      required this.codeannee,
      this.CodeMatiere = '',
      this.LibelleMatiere = ''});

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(
      Codeenseignement:
          (json['CodeEnseignement'] ?? json['Codeenseignement'])?.toString() ??
              '',
      CodeEleve: json['CodeEleve']?.toString() ?? '',
      CodeEvaluation: json['CodeEvaluation']?.toString() ?? '',
      CodeAppreciation: json['CodeAppreciation']?.toString() ?? '',
      valeur: json['valeur']?.toString() ?? '',
      coef: json['coef']?.toString() ?? '',
      total: (json['Total'] ?? json['total'])?.toString() ?? '',
      Dateeng: json['Dateeng']?.toString() ?? '',
      codeannee: (json['CodeAnnee'] ?? json['codeannee'])?.toString() ?? '',
      CodeMatiere: json['CodeMatiere']?.toString() ?? '',
      LibelleMatiere: json['LibelleMatiere']?.toString() ?? '',
    );
  }
}
