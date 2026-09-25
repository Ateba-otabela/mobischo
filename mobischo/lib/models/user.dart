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
      required this.CodeEtablissement
      });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      contacts: json['contacts'] as String,
      sex: json['sex'] as String,
      email: json['email'] as String,
      login: json['login'] as String,
      code: json['code'] as String,
      account_type: json['account_type'] as String,
      text_password: json['text_password'] as String,
      address: json['address'] as String,
      admin: json['admin'] as String,
      CodeEtablissement: json['CodeEtablissement'] as String
    );
  }
}
