import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/parent/institution_image.dart';
import 'package:mobischo/models/institution.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class InstitutionDetailsScreen extends StatelessWidget {
  final Institution institution;

  const InstitutionDetailsScreen({Key? key, required this.institution})
      : super(key: key);

  Future<void> _openWebsite(BuildContext context) async {
    final url = institution.websiteUrl.trim();
    if (url.isEmpty) {
      return;
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null) {
      return;
    }

    if (!await launchUrl(parsed, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Impossible d’ouvrir le site web de l’établissement.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel =
        institution.type.toLowerCase() == 'private' ? 'Privée' : 'Publique';
    final category = institution.category.toLowerCase();
    final categoryLabel = category == 'secondaire' || category == 'secondaires'
        ? 'Formations'
        : 'Universitaire';

    return Scaffold(
      backgroundColor: const Color(0xfff7faf7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Institution',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InstitutionImage(
              imageAsset: institution.imageAsset,
              imageUrl: institution.imageUrl,
              logoUrl: institution.logoUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              iconSize: 50,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipOval(
                        child: InstitutionImage(
                          imageUrl: institution.logoUrl,
                          logoUrl: institution.imageUrl,
                          width: 52,
                          height: 52,
                          iconSize: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              institution.name,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _statusPill(typeLabel),
                                _statusPill(categoryLabel,
                                    background: const Color(0xffe0f2fe),
                                    foreground: const Color(0xff0369a1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (institution.location.isNotEmpty)
                    _infoRow(Icons.location_on_outlined, 'Situé à',
                        institution.location),
                  if (institution.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            institution.description,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  if (institution.programs.isNotEmpty)
                    _sectionTitle('Filières'),
                  if (institution.programs.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: institution.programs
                          .map((program) => _chip(program,
                              background: const Color(0xfff3f4f6),
                              foreground: const Color(0xff374151)))
                          .toList(),
                    ),
                  if (institution.languages.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('Langues'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: institution.languages
                          .map((language) => _chip(language,
                              background: const Color(0xffeff6ff),
                              foreground: const Color(0xff1d4ed8)))
                          .toList(),
                    ),
                  ],
                  if (institution.websiteUrl.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openWebsite(context),
                        icon: const Icon(Icons.language_rounded),
                        label: const Text('Visiter le site'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomTheme.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statusPill(String label,
      {Color background = const Color(0xffebfbee),
      Color foreground = const Color(0xff1d7a48)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: foreground, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  static Widget _chip(String label,
      {required Color background, required Color foreground}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    );
  }

  static Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: '$label ',
                    style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                TextSpan(
                    text: value,
                    style:
                        const TextStyle(color: Colors.black87, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
