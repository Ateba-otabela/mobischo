import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobischo/main.dart';

void main() {
  test('resolves French, English, and unsupported device languages', () {
    expect(resolveMobischoLocale(const Locale('fr', 'CA')), const Locale('fr'));
    expect(resolveMobischoLocale(const Locale('en', 'US')), const Locale('en'));
    expect(resolveMobischoLocale(const Locale('es')), const Locale('fr'));
    expect(resolveMobischoLocale(null), const Locale('fr'));
  });

}
