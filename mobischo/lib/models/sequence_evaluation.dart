// ignore_for_file: non_constant_identifier_names

class SequenceEvaluation {
  int CodeEvaluation;
  String LibelleEvaluation;
  bool hasMarks;

  SequenceEvaluation({
    required this.CodeEvaluation,
    required this.LibelleEvaluation,
    this.hasMarks = false,
  });

  factory SequenceEvaluation.fromJson(Map<String, dynamic> json) {
    final code = int.tryParse(json['CodeEvaluation']?.toString() ?? '');
    final label = json['LibelleEvaluation']?.toString() ?? '';
    final availability = json['hasMarks'] ?? json['has_marks'];
    if (code == null || label.trim().isEmpty) {
      throw const FormatException('Invalid sequence evaluation');
    }

    return SequenceEvaluation(
      CodeEvaluation: code,
      LibelleEvaluation: label,
      hasMarks: availability == true ||
          availability == 1 ||
          availability?.toString().toLowerCase() == 'true' ||
          availability?.toString() == '1',
    );
  }
}
