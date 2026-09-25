// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/parent/HistoriqueInscriptionDetails.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/inscription_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class MyChildrenHistoriqueInscriptions extends StatefulWidget {
  final User user;
  final Student student;
  final String NUMFAC;
  const MyChildrenHistoriqueInscriptions(
      {Key? key,
      required this.user,
      required this.student,
      required this.NUMFAC})
      : super(key: key);

  @override
  State<MyChildrenHistoriqueInscriptions> createState() =>
      _MyChildrenHistoriqueInscriptionsState();
}

class _MyChildrenHistoriqueInscriptionsState
    extends State<MyChildrenHistoriqueInscriptions> {
  String getGender(String sex) {
    if (sex == '0') {
      return "Masculin";
    } else {
      return "Feminin";
    }
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
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 12, left: 5, right: 5, bottom: 5),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: CustomTheme.cardShadow),
              child: ListTile(
                trailing:
                    const Image(image: AssetImage('assets/images/money1.jpg')),
                title: const Text(
                  "HISTORIQUE D'INSCRIPTIONS",

                  // textAlign: TextAlign.center,
                  // style: TextStyle(fontSize: 30),
                ),
                subtitle: Text(
                  "NUMFAC : ${widget.NUMFAC}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          Flexible(
            child: FutureBuilder(
              future: InscriptionServices.getStudentHistoriqueInscription(
                  widget.student.CodeEleve, widget.NUMFAC),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return Container(
                    color: CustomTheme.grey,
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
                                leading: const Icon(
                                  Icons.inventory_outlined,
                                  color: CustomTheme.blue,
                                ),
                                title: Text(
                                  "Paiement : ${snapshot.data[index].libinscrip}",
                                ),
                                subtitle: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Montant : ${snapshot.data[index].Montantins} FCFA",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Avance : ${snapshot.data[index].Avance} FCFA",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Reste : ${snapshot.data[index].Reste} FCFA",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.more_vert),
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }
                                  Navigator.pop(context);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: ((context) =>
                                              HistoriqueInscriptionDetails(
                                                inscription:
                                                    snapshot.data[index],
                                                student: widget.student,
                                              ))));
                                },
                              ),
                            ),
                          );
                        }),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
