import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobischo/services/academic_services.dart';

void main() {
  group('AcademicServices.insertConvocations', () {
    test('sends the existing form contract without an attachment', () async {
      late http.Request request;
      final client = MockClient((incoming) async {
        request = incoming as http.Request;
        return http.Response(
          jsonEncode({'status': 'success'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await AcademicServices.insertConvocations(
        'TEACHER-1',
        ['STUDENT-1', 'STUDENT-2'],
        'Indiscipline',
        'Convocation description',
        'COURSE-1',
        '2026-10-10',
        codeClasse: 'CLASS-1',
        client: client,
      );

      final payload = Uri.splitQueryString(request.body);
      expect(request.method, 'POST');
      expect(request.url.path, '/api/school_manager');
      expect(request.headers['content-type'], contains('application/x-www-form-urlencoded'));
      expect(payload, {
        'action': 'INSERT_CONVOCATION',
        'code': 'TEACHER-1',
        'CodeEleves': jsonEncode(['STUDENT-1', 'STUDENT-2']),
        'CodeClasse': 'CLASS-1',
        'motif': 'Indiscipline',
        'description': 'Convocation description',
        'CodeEnseignement': 'COURSE-1',
        'dateConvocation': '2026-10-10',
      });
      expect(payload.containsKey('document'), isFalse);
      expect(jsonDecode(result), {'status': 'success'});

      client.close();
    });

    test('preserves safe validation messages and HTTP status', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'error': 'La date de convocation est invalide.'}),
            422,
            headers: {'content-type': 'application/json'},
          ));

      await expectLater(
        AcademicServices.insertConvocations(
          'TEACHER-1',
          ['STUDENT-1'],
          'Indiscipline',
          'Description',
          'COURSE-1',
          '10/10/2026',
          codeClasse: 'CLASS-1',
          client: client,
        ),
        throwsA(
          isA<ConvocationRequestException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having(
                (error) => error.safeMessage,
                'safeMessage',
                'La date de convocation est invalide.',
              ),
        ),
      );

      client.close();
    });
  });
}