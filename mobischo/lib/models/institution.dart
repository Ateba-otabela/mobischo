class Institution {
  final String id;
  final String name;
  final String type;
  final String category;
  final String location;
  final String city;
  final String region;
  final String description;
  final List<String> programs;
  final List<String> languages;
  final String logoUrl;
  final String imageUrl;
  final String? imageAsset;
  final String websiteUrl;
  final bool featured;

  const Institution({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.location,
    required this.city,
    required this.region,
    required this.description,
    required this.programs,
    required this.languages,
    required this.logoUrl,
    required this.imageUrl,
    this.imageAsset,
    required this.websiteUrl,
    required this.featured,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? '').toString();
    final category = (json['category'] ?? '').toString();

    return Institution(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: type.isEmpty ? 'public' : type,
      category: category.isEmpty ? 'universitaire' : category,
      location:
          (json['location'] ?? json['city'] ?? json['region'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      region: (json['region'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      programs: _stringList(json['programs']),
      languages: _stringList(json['languages']),
      logoUrl: (json['logo_url'] ?? json['logoUrl'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '').toString(),
      imageAsset: _assetForInstitution((json['id'] ?? '').toString()),
      websiteUrl: (json['website_url'] ?? json['websiteUrl'] ?? '').toString(),
      featured: json['featured'] == true,
    );
  }

  static String? _assetForInstitution(String id) {
    const assetsByInstitutionId = {
      'universite-de-douala': 'assets/images/douala.jpg',
      'universite-de-yaounde-i': 'assets/images/luniversite-de-yaounde-i.jpg',
      'campus-centre-dexcellence-paul-biya': 'assets/images/IAI.jpeg',
      'institut-saint-jean': 'assets/images/saintjean.jpeg',
      'college-bilingue-de-bafoussam': 'assets/images/bafoussam.jpg',
    };

    return assetsByInstitutionId[id];
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }
}
