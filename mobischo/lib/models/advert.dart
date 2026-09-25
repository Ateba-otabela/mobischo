import 'dart:convert';

class Advert {
  final int id;
  final String name;
  final String phone;
  final String type;
  final int isDeleted;
  final String video;
  final String package;
  final String link;
  final String images;
  final String description;
  final String towns;
  final String logo;
  final int isPopular;
  final String department;
  final String language;
  final String group;

  const Advert({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.isDeleted,
    required this.video,
    required this.package,
    required this.link,
    required this.images,
    required this.description,
    required this.towns,
    required this.logo,
    required this.isPopular,
    required this.department,
    required this.language,
    required this.group,
  });

  factory Advert.fromJson(Map<String, dynamic> json) {
    return Advert(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      phone: _asString(json['phone']),
      type: _asString(json['type']),
      isDeleted: _asInt(json['isDeleted']),
      video: _asString(json['video']),
      package: _asString(json['package']),
      link: _asString(json['link']),
      images: _asString(json['images']),
      description: _asString(json['description']),
      towns: _asString(json['towns']),
      logo: _asString(json['logo']),
      isPopular: _asInt(json['isPopular']),
      department: _asString(json['department']),
      language: _asString(json['language']),
      group: _asString(json['group']),
    );
  }

  static String _asString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  static int _asInt(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  String get primaryImage {
    final logoUrl = logo.trim();
    if (logoUrl.isNotEmpty) {
      return logoUrl;
    }

    final imagesValue = images.trim();
    if (imagesValue.isEmpty) {
      return '';
    }

    if (imagesValue.startsWith('[')) {
      try {
        final decoded = List<dynamic>.from((jsonDecode(imagesValue) as List<dynamic>));
        for (final item in decoded) {
          final value = item.toString().trim();
          if (value.isNotEmpty) {
            return value;
          }
        }
      } catch (_) {
        return '';
      }
      return '';
    }

    if (imagesValue.contains(',')) {
      final first = imagesValue.split(',').first.trim();
      if (first.isNotEmpty) {
        return first;
      }
    }

    return imagesValue;
  }
}
