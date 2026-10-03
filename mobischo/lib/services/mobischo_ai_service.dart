import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobischo/models/user.dart';

class MobischoAiServiceException implements Exception {
  final String userMessage;

  const MobischoAiServiceException(this.userMessage);
}

class MobischoAiService {
  static final Uri _chatEndpoint =
      Uri.parse('https://mobischo.com/api/ai/chat');
  static final Uri _conversationsEndpoint =
      Uri.parse('https://mobischo.com/api/ai/conversations');

  final http.Client _client;
  final bool _ownsClient;

  MobischoAiService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  void dispose() {
    if (_ownsClient) _client.close();
  }

  void _logRequest(User user, String method, Uri endpoint) {
    debugPrint(
      '[MobischoAI] role=${user.account_type}; '
      'admin=${user.admin}; '
      '$method ${endpoint.toString()}; '
      'aiTokenPresent=${user.aiToken.trim().isNotEmpty}',
    );
  }

  void _logResponse(User user, String endpoint, http.Response response) {
    debugPrint(
      '[MobischoAI] role=${user.account_type}; '
      'RESPONSE endpoint=$endpoint; status=${response.statusCode}; '
      'body=${_safeDiagnosticBody(response.body)}',
    );
  }

  String _safeDiagnosticBody(String body) {
    return body
        .replaceAll(
          RegExp(
            r'(["\x27]?(?:access[_-]?token|refresh[_-]?token|id[_-]?token|token|password(?:[_-]?confirmation)?|authorization|secret|api[_-]?key)["\x27]?\s*[:=]\s*["\x27]?)[^"\x27,\s}]+',
            caseSensitive: false,
          ),
          r'$1[REDACTED]',
        )
        .replaceAll(
          RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
          'Bearer [REDACTED]',
        );
  }

  void _logCaughtException(User user, String step, Object error) {
    debugPrint(
      '[MobischoAI] role=${user.account_type}; step=$step; '
      'caughtType=${error.runtimeType}; '
      'caughtMessage=${_safeDiagnosticBody(error.toString())}',
    );
  }

  Future<String> sendMessage({
    required User user,
    required String message,
    required List<Map<String, String>> conversation,
    String languageCode = 'fr',
    int? conversationId,
  }) async {
    final token = user.aiToken.trim();
    _logRequest(user, 'POST', _chatEndpoint);
    debugPrint('[MobischoAI] conversationTurns=${conversation.length}');
    if (token.isEmpty) {
      debugPrint(
        '[MobischoAI] role=${user.account_type}; '
        'stopped locally: ai_token missing',
      );
      throw const MobischoAiServiceException(
        'Votre session doit être renouvelée. Veuillez vous reconnecter.',
      );
    }

    try {
      final recentConversation = conversation.length <= 20
          ? conversation
          : conversation.sublist(conversation.length - 20);
      final languageInstruction = languageCode == 'en'
          ? 'Please respond in English, regardless of the language of the question.'
          : 'Réponds en français, quelle que soit la langue de la question.';
      final requestBody = <String, dynamic>{
        'message': '$message\n\n$languageInstruction',
        'conversation': recentConversation,
        if (conversationId != null) 'conversation_id': conversationId,
      };
      final response = await _client
          .post(
            _chatEndpoint,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 35));

      _logResponse(user, _chatEndpoint.toString(), response);
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint(
          '[MobischoAI] role=${user.account_type}; '
          'chat rejected with HTTP ${response.statusCode}',
        );
        throw const MobischoAiServiceException(
          'Votre session doit être renouvelée. Veuillez vous reconnecter.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[MobischoAI] role=${user.account_type}; '
          'chat rejected with HTTP ${response.statusCode}',
        );
        throw const MobischoAiServiceException(
          'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        debugPrint(
          '[MobischoAI] role=${user.account_type}; '
          'chat response parse failure; decodedType=${decoded.runtimeType}; '
          'success=${decoded is Map<String, dynamic> ? decoded['success'] : null}',
        );
        throw const MobischoAiServiceException(
          'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.',
        );
      }

      final answer = decoded['message'];
      if (answer is! String || answer.trim().isEmpty) {
        debugPrint(
          '[MobischoAI] role=${user.account_type}; '
          'chat response message invalid; messageType=${answer.runtimeType}',
        );
        throw const MobischoAiServiceException(
          'Je n’ai pas reçu de réponse. Veuillez réessayer.',
        );
      }
      return answer.trim();
    } on MobischoAiServiceException catch (error) {
      _logCaughtException(user, 'POST /api/ai/chat', error);
      rethrow;
    } on TimeoutException catch (error) {
      _logCaughtException(user, 'POST /api/ai/chat', error);
      debugPrint(
        '[MobischoAI] role=${user.account_type}; '
        'POST ${_chatEndpoint.toString()} timed out',
      );
      throw const MobischoAiServiceException(
        'La réponse prend trop de temps. Vérifiez votre connexion et réessayez.',
      );
    } catch (error) {
      _logCaughtException(user, 'POST /api/ai/chat', error);
      throw const MobischoAiServiceException(
        'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.',
      );
    }
  }

  Future<Map<String, dynamic>> fetchConversations(User user,
      {int page = 1}) async {
    final token = user.aiToken.trim();
    final endpoint =
        _conversationsEndpoint.replace(queryParameters: {'page': '$page'});
    debugPrint(
      '[MobischoAI] role=${user.account_type}; '
      'step=conversation history request; aiTokenPresent=${token.isNotEmpty}',
    );
    _logRequest(user, 'GET', endpoint);
    if (token.isEmpty) {
      debugPrint(
        '[MobischoAI] role=${user.account_type}; '
        'stopped locally: ai_token missing',
      );
      throw const MobischoAiServiceException(
        'Votre session doit être renouvelée. Veuillez vous reconnecter.',
      );
    }

    late final http.Response response;
    try {
      response = await _client.get(
        endpoint,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      _logResponse(user, endpoint.toString(), response);
    } catch (error) {
      _logCaughtException(user, 'GET conversation history', error);
      rethrow;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const MobischoAiServiceException(
        'Votre session doit être renouvelée. Veuillez vous reconnecter.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MobischoAiServiceException(
        'Impossible de charger vos conversations.',
      );
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (error) {
      _logCaughtException(user, 'parse conversation history response', error);
      rethrow;
    }
    if (decoded is! Map<String, dynamic>) {
      return const {
        'data': <Map<String, dynamic>>[],
        'page': 1,
        'has_more': false
      };
    }

    return decoded;
  }

  Future<Map<String, dynamic>> fetchConversation(
      User user, int conversationId) async {
    final token = user.aiToken.trim();
    final detailUri =
        Uri.parse('${_conversationsEndpoint.toString()}/$conversationId');
    debugPrint(
      '[MobischoAI] role=${user.account_type}; '
      'step=conversation detail request; aiTokenPresent=${token.isNotEmpty}',
    );
    _logRequest(user, 'GET', detailUri);
    final response = await _client.get(
      detailUri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _logResponse(user, detailUri.toString(), response);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const MobischoAiServiceException(
        'Votre session doit être renouvelée. Veuillez vous reconnecter.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MobischoAiServiceException(
        'Impossible d’ouvrir cette conversation.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const MobischoAiServiceException(
        'Impossible d’ouvrir cette conversation.',
      );
    }

    return decoded;
  }

  Future<Map<String, dynamic>> createConversation(User user,
      {String? title}) async {
    final token = user.aiToken.trim();
    debugPrint(
      '[MobischoAI] role=${user.account_type}; '
      'step=conversation setup request; aiTokenPresent=${token.isNotEmpty}',
    );
    _logRequest(user, 'POST', _conversationsEndpoint);
    late final http.Response response;
    try {
      response = await _client.post(
        _conversationsEndpoint,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if ((title ?? '').trim().isNotEmpty) 'title': title!.trim(),
        }),
      );
      _logResponse(user, _conversationsEndpoint.toString(), response);
    } catch (error) {
      _logCaughtException(user, 'POST conversation setup', error);
      rethrow;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const MobischoAiServiceException(
        'Votre session doit être renouvelée. Veuillez vous reconnecter.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MobischoAiServiceException(
        'Impossible de créer une conversation.',
      );
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (error) {
      _logCaughtException(user, 'parse conversation setup response', error);
      rethrow;
    }
    if (decoded is! Map<String, dynamic>) {
      throw const MobischoAiServiceException(
        'Impossible de créer une conversation.',
      );
    }

    return decoded;
  }

  Future<void> deleteConversation(User user, int conversationId) async {
    final token = user.aiToken.trim();
    final detailUri =
        Uri.parse('${_conversationsEndpoint.toString()}/$conversationId');
    _logRequest(user, 'DELETE', detailUri);
    final response = await _client.delete(
      detailUri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _logResponse(user, detailUri.toString(), response);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const MobischoAiServiceException(
        'Votre session doit être renouvelée. Veuillez vous reconnecter.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MobischoAiServiceException(
        'Impossible de supprimer cette conversation.',
      );
    }
  }
}
