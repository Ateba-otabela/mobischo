import 'package:flutter_test/flutter_test.dart';
import 'package:mobischo/utils/password_validation.dart';

void main() {
  group('validateStrongPassword', () {
    test('accepts a strong password', () {
      expect(
        validateStrongPassword('StrongPass1!Secure'),
        isNull,
      );
    });

    test('reports each missing requirement clearly', () {
      expect(
        validateStrongPassword('short'),
        'Password must be at least 12 characters; Password must contain an uppercase letter; Password must contain a number; Password must contain a special character',
      );

      expect(
        validateStrongPassword('ABCDEF12345678!'),
        'Password must contain a lowercase letter',
      );
    });

    test('rejects the default password', () {
      expect(
        validateStrongPassword('00000000'),
        'Password must be at least 12 characters; Password must contain an uppercase letter; Password must contain a lowercase letter; Password must contain a special character; Password cannot be 00000000',
      );
    });
  });
}
