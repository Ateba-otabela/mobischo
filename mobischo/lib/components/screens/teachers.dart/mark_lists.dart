// ignore_for_file: camel_case_types, sort_child_properties_last, prefer_typing_uninitialized_variables, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/teachers.dart/sorted_marks.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/mark_services.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class MarkListScreen extends StatefulWidget {
  final Course course;
  const MarkListScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<MarkListScreen> createState() => _MarkListScreenState();
}

class _MarkListScreenState extends State<MarkListScreen> {
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
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              // color: CustomTheme.blue,
            )),
        title: FutureBuilder<String>(
          future: CourseServices.getMainCourse(widget.course.CodeMatiere),
          builder: (
            BuildContext context,
            AsyncSnapshot<String> snapshot,
          ) {
            if (snapshot.data == null) {
              return const Text('loading ...');
            } else {
              return Text(
                snapshot.data!.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge,
              );
            }
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                BottomForm(context);
              },
              icon: const Icon(
                Icons.more_vert,
                // color: CustomTheme.blue,
              ))
        ],
      ),
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
                        elevation: 10,
                        child: InkWell(
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ListTile(
                                trailing: const Image(
                                  image: AssetImage('assets/images/menu4.png'),
                                ),
                                title: FutureBuilder<String>(
                                  future: AcademicServices.getMainSequence(
                                      sequence),
                                  builder: (
                                    BuildContext context,
                                    AsyncSnapshot<String> snapshot,
                                  ) {
                                    if (snapshot.data == null) {
                                      return const Text('loading ...');
                                    } else {
                                      return Text(
                                        snapshot.data!.toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.black),
                                      );
                                    }
                                  },
                                ),
                                subtitle: FutureBuilder<String>(
                                  future: AcademicServices.getMainYear(year),
                                  builder: (
                                    BuildContext context,
                                    AsyncSnapshot<String> snapshot,
                                  ) {
                                    if (snapshot.data == null) {
                                      return const Text('loading ...');
                                    } else {
                                      return Text(
                                        snapshot.data!.toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.black),
                                      );
                                    }
                                  },
                                ),
                                onTap: () {
                                  BottomForm(context);
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
          Flexible(child: markList(widget: widget)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          BottomForm(context);
        },
        child: const Icon(Icons.note_add_outlined),
        backgroundColor: CustomTheme.blue,
      ),
    );
  }

  Future<void> BottomForm(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        DropdownButton(
                          isExpanded: true,
                          items: ListSequences,
                          value: sequence,
                          onChanged: (value) {
                            sequence = value;
                            setState(() {
                              sequence = value;

                              // Navigator.pop(context);
                              // Navigator.push(context, MaterialPageRoute(builder: ((context) => SortedMarkListScreen(course: widget.course, sequence: sequence, year: year))));
                            });
                          },
                          elevation: 10,
                          hint: const Text('Sequences Evaluations'),
                        ),
                        DropdownButton(
                          items: ListYears,
                          value: year,
                          isExpanded: true,
                          onChanged: (value) {
                            year = value;
                            setState(() {
                              // print(year);
                              year = value;
                            });
                            // Navigator.push(context, MaterialPageRoute(builder: ((context) => SortedMarkListScreen(course: widget.course, sequence: sequence, year: year))));
                            // Navigator.pop(context);
                          },
                          elevation: 10,
                          hint: const Text('Annee Scholaires'),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, top: 20),
                    child: CustomButton(
                        text: "Trier",
                        onPress: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: ((context) => SortedMarkListScreen(
                                      course: widget.course,
                                      sequence: sequence,
                                      year: year))));
                        }),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class markList extends StatelessWidget {
  const markList({
    Key? key,
    required this.widget,
  }) : super(key: key);

  final MarkListScreen widget;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MarkServices.getCourseMarksForNotes(widget.course.CodeEnseignement),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Impossible de charger les notes. Veuillez réessayer.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else if (snapshot.data == null || snapshot.data.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aucune note enregistrée pour cette matière.',
                textAlign: TextAlign.center,
              ),
            ),
          );
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
                          Icons.note_add_outlined,
                          color: CustomTheme.blue,
                        ),
                        title: FutureBuilder<String>(
                            future: StudentServices.getMainStudent(
                                snapshot.data[index].CodeEleve),
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<String> snapshot,
                            ) {
                              if (snapshot.data == null) {
                                return const Text('loading ...');
                              } else {
                                return Text(
                                  snapshot.data ?? "",
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 13),
                                );
                              }
                            }),
                        subtitle: Text("Note: ${snapshot.data[index].valeur}"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {},
                      ),
                    ),
                  );
                }),
          );
        }
      },
    );
  }
}
