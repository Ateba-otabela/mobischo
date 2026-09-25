// ignore_for_file: file_names, non_constant_identifier_names, import_of_legacy_library_into_null_safe

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/parent/HistoriqueInscriptions.dart';
import 'package:mobischo/components/screens/parent/InscriptionDetails.dart';
import 'package:mobischo/models/inscription.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/inscription_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';
import 'package:intl/intl.dart';

class MyChildrenInscriptions extends StatefulWidget {
  final User user;
  final Student student;
  const MyChildrenInscriptions(
      {Key? key, required this.user, required this.student})
      : super(key: key);

  @override
  State<MyChildrenInscriptions> createState() => _MyChildrenInscriptionsState();
}

class _MyChildrenInscriptionsState extends State<MyChildrenInscriptions> {
  String getGender(String sex) {
    if (sex == '0') {
      return "Masculin";
    } else {
      return "Feminin";
    }
  }

  String HumanDateFormat(String date) {
    return DateFormat.yMMMd().format(DateTime.parse(date));
  }

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
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            )),
        title: Text(
          getStudentDisplayName(widget.student),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Center(
        child: FutureBuilder(
          future: InscriptionServices.getStudentInscription(
              widget.student.CodeEleve),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 12, left: 5, right: 5, bottom: 5),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: CustomTheme.cardShadow),
                      child: ListTile(
                        trailing: const Image(
                            image: AssetImage('assets/images/money.png')),
                        title: const Text(
                          "INSCRIPTIONS",
                          // textAlign: TextAlign.center,
                          // style: TextStyle(fontSize: 30),
                        ),
                        subtitle: Text(
                          "Cliquez pour consulter l'historique",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white),
                              child: ListTile(
                                leading: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                          image: AssetImage(
                                              'assets/images/avatar-s-19.jpg'),
                                          fit: BoxFit.fill),
                                    )),
                                title: Text(
                                  "No RECU : ${snapshot.data[index].NUMFAC}",
                                ),
                                subtitle: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FutureBuilder<String>(
                                        future: InscriptionServices
                                            .getSumInscription(
                                                snapshot.data[index].CodeEleve,
                                                snapshot.data[index].NUMFAC),
                                        builder: (
                                          BuildContext context,
                                          AsyncSnapshot<String> snapshot,
                                        ) {
                                          if (snapshot.data == null) {
                                            return const Text('loading ...');
                                          } else {
                                            return Text(
                                                "Montant : ${snapshot.data!.toUpperCase()} FCFA",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium);
                                          }
                                        },
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                          "Date de paiement : ${HumanDateFormat(snapshot.data[index].DateInscription.toString())}"),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.more_vert),
                                onTap: () {
                                  BottomForm(context, snapshot.data[index]);
                                },
                              ),
                            ),
                          );
                        }),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> BottomForm(BuildContext context, Inscription inscription) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          return Container(
            height: 150,
            width: double.infinity,
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(
                      Icons.person,
                      color: CustomTheme.blue,
                    ),
                    title: const Text('Details'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => InscriptionDetail(
                                    inscription: inscription,
                                    student: widget.student,
                                  ))));
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.inventory_outlined,
                      color: CustomTheme.blue,
                    ),
                    title: const Text("Historique de Paiements"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) =>
                                  MyChildrenHistoriqueInscriptions(
                                      user: widget.user,
                                      student: widget.student,
                                      NUMFAC: inscription.NUMFAC))));
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
