// ignore_for_file: unnecessary_import, implementation_imports, sort_child_properties_last, file_names, import_of_legacy_library_into_null_safe

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/models/conduite.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:intl/intl.dart';

class AbsenceDetail extends StatefulWidget {
  final Student student;
  final Conduite absence;
  const AbsenceDetail({Key? key, required this.student, required this.absence})
      : super(key: key);

  @override
  State<AbsenceDetail> createState() => _AbsenceDetailState();
}

class _AbsenceDetailState extends State<AbsenceDetail> {
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

  String getTime(String date) {
    String formattedTime = DateFormat.Hms().format(DateTime.parse(date));
    return formattedTime;
  }

  String getDate(String date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formatted = formatter.format(DateTime.parse(date));
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            // color: CustomTheme.blue,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: FutureBuilder<String>(
            future: CourseServices.getMainCourse(widget.absence.CodeMatiere),
            builder: (
              BuildContext context,
              AsyncSnapshot<String> snapshot,
            ) {
              if (snapshot.data == null) {
                return const Text('loading ...');
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
          Container(
            width: double.infinity,
            color: CustomTheme.grey,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Text(
              'Présence validée',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: CustomTheme.blue),
            title: FutureBuilder<String>(
                future:
                    StudentServices.getMainStudent(widget.absence.CodeEleve),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<String> snapshot,
                ) {
                  if (snapshot.data == null) {
                    return const Text('loading ...');
                  } else {
                    return Text(
                      snapshot.data ?? "",
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                    );
                  }
                }),
            subtitle: const Text('Élève'),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future: CourseServices.getMainCourse(widget.absence.CodeMatiere),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return const Text('Loading ...');
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: const Text('Matiere'),
          ),
          ListTile(
            leading:
                const Icon(Icons.home_max_outlined, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future: CourseServices.getMainClass(widget.absence.CodeClasse),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return const Text('Loading ...');
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: const Text('Classe'),
          ),
          ListTile(
            leading: const Icon(Icons.timer, color: CustomTheme.blue),
            title: Text(widget.absence.Nombre),
            subtitle: const Text("Nombre D'Heures"),
          ),
          ListTile(
              leading:
                  const Icon(Icons.calendar_month, color: CustomTheme.blue),
              title: Text(getDate(widget.absence.DateEnreg)),
              subtitle: const Text("Date d'Enregistrement")),
          ListTile(
            leading: const Icon(Icons.abc_rounded, color: CustomTheme.blue),
            title: Text(getTime(widget.absence.created_at).toString()),
            subtitle: const Text("Heure"),
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
