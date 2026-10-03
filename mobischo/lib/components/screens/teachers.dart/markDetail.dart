// ignore_for_file: unnecessary_import, implementation_imports, sort_child_properties_last, file_names

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/models/mark.dart';
import 'package:mobischo/models/student.dart';
// ignore: unused_import
import 'package:mobischo/services/services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/l10n/ui_text.dart';

class MarkDetail extends StatefulWidget {
  final Mark mark;
  final Student student;
  const MarkDetail({Key? key, required this.mark, required this.student})
      : super(key: key);

  @override
  State<MarkDetail> createState() => _MarkDetailState();
}

class _MarkDetailState extends State<MarkDetail> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: CustomTheme.blue,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          "${widget.student.Nom} ${widget.student.Prenom}",
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      body: ListView(
        children: [
          // ListTile(
          //   leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
          //   title: Text(widget.mark.Codeenseignement??''),
          //   subtitle: const Text('Code Enseignement'),
          // ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: Text(widget.mark.valeur),
            subtitle: Text(uiText(context, 'markValue')),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: Text(widget.mark.total),
            subtitle: Text(uiText(context, 'total')),
          ),
          // ListTile(
          //   leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
          //   title: Text(widget.mark.coef),
          //   subtitle: const Text("Coefficient"),
          // ),
          // ListTile(
          //   leading: const Icon(Icons.timer, color: CustomTheme.blue),
          //   title: Text(widget.mark.Dateeng),
          //   subtitle: const Text("Nombre D'Heures"),
          // ),
          // ListTile(
          //     leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
          //     title: FutureBuilder<String>(
          //       future: SchoolServices.getMainSchool('11201'),
          //       builder:
          //           (BuildContext context, AsyncSnapshot<String> snapshot) {
          //         if (snapshot.data == null) {
          //           return const Text('Loading ...');
          //         } else {
          //           return Text(snapshot.data ?? "");
          //         }
          //       },
          //     ),
          //     subtitle: const Text("Etablissement"))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context);
          },
          backgroundColor: CustomTheme.blue,
          child: const Icon(Icons.arrow_back_ios)),
    );
  }
}
