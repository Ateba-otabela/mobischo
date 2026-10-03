// ignore_for_file: camel_case_types, sort_child_properties_last, prefer_typing_uninitialized_variables, non_constant_identifier_names, file_names

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/teachers.dart/convocation_detail.dart';
import 'package:mobischo/home.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/l10n/ui_text.dart';

class EncardreurConvocationList extends StatefulWidget {
  final User user;
  const EncardreurConvocationList({Key? key, required this.user})
      : super(key: key);

  @override
  State<EncardreurConvocationList> createState() =>
      _EncardreurConvocationListState();
}

class _EncardreurConvocationListState extends State<EncardreurConvocationList> {
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
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      body: Column(
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
                                title:
                                    Text(uiText(context, 'studentsToConvene')),
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
          Flexible(child: convocationList(widget: widget)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // BottomForm(context);

          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Home(
                      user: widget.user,
                      selectedPage: 1,
                    )),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: CustomTheme.blue,
      ),
    );
  }
}

class convocationList extends StatelessWidget {
  const convocationList({
    Key? key,
    required this.widget,
  }) : super(key: key);

  final EncardreurConvocationList widget;
  String getMessage(student) {
    return "$student";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AcademicServices.getTeacherConvocation(widget.user.code),
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
                    return Column(
                      children: <Widget>[
                        // SizedBox(height: 20.0),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)),
                            child: ExpansionTile(
                              title: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FutureBuilder<String>(
                                        future: StudentServices.getMainStudent(
                                            snapshot.data[index].CodeEleve),
                                        builder: (
                                          BuildContext context,
                                          AsyncSnapshot<String> snapshot,
                                        ) {
                                          if (snapshot.data == null) {
                                            return Text(uiText(
                                                context, 'loadingEllipsis'));
                                          } else {
                                            return Text(
                                              snapshot.data ?? "",
                                              // style: Theme.of(context)
                                              //     .textTheme
                                              //     .titleSmall,
                                            );
                                          }
                                        }),
                                  ),
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        snapshot.data[index].dateConvocation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ))
                                ],
                              ),
                              children: <Widget>[
                                ListTile(
                                  title: Text(uiText(
                                    context,
                                    'convocationDateReason',
                                    parameters: {
                                      'date':
                                          snapshot.data[index].dateConvocation,
                                      'reason': snapshot.data[index].motif,
                                    },
                                  )),
                                  trailing: const Icon(Icons.arrow_forward),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ConvocationDetail(
                                                  convocation:
                                                      snapshot.data[index],
                                                  user: widget.user)),
                                    );
                                  },
                                ),
                                ListTile(
                                  title: Text(
                                    "MESSAGE",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  subtitle:
                                      Text(snapshot.data[index].description),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ConvocationDetail(
                                                  convocation:
                                                      snapshot.data[index],
                                                  user: widget.user)),
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }));

          // return Container(
          //   color: CustomTheme.grey,
          //   child: ListView.builder(
          //       shrinkWrap: true,
          //       itemCount: snapshot.data.length,
          //       itemBuilder: (BuildContext context, int index) {
          //         return Padding(
          //           padding: const EdgeInsets.all(3),
          //           child: Container(
          //             decoration: BoxDecoration(
          //                 borderRadius: BorderRadius.circular(10),
          //                 color: Colors.white),
          //             child: ListTile(
          //               title: Column(
          //                 children: [
          //
          //                   Text(
          //                     'A ete convoque le ${snapshot.data[index].dateConvocation} pour ${snapshot.data[index].motif}',
          //                     style: Theme.of(context).textTheme.bodySmall,
          //                   )
          //                 ],
          //               ),
          //               subtitle: Column(
          //                 children: [
          //                   Padding(
          //                     padding:
          //                         const EdgeInsets.only(top: 10, bottom: 10),
          //                     child: Text(
          //                       "DESCRIPTION DE L'ENSEIGNANT",
          //                       style: Theme.of(context).textTheme.bodyMedium,
          //                     ),
          //                   ),
          //                   Text(
          //                     snapshot.data[index].description,
          //                     style: Theme.of(context).textTheme.bodySmall,
          //                   ),
          //                 ],
          //               ),
          //               // trailing: const Icon(Icons.arrow_forward_ios),
          //               onTap: () {
          //                 Navigator.push(
          //                   context,
          //                   MaterialPageRoute(
          //                       builder: (context) => ConvocationDetail(
          //                           convocation: snapshot.data[index],
          //                           user: widget.user)),
          //                 );
          //               },
          //             ),
          //           ),
          //         );
          //       }),
          // );
        }
      },
    );
  }
}
