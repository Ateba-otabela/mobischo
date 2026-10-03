// ignore_for_file: unnecessary_import, implementation_imports, sort_child_properties_last, file_names

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/models/HistoriqueInscription.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/courses.dart';
// ignore: unused_import
import 'package:mobischo/services/services.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class HistoriqueInscriptionDetails extends StatefulWidget {
  final HistoriqueInscription inscription;
  final Student student;
  const HistoriqueInscriptionDetails(
      {Key? key, required this.inscription, required this.student})
      : super(key: key);

  @override
  State<HistoriqueInscriptionDetails> createState() =>
      _HistoriqueInscriptionDetailsState();
}

class _HistoriqueInscriptionDetailsState
    extends State<HistoriqueInscriptionDetails> {
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
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: FutureBuilder<String>(
            future:
                StudentServices.getMainStudent(widget.inscription.CodeEleve),
            builder: (
              BuildContext context,
              AsyncSnapshot<String> snapshot,
            ) {
              if (snapshot.data == null) {
                return Text(uiText(context, 'loadingEllipsis'));
              } else {
                return Text(
                  snapshot.data ?? "",
                  style: Theme.of(context).textTheme.titleLarge,
                );
              }
            }),
      ),
      body: ListView(
        children: [
          ListTile(
            leading:
                const Icon(Icons.inventory_outlined, color: CustomTheme.blue),
            title: Text(widget.inscription.NUMFAC),
            subtitle: Text(uiText(context, 'invoiceNumber')),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: Text(widget.inscription.libinscrip),
            subtitle: Text(uiText(context, 'registrationLabel')),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future:
                  StudentServices.getMainStudent(widget.inscription.CodeEleve),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return Text(uiText(context, 'loadingEllipsis'));
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: Text(uiText(context, 'studentName')),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future: CourseServices.getMainClass(widget.student.CodeClasse),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return Text(uiText(context, 'loadingEllipsis'));
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: Text(uiText(context, 'className')),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_sharp,
                color: CustomTheme.blue),
            title: Text("${widget.inscription.Montantins} FCFA"),
            subtitle: Text(uiText(context, 'registrationAmount')),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_rounded,
                color: CustomTheme.blue),
            title: Text("${widget.inscription.Avance} FCFA"),
            subtitle: Text(uiText(context, 'advance')),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined,
                color: CustomTheme.blue),
            title: Text("${widget.inscription.Reste} FCFA"),
            subtitle: Text(uiText(context, 'remaining')),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on, color: CustomTheme.blue),
            title: Text("${widget.inscription.Montantt} FCFA"),
            subtitle: Text(uiText(context, 'totalAmount')),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future:
                  AcademicServices.getMainYear(widget.inscription.codeannee),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return Text(uiText(context, 'loadingEllipsis'));
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: Text(uiText(context, 'schoolYear')),
          ),
          ListTile(
            leading: const Icon(Icons.timer, color: CustomTheme.blue),
            title: Text("${widget.inscription.heure} FCFA"),
            subtitle: Text(uiText(context, 'time')),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_rounded,
                color: CustomTheme.blue),
            title: Text("${widget.inscription.DateInscription} FCFA"),
            subtitle: Text(uiText(context, 'enrollmentDate')),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //     onPressed: () {
      //       Navigator.pop(context);
      //     },
      //     backgroundColor: CustomTheme.blue,
      //     child: const Icon(Icons.arrow_back_ios)),
    );
  }
}
