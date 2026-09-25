// ignore_for_file: non_constant_identifier_names

class SequenceEvaluation {
  int CodeEvaluation;
  String LibelleEvaluation;

  SequenceEvaluation(
      {required this.CodeEvaluation, required this.LibelleEvaluation});

  factory SequenceEvaluation.fromJson(Map<String, dynamic> json) {
    return SequenceEvaluation(
      CodeEvaluation: json['CodeEvaluation'] as int,
      LibelleEvaluation: json['LibelleEvaluation'] as String
      );
  }
}
