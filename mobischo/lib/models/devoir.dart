// ignore_for_file: non_constant_identifier_names

class Devoir {
  int id;
  String titre;
  String description;
  String dateDuDevoir;
  String code;
  String CodeClasse;
  String CodeMatiere;
  String CodeEnseignement;
  String CodeEtablissement;
  String created_at;
  String updated_at;

  Devoir({
    required this.id,
    required this.titre,
    required this.description,
    required this.dateDuDevoir,
    required this.code,
    required this.CodeClasse,
    required this.CodeMatiere,
    required this.CodeEnseignement,
    required this.CodeEtablissement,
    required this.created_at,
    required this.updated_at,
  });

  factory Devoir.fromJson(Map<String, dynamic> json) {
    return Devoir(
      id: json['id'] as int,
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dateDuDevoir: json['dateDuDevoir'] as String? ?? '',
      code: json['code'] as String? ?? '',
      CodeClasse: json['CodeClasse'] as String? ?? '',
      CodeMatiere: json['CodeMatiere'] as String? ?? '',
      CodeEnseignement: json['CodeEnseignement'] as String? ?? '',
      CodeEtablissement: json['CodeEtablissement'] as String? ?? '',
      created_at: json['created_at'] as String? ?? '',
      updated_at: json['updated_at'] as String? ?? '',
    );
  }
}
