// ignore_for_file: non_constant_identifier_names

import 'dart:core';

class User {
  String nom;
  String prenom;
  String contacts;
  String sex;
  String email;
  String login;
  String code;
  String account_type;
  String text_password;
  String address;
  String admin;
  String CodeEtablissement;
  String aiToken;
  String token;

  User(
      {required this.nom,
      required this.prenom,
      required this.contacts,
      required this.sex,
      required this.email,
      required this.login,
      required this.code,
      required this.account_type,
      required this.text_password,
      required this.address,
      required this.admin,
      required this.CodeEtablissement,
      this.aiToken = '',
      this.token = ''});

  factory User.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing or invalid required user field: $key');
      }
      return value;
    }

    String optionalString(String key, [String fallback = '']) {
      final value = json[key];
      return value == null ? fallback : value.toString();
    }

    return User(
      nom: optionalString('nom'),
      prenom: optionalString('prenom'),
      contacts: optionalString('contacts'),
      sex: optionalString('sex'),
      email: optionalString('email'),
      login: requiredString('login'),
      code: requiredString('code'),
      account_type: requiredString('account_type'),
      text_password: optionalString('text_password'),
      address: optionalString('address'),
      admin: optionalString('admin', '0'),
      CodeEtablissement: optionalString('CodeEtablissement'),
      aiToken: optionalString('ai_token'),
      token: optionalString('token'),
    );
  }
}
