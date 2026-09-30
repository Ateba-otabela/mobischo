import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobischo/models/absence_justification.dart';

class AbsenceJustificationServiceException implements Exception {
  final String userMessage;

  const AbsenceJustificationServiceException(this.userMessage);
}

class AbsenceJustificationService {
  static const String root = 'https://mobischo.com/api/school_manager';

  static Future<List<AbsenceJustification>> getParentJustifications(
      String parentCode) async {
    try {
      final response = await http.post(Uri.parse(root), body: {
        'action': 'GET_PARENT_ABSENCE_JUSTIFICATIONS',
        'code': parentCode,
      });
      if (response.statusCode != 200) {
        throw _responseException(response, 'Impossible de charger les justificatifs.');
      }

      final data = json.decode(response.body);
      if (data is! List) {
        throw const AbsenceJustificationServiceException(
          'La réponse des justificatifs est invalide.',
        );
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(AbsenceJustification.fromJson)
          .toList();
    } on AbsenceJustificationServiceException {
      rethrow;
    } catch (_) {
      throw const AbsenceJustificationServiceException(
        'Impossible de joindre le serveur pour charger les justificatifs.',
      );
    }
  }

  static Future<void> submit({
    required String parentCode,
    required String studentCode,
    required String absenceDate,
    required String motif,
    required String justification,
    String? attachment,
  }) async {
    try {
      final response = await http.post(Uri.parse(root), body: {
        'action': 'SUBMIT_ABSENCE_JUSTIFICATION',
        'code': parentCode,
        'CodeEleve': studentCode,
        'date_absence': absenceDate,
        'motif': motif,
        'justification': justification,
        'piece_jointe': attachment ?? '',
      });

      if (response.statusCode != 200) {
        throw _responseException(response, 'La justification n’a pas pu être envoyée.');
      }

      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> &&
          decoded['status'] == 'success' &&
          decoded['id'] != null) {
        return;
      }

      if (decoded is Map<String, dynamic>) {
        throw AbsenceJustificationServiceException(
          _messageFromPayload(decoded, 'La justification n’a pas été enregistrée.'),
        );
      }

      throw const AbsenceJustificationServiceException(
        'La réponse du serveur ne confirme pas l’enregistrement.',
      );
    } on AbsenceJustificationServiceException {
      rethrow;
    } catch (_) {
      throw const AbsenceJustificationServiceException(
        'Impossible de joindre le serveur. Vérifiez votre connexion puis réessayez.',
      );
    }
  }

  static AbsenceJustificationServiceException _responseException(
    http.Response response,
    String fallback,
  ) {
    if (response.statusCode == 403) {
      return const AbsenceJustificationServiceException(
        'Cet enfant n’est pas associé à votre compte parent.',
      );
    }

    if (response.statusCode == 422) {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return AbsenceJustificationServiceException(
            _messageFromPayload(decoded, 'Vérifiez la date et les champs obligatoires.'),
          );
        }
      } catch (_) {
        return const AbsenceJustificationServiceException(
          'Vérifiez la date et les champs obligatoires.',
        );
      }
      return const AbsenceJustificationServiceException(
        'Vérifiez la date et les champs obligatoires.',
      );
    }

    if (response.statusCode >= 500) {
      return const AbsenceJustificationServiceException(
        'Le serveur ne peut pas enregistrer la justification pour le moment.',
      );
    }

    return AbsenceJustificationServiceException(fallback);
  }

  static String _messageFromPayload(Map<String, dynamic> payload, String fallback) {
    final error = payload['error']?.toString().trim();
    if (error != null && error.isNotEmpty) return error;

    final message = payload['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    final errors = payload['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final firstMessage = value.first?.toString().trim();
          if (firstMessage != null && firstMessage.isNotEmpty) return firstMessage;
        }
      }
    }

    return fallback;
  }
}
