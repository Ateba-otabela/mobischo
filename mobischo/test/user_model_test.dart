import 'package:flutter_test/flutter_test.dart';
import 'package:mobischo/models/user.dart';

void main() {
  test('parses a complete mobile login response', () {
    final user = User.fromJson({
      'nom': 'Nom',
      'prenom': 'Prenom',
      'contacts': '0600000000',
      'sex': 'M',
      'email': 'parent@example.com',
      'login': 'parent.demo',
      'code': 'parent-001',
      'account_type': 'parent',
      'address': 'Address',
      'admin': '0',
      'CodeEtablissement': 'school-a',
      'token': 'mobile-token',
      'ai_token': 'ai-token',
    });

    expect(user.login, 'parent.demo');
    expect(user.code, 'parent-001');
    expect(user.account_type, 'parent');
    expect(user.token, 'mobile-token');
    expect(user.aiToken, 'ai-token');
  });

  test('parses null optional AI token and omitted password safely', () {
    final user = User.fromJson({
      'nom': 'Nom',
      'prenom': 'Prenom',
      'contacts': null,
      'sex': null,
      'email': null,
      'login': 'parent.demo',
      'code': 'parent-001',
      'account_type': 'parent',
      'address': null,
      'admin': '0',
      'CodeEtablissement': null,
      'token': 'mobile-token',
      'ai_token': null,
    });

    expect(user.aiToken, isEmpty);
    expect(user.text_password, isEmpty);
    expect(user.contacts, isEmpty);
    expect(user.token, 'mobile-token');
  });

  test('rejects missing required identity fields', () {
    expect(
      () => User.fromJson({
        'login': 'parent.demo',
        'account_type': 'parent',
        'token': 'mobile-token',
      }),
      throwsFormatException,
    );
  });
}