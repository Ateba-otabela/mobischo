import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobischo/components/screens/mobischo_ai.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/mobischo_ai_service.dart';

User _testUser() => User(
      nom: 'Principal',
      prenom: 'Test',
      contacts: '',
      sex: '',
      email: '',
      login: 'principal-test',
      code: 'principal-test',
      account_type: 'principal_encadreur',
      text_password: '',
      address: '',
      admin: '1',
      CodeEtablissement: 'school-test',
      aiToken: 'test-session-token',
    );

void main() {
  test('posts bearer auth and recent conversation, then parses the reply', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/ai/chat');
      expect(request.headers['authorization'], 'Bearer test-session-token');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['message'], 'Question suivante');
      final conversation = body['conversation'] as List<dynamic>;
      expect(conversation, hasLength(20));
      expect(conversation.first['text'], 'turn-2');
      expect(conversation.last['text'], 'turn-21');
      return http.Response(
        jsonEncode({'success': true, 'message': 'Réponse réelle du service'}),
        200,
      );
    });
    final service = MobischoAiService(client: client);

    final reply = await service.sendMessage(
      user: _testUser(),
      message: 'Question suivante',
      conversation: List.generate(
        21,
        (index) => {'role': 'user', 'text': 'turn-${index + 1}'},
      ),
    );

    expect(reply, 'Réponse réelle du service');
    client.close();
  });

  test('converts HTTP failures to a friendly message', () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({'error': 'private upstream detail'}),
          502,
        ));
    final service = MobischoAiService(client: client);

    await expectLater(
      service.sendMessage(
        user: _testUser(),
        message: 'Bonjour',
        conversation: const [],
      ),
      throwsA(
        isA<MobischoAiServiceException>().having(
          (error) => error.userMessage,
          'userMessage',
          contains('Veuillez réessayer'),
        ),
      ),
    );
    client.close();
  });

  testWidgets('shows a sent message and typing state before the AI reply',
      (tester) async {
    final responseCompleter = Completer<http.Response>();
    final requestCompleter = Completer<Map<String, dynamic>>();
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path.endsWith('/conversations')) {
        return http.Response(
          jsonEncode({'data': [], 'page': 1, 'has_more': false}),
          200,
        );
      }
      if (request.method == 'POST' && request.url.path.endsWith('/conversations')) {
        return http.Response(
          jsonEncode({'id': 7, 'title': 'Nouvelle conversation'}),
          201,
        );
      }
      requestCompleter.complete(jsonDecode(request.body) as Map<String, dynamic>);
      return responseCompleter.future;
    });
    final service = MobischoAiService(client: client);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MobischoAiScreen(user: _testUser(), aiService: service),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bonjour 👋 Je suis Mobischo AI.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Question de test');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(find.text('Question de test'), findsOneWidget);
    expect(find.text('Mobischo AI écrit…'), findsOneWidget);
    final requestBody = await requestCompleter.future;
    expect(requestBody['message'], 'Question de test');

    responseCompleter.complete(http.Response(
      jsonEncode({'success': true, 'message': 'Réponse IA de test'}),
      200,
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Réponse IA de test'), findsOneWidget);
    expect(find.text('Mobischo AI écrit…'), findsNothing);
    client.close();
  });

  testWidgets('loads a saved conversation when the AI screen opens',
      (tester) async {
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path.endsWith('/conversations')) {
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 41, 'title': 'Présence de la semaine', 'updated_at': '2026-09-27T10:00:00Z'}
            ],
            'page': 1,
            'has_more': false,
          }),
          200,
        );
      }
      expect(request.url.path, '/api/ai/conversations/41');
      return http.Response(
        jsonEncode({
          'id': 41,
          'title': 'Présence de la semaine',
          'messages': [
            {
              'id': 1,
              'role': 'user',
              'content': 'Résume les présences.',
              'created_at': '2026-09-27T09:00:00Z',
            },
            {
              'id': 2,
              'role': 'assistant',
              'content': '**Résumé** des présences.',
              'created_at': '2026-09-27T09:00:10Z',
            },
          ],
        }),
        200,
      );
    });
    final service = MobischoAiService(client: client);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MobischoAiScreen(user: _testUser(), aiService: service),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Résume les présences.'), findsOneWidget);
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(
      tester.widget<MarkdownBody>(find.byType(MarkdownBody)).onTapLink,
      isNotNull,
    );
    expect(find.text('Copier'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    await tester.tap(find.text('Copier'));
    await tester.pump();
    expect(find.text('Copied'), findsOneWidget);
    client.close();
  });
}