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

  Future<String> sendMessage({
    required User user,
    required String message,
    required List<Map<String, String>> conversation,
    int? conversationId,
  }) async {
    final token = user.aiToken.trim();
    debugPrint(
      '[MobischoAI] POST ${_chatEndpoint.host}${_chatEndpoint.path}; '
      'sessionTokenPresent=${token.isNotEmpty}; '
      'conversationTurns=${conversation.length}',
    );
    if (token.isEmpty) {
      debugPrint('[MobischoAI] stopped locally: session token missing');
      throw const MobischoAiServiceException(
        'Votre session doit être renouvelée. Veuillez vous reconnecter.',
      );
    }

    try {
      final recentConversation = conversation.length <= 20
          ? conversation
          : conversation.sublist(conversation.length - 20);
      final response = await _client
          .post(
            _chatEndpoint,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'message': message,
              'conversation': recentConversation,
              if (conversationId != null) 'conversation_id': conversationId,
            }),
          )
          .timeout(const Duration(seconds: 35));

          debugPrint('[MobischoAI] Laravel HTTP status=${response.statusCode}');
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const MobischoAiServiceException(
          'Votre session doit être renouvelée. Veuillez vous reconnecter.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const MobischoAiServiceException(
          'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw const MobischoAiServiceException(
          'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.',
        );
      }

      final answer = decoded['message'];
      if (answer is! String || answer.trim().isEmpty) {
        throw const MobischoAiServiceException(
          'Je n’ai pas reçu de réponse. Veuillez réessayer.',
        );
      }
      return answer.trim();
    } on MobischoAiServiceException {
      rethrow;
    } on TimeoutException {
      debugPrint('[MobischoAI] request timed out');
      throw const MobischoAiServiceException(
        'La réponse prend trop de temps. Vérifiez votre connexion et réessayez.',
      );
    } catch (_) {
      debugPrint('[MobischoAI] request failed: network or response parsing');
      throw const MobischoAiServiceException(
        'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.',
      );
    }
  }

  Future<Map<String, dynamic>> fetchConversations(User user, {int page = 1}) async {
    final token = user.aiToken.trim();
    if (token.isEmpty) {
      throw const MobischoAiServiceException(
        'Votre session doit être renouvelée. Veuillez vous reconnecter.',
      );
    }

    final response = await _client.get(
      _conversationsEndpoint.replace(queryParameters: {'page': '$page'}),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

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

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const {'data': <Map<String, dynamic>>[], 'page': 1, 'has_more': false};
    }

    return decoded;
  }

  Future<Map<String, dynamic>> fetchConversation(User user, int conversationId) async {
    final token = user.aiToken.trim();
    final detailUri = Uri.parse('${_conversationsEndpoint.toString()}/$conversationId');
    final response = await _client.get(
      detailUri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

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

  Future<Map<String, dynamic>> createConversation(User user, {String? title}) async {
    final token = user.aiToken.trim();
    final response = await _client.post(
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

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const MobischoAiServiceException(
        'Impossible de créer une conversation.',
      );
    }

    return decoded;
  }

  Future<void> deleteConversation(User user, int conversationId) async {
    final token = user.aiToken.trim();
    final detailUri = Uri.parse('${_conversationsEndpoint.toString()}/$conversationId');
    final response = await _client.delete(
      detailUri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

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