// ignore_for_file: non_constant_identifier_names

class Inscription {
  String NUMFAC;
  String CodeInscription;
  String CodeEleve;
  String DateInscription;
  String Tranche;
  String codeannee;
  String Montantins;
  String Avance;
  String Reste;
  String Montantt;
  String libinscrip;
  String heure;
  String caissie;
  String remise;

  Inscription(
      {required this.NUMFAC,
      required this.CodeInscription,
      required this.CodeEleve,
      required this.DateInscription,
      required this.Tranche,
      required this.codeannee,
      required this.Montantins,
      required this.Avance,
      required this.Reste,
      required this.Montantt,
      required this.libinscrip,
      required this.heure,
      required this.caissie,
      required this.remise});

  factory Inscription.fromJson(Map<String, dynamic> json) {
    return Inscription(
      NUMFAC: (json['NUMFAC'] ?? '').toString(),
      CodeInscription: (json['CodeInscription'] ?? '').toString(),
      CodeEleve: (json['CodeEleve'] ?? '').toString(),
      DateInscription: (json['DateInscription'] ?? '').toString(),
      Tranche: (json['Tranche'] ?? '').toString(),
      codeannee: (json['codeannee'] ?? json['CodeAnnee'] ?? '').toString(),
      Montantins: (json['Montantins'] ?? '').toString(),
      Avance: (json['Avance'] ?? '').toString(),
      Reste: (json['Reste'] ?? '').toString(),
      Montantt: (json['Montantt'] ?? '').toString(),
      libinscrip: (json['libinscrip'] ?? '').toString(),
      heure: (json['heure'] ?? '').toString(),
      caissie: (json['caissie'] ?? json['caissier'] ?? '').toString(),
      remise: (json['remise'] ?? '').toString(),
    );
  }
}
