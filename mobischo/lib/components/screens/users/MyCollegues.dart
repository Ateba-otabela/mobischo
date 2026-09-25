// ignore_for_file: avoid_print, unused_element, prefer_const_constructors, file_names

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/users/user_detail.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class MyCollegues extends StatefulWidget {
  final User user;

  const MyCollegues({Key? key, required this.user}) : super(key: key);

  @override
  State<MyCollegues> createState() => _MyColleguesState();
}

class _MyColleguesState extends State<MyCollegues> {
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

  bool isLoaded = false;
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<User> _colleagues = [];
  List<User> _filteredColleagues = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadColleagues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadColleagues() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final colleagues = await Services.getTeacherColleagues(
        teacherCode: widget.user.code,
        schoolCode: widget.user.CodeEtablissement,
      );

      if (!mounted) return;

      setState(() {
        _colleagues = colleagues;
        _filteredColleagues = colleagues;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Impossible de charger vos collègues.';
        _loading = false;
      });
    }
  }

  void _applySearch(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _filteredColleagues = query.isEmpty
          ? _colleagues
          : _colleagues.where((teacher) {
              final fullName = '${teacher.nom} ${teacher.prenom}'.toLowerCase();
              final code = teacher.code.toLowerCase();
              return fullName.contains(query) || code.contains(query);
            }).toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-2496623977736610/2133664237',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
          setState(() {
            isLoaded = true;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            _createInterstitialAd();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomTheme.grey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _applySearch,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Rechercher un collègue',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: CustomTheme.blue))
                : _hasError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _filteredColleagues.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.groups_outlined,
                                    size: 56,
                                    color: CustomTheme.blue,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucun collègue trouvé',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Aucun autre enseignant n'est actuellement disponible dans votre établissement.",
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            itemCount: _filteredColleagues.length,
                            itemBuilder: (BuildContext context, int index) {
                              final colleague = _filteredColleagues[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: AssetImage(
                                              'assets/images/avatar-s-19.jpg'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${colleague.nom} ${colleague.prenom}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (colleague.code.isNotEmpty)
                                          Text('Code: ${colleague.code}'),
                                        if (colleague.account_type.isNotEmpty)
                                          Text(colleague.account_type),
                                      ],
                                    ),
                                    trailing:
                                        const Icon(Icons.arrow_forward_ios),
                                    onTap: () {
                                      if (isLoaded == true) {
                                        _interstitialAd!.show();
                                      }
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              UserDetailScreen(
                                            user: colleague,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
