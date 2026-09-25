// ignore_for_file: unnecessary_import, implementation_imports, sort_child_properties_last, file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/models/inscription.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/courses.dart';
// ignore: unused_import
import 'package:mobischo/services/services.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class InscriptionDetail extends StatefulWidget {
  final Inscription inscription;
  final Student student;
  const InscriptionDetail(
      {Key? key, required this.inscription, required this.student})
      : super(key: key);

  @override
  State<InscriptionDetail> createState() => _InscriptionDetailState();
}

class _InscriptionDetailState extends State<InscriptionDetail> {
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
        actions: [
          IconButton(
              onPressed: () {
                BottomForm(context, widget.student);
                // showPopupDialog(context);
              },
              icon: const Icon(Icons.more_vert),
              color: Colors.white)
        ],
        centerTitle: true,
        title: FutureBuilder<String>(
            future:
                StudentServices.getMainStudent(widget.inscription.CodeEleve),
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
          ListTile(
            leading:
                const Icon(Icons.inventory_outlined, color: CustomTheme.blue),
            title: Text(widget.inscription.NUMFAC),
            subtitle: const Text('Numero de Facture'),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: Text(widget.inscription.libinscrip),
            subtitle: const Text("Libelle Inscription"),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: Text(widget.inscription.Tranche),
            subtitle: const Text("Tranche"),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future:
                  StudentServices.getMainStudent(widget.inscription.CodeEleve),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return const Text('Loading ...');
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: const Text('Eleve'),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future: CourseServices.getMainClass(widget.student.CodeClasse),
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
            leading: const Icon(Icons.monetization_on_sharp,
                color: CustomTheme.blue),
            title: Text("${widget.inscription.Montantins} FCFA"),
            subtitle: const Text("Montant d'Inscription"),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_rounded,
                color: CustomTheme.blue),
            title: Text("${widget.inscription.Avance} FCFA"),
            subtitle: const Text("Avance"),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined,
                color: CustomTheme.blue),
            title: Text("${widget.inscription.Reste} FCFA"),
            subtitle: const Text("Reste"),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on, color: CustomTheme.blue),
            title: Text("${widget.inscription.Montantt} FCFA"),
            subtitle: const Text("Montant Total"),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future:
                  AcademicServices.getMainYear(widget.inscription.codeannee),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return const Text('Loading ...');
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: const Text("Annee Scholaire"),
          ),
          ListTile(
            leading: const Icon(Icons.timer, color: CustomTheme.blue),
            title: Text("${widget.inscription.heure} FCFA"),
            subtitle: const Text("Heure D'inscription"),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_rounded,
                color: CustomTheme.blue),
            title: Text("${widget.inscription.DateInscription} FCFA"),
            subtitle: const Text("Date d'Inscription"),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            BottomForm(context, widget.student);
          },
          backgroundColor: CustomTheme.blue,
          child: const Icon(Icons.more_horiz)),
    );
  }

  Future<void> BottomForm(BuildContext context, Student student) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          return Container(
            height: 100,
            width: double.infinity,
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.inventory_outlined,
                        color: CustomTheme.blue),
                    title: const Text("Historique des Paiements"),
                    subtitle:
                        const Text("Consultez l'Historique de cette facture"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pop(context);
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: ((context) => StudentDetailScreen(
                      //               student: student,
                      //               user: widget.user,
                      //             ))));
                    },
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
