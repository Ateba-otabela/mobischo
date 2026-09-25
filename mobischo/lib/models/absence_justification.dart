class AbsenceJustification {
  final String id;
  final String studentCode;
  final String dateAbsence;
  final String motif;
  final String justification;
  final String pieceJointe;
  final String statut;
  final String dateEnvoi;

  AbsenceJustification({
    required this.id,
    required this.studentCode,
    required this.dateAbsence,
    required this.motif,
    required this.justification,
    required this.pieceJointe,
    required this.statut,
    required this.dateEnvoi,
  });

  factory AbsenceJustification.fromJson(Map<String, dynamic> json) {
    return AbsenceJustification(
      id: '${json['id'] ?? ''}',
      studentCode: '${json['CodeEleve'] ?? ''}',
      dateAbsence: '${json['date_absence'] ?? ''}',
      motif: '${json['motif'] ?? ''}',
      justification: '${json['justification'] ?? ''}',
      pieceJointe: '${json['piece_jointe'] ?? ''}',
      statut: '${json['statut'] ?? 'En attente'}',
      dateEnvoi: '${json['created_at'] ?? ''}',
    );
  }
}
