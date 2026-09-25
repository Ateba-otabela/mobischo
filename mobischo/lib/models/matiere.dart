// ignore_for_file: non_constant_identifier_names

class Matiere{
  String CodeMatiere;
  String LibelleMatiere;
  String ordre;
  String CodeEtablissement;

  Matiere({
    required this.CodeMatiere,
    required this.LibelleMatiere,
    required this.ordre,
    required this.CodeEtablissement
  });

  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      CodeMatiere: json['CodeMatiere'] as String,
      LibelleMatiere: json['LibelleMatiere'] as String,
      ordre: json['ordre'] as String,
      CodeEtablissement: json['CodeEtablissement'] as String
    );
}
}