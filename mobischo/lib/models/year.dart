// ignore_for_file: non_constant_identifier_names

class Year {
  int CodeAnnee;
  String Libelle;

  Year({required this.CodeAnnee, required this.Libelle});

  factory Year.fromJson(Map<String, dynamic> json) {
    return Year(
      CodeAnnee: json['CodeAnnee'] as int,
      Libelle: json['Libelle'] as String
      );
  }
}
