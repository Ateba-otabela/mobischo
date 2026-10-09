String? validateStrongPassword(String password) {
  final failures = <String>[];

  if (password.length < 12) {
    failures.add('Password must be at least 12 characters');
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    failures.add('Password must contain an uppercase letter');
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    failures.add('Password must contain a lowercase letter');
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    failures.add('Password must contain a number');
  }
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
    failures.add('Password must contain a special character');
  }
  if (password.contains(RegExp(r'\s'))) {
    failures.add('Password cannot contain spaces');
  }
  if (password == '00000000') {
    failures.add('Password cannot be 00000000');
  }

  return failures.isEmpty ? null : failures.join('; ');
}
