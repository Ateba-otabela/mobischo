import 'package:flutter/material.dart';
import 'package:mobischo/models/advert.dart';
import 'package:mobischo/services/advert_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SchoolAdvertScreen extends StatefulWidget {
  final String userCode;

  const SchoolAdvertScreen({Key? key, required this.userCode}) : super(key: key);

  @override
  State<SchoolAdvertScreen> createState() => _SchoolAdvertScreenState();
}

class _SchoolAdvertScreenState extends State<SchoolAdvertScreen> {
  List<Advert> _adverts = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadAdverts();
  }

  Future<void> _loadAdverts() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final adverts = await AdvertServices.getSchoolAdverts();
      setState(() {
        _adverts = adverts;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : _error
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Impossible de charger les offres pour le moment.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                : _adverts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'Aucune opportunité disponible pour le moment.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _adverts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final advert = _adverts[index];
                          final imageUrl = advert.primaryImage;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
                            child: InkWell(
                              onTap: () async {
                                if (advert.link.isEmpty) {
                                  return;
                                }

                                final uri = Uri.tryParse(advert.link);
                                if (uri != null && await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (imageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          imageUrl,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const SizedBox(
                                            width: 64,
                                            height: 64,
                                            child: Center(
                                              child: Icon(Icons.school_outlined, size: 28),
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: Center(
                                          child: Icon(Icons.school_outlined, size: 28),
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            advert.name.isNotEmpty ? advert.name : 'École / Université',
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                          if (advert.description.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6.0),
                                              child: Text(
                                                advert.description,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ),
                                          if (advert.link.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                'Voir plus',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(color: CustomTheme.blue),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
