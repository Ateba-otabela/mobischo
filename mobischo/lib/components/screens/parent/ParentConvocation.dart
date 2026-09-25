// ignore_for_file: camel_case_types, sort_child_properties_last, prefer_typing_uninitialized_variables, non_constant_identifier_names, file_names

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/teachers.dart/convocation_detail.dart';
import 'package:mobischo/home.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class ParentConvocationList extends StatefulWidget {
  final User user;
  final bool embedded;

  const ParentConvocationList({
    Key? key,
    required this.user,
    this.embedded = false,
  }) : super(key: key);

  @override
  State<ParentConvocationList> createState() => _ParentConvocationListState();
}

class _ParentConvocationListState extends State<ParentConvocationList> {
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

  bool isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-2496623977736610/2133664237',
        // adUnitId: 'ca-app-pub-2496623977736610/2133664237',
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
        ));
  }

  String getGender(String sex) {
    if (sex == '0') {
      return "Masculin";
    } else {
      return "Feminin";
    }
  }

  var sequence;
  var year;

  List<DropdownMenuItem<String>> ListSequences = [];
  List<DropdownMenuItem<String>> ListYears = [];

  Future<List<DropdownMenuItem>> sequences() {
    ListSequences.clear();
    Future<List<DropdownMenuItem>> all_sequences =
        AcademicServices.getSequences().then((all_sequences) {
      for (var i = 0; i < all_sequences.length; i++) {
        ListSequences.add(DropdownMenuItem(
            value: all_sequences[i].CodeEvaluation.toString(),
            child: Text(all_sequences[i].LibelleEvaluation)));
      }
      return ListSequences;
    });
    return all_sequences;
  }

  Future<List<DropdownMenuItem>> years() {
    ListYears.clear();
    Future<List<DropdownMenuItem>> all_years =
        AcademicServices.getYears().then((all_years) {
      for (var i = 0; i < all_years.length; i++) {
        ListYears.add(DropdownMenuItem(
            value: all_years[i].CodeAnnee.toString(),
            child: Text(all_years[i].Libelle)));
      }
      return ListYears;
    });
    return all_years;
  }

  @override
  void initState() {
    super.initState;
    sequences();
    years();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
        children: [
          Container(
            color: CustomTheme.grey,
            // decoration: CustomTheme.getCardDecoration(),
            height: 80,
            width: double.infinity,
            // color: CustomTheme.blue,
            child: Column(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                        child: SizedBox(
                      width: double.infinity,
                      height: 80,
                      // padding: const EdgeInsets.all(2.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        // elevation: 10,
                        child: InkWell(
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ListTile(
                                trailing: const Image(
                                  image:
                                      AssetImage('assets/images/landing5.png'),
                                ),
                                title: const Text('Eleves Convoques'),
                                subtitle: Text(
                                  'Cliquez pour plus de details',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                onTap: () {
                                  // BottomForm(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ))
                  ],
                ),
              ],
            ),
          ),
          // const Divider(
          //   height: 10,
          //   color: CustomTheme.grey,
          // ),
          Flexible(
              child: convocationList(
            widget: widget,
            isLoaded: isLoaded,
            interstitialAd: _interstitialAd,
          )),
        ],
      );

    if (widget.embedded) {
      return Container(
        color: CustomTheme.grey,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Retour au tableau de bord',
                  icon: const Icon(Icons.arrow_back_ios),
                  color: CustomTheme.blue,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
            )),
        title: Text(
          'Liste des Convocations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // BottomForm(context);

          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Home(
                      user: widget.user,
                      selectedPage: 3,
                    )),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: CustomTheme.blue,
      ),
    );
  }
}

class _MessagesEmptyState extends StatelessWidget {
  final String label;

  const _MessagesEmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationSize = (constraints.maxWidth * 0.46).clamp(140.0, 180.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 18),
              child: Column(
                children: [
                  _MessagesIllustration(size: illustrationSize),
                  const SizedBox(height: 24),
                  const Text(
                    'Aucun message disponible pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF424242),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: const Text(
                      'Les messages et informations de l\'établissement apparaîtront ici lorsqu\'ils seront disponibles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    height: 40,
                    decoration: BoxDecoration(
                      color: CustomTheme.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
    );
  }
}

class _MessagesIllustration extends StatelessWidget {
  final double size;

  const _MessagesIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.76,
            height: size * 0.48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: Icon(Icons.chat_bubble_outline, size: size * 0.34, color: const Color(0xFF2E7D32)),
          ),
          Positioned(
            bottom: size * 0.06,
            child: Icon(Icons.mail_outline, size: size * 0.38, color: const Color(0xFF616161)),
          ),
          Positioned(
            top: size * 0.02,
            right: size * 0.04,
            child: Icon(Icons.notifications_none_rounded, size: size * 0.22, color: const Color(0xFF2E7D32)),
          ),
          Positioned(
            bottom: size * 0.02,
            left: size * 0.04,
            child: Icon(Icons.check_circle_outline_rounded, size: size * 0.2, color: const Color(0xFF66BB6A)),
          ),
        ],
      ),
    );
  }
}

class convocationList extends StatelessWidget {
  final InterstitialAd? interstitialAd;
  final bool isLoaded;
  final ParentConvocationList widget;
  final String sortKey;
  final String sortLabel;
  final ValueChanged<String>? onSortChanged;

  const convocationList({
    Key? key,
    required this.widget,
    required this.interstitialAd,
    required this.isLoaded,
    this.sortKey = 'newest',
    this.sortLabel = 'Trier les messages',
    this.onSortChanged,
  }) : super(key: key);

  List<dynamic> _sortedConvocations(List<dynamic> convocations) {
    final sorted = List<dynamic>.from(convocations);
    sorted.sort((a, b) {
      final aDate = _parseDate(a.dateConvocation);
      final bDate = _parseDate(b.dateConvocation);
      final comparison = aDate.compareTo(bDate);
      return sortKey == 'oldest' ? comparison : -comparison;
    });
    return sorted;
  }

  DateTime _parseDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final dateTime = DateTime.tryParse(normalized);
    if (dateTime != null) {
      return dateTime;
    }

    final parts = normalized.split(RegExp(r'[/\-]'));
    if (parts.length == 3) {
      final first = parts[0];
      final second = parts[1];
      final third = parts[2];
      try {
        if (first.length == 4) {
          return DateTime.parse('$first-${second.padLeft(2, '0')}-${third.padLeft(2, '0')}');
        }
        if (third.length == 4) {
          return DateTime.parse('$third-${second.padLeft(2, '0')}-$first');
        }
      } catch (_) {}
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AcademicServices.getParentConvocation(widget.user.code),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.data.isEmpty) {
          return _MessagesEmptyState(label: sortLabel);
        } else {
          final sortedData = _sortedConvocations(snapshot.data);
          return Column(
            children: [
              Expanded(
                child: Container(
                  color: CustomTheme.grey,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sortedData.length,
                    itemBuilder: (BuildContext context, int index) {
                      final item = sortedData[index];
                      return Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ExpansionTile(
                                title: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FutureBuilder<String>(
                                        future: StudentServices.getMainStudent(item.CodeEleve),
                                        builder: (
                                          BuildContext context,
                                          AsyncSnapshot<String> snapshot,
                                        ) {
                                          if (snapshot.data == null) {
                                            return const Text('loading ...');
                                          } else {
                                            return Text(snapshot.data ?? "");
                                          }
                                        },
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        item.dateConvocation,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                children: <Widget>[
                                  ListTile(
                                    title: Text(
                                      'Convoqué le ${item.dateConvocation} pour ${item.motif}',
                                    ),
                                    trailing: const Icon(Icons.arrow_forward),
                                    onTap: () {
                                      if (isLoaded == true) {
                                        interstitialAd!.show();
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ConvocationDetail(
                                            convocation: item,
                                            user: widget.user,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    title: Text(
                                      "MESSAGE",
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    subtitle: Text(item.description),
                                    onTap: () {
                                      if (isLoaded == true) {
                                        interstitialAd!.show();
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ConvocationDetail(
                                            convocation: item,
                                            user: widget.user,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PopupMenuButton<String>(
                  onSelected: onSortChanged ?? (_) {},
                  offset: const Offset(0, -140),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'newest', child: Text('Plus récent')),
                    PopupMenuItem(value: 'oldest', child: Text('Plus ancien')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    height: 40,
                    decoration: BoxDecoration(
                      color: CustomTheme.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          sortLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
