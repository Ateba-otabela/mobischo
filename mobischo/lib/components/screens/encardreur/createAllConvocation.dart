// ignore_for_file: file_names, non_constant_identifier_names, prefer_const_constructors, import_of_legacy_library_into_null_safe, prefer_typing_uninitialized_variables, avoid_print

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/components/screens/teachers.dart/convocation_success.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/utils/custom_theme.dart';

class CreateAllConvocation extends StatefulWidget {
  final User user;
  const CreateAllConvocation({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<CreateAllConvocation> createState() => _CreateAllConvocationState();
}

class _CreateAllConvocationState extends State<CreateAllConvocation> {
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

  var course;
  var date = 'Date de convocation';
  var motif;

  List<DropdownMenuItem<String>> ListCourses = [];
  List<DropdownMenuItem<String>> ListMotifs = [];
  TextEditingController description = TextEditingController();

  List<DropdownMenuItem> motifs() {
    ListMotifs.clear();
    ListMotifs.add(DropdownMenuItem(
        value: "Insubordination",
        child: Text(uiText(context, 'insubordination'))));
    ListMotifs.add(DropdownMenuItem(
        value: "Retard Abusive",
        child: Text(uiText(context, 'excessiveLateness'))));
    ListMotifs.add(DropdownMenuItem(
        value: "Violence", child: Text(uiText(context, 'violence'))));
    ListMotifs.add(DropdownMenuItem(
        value: "Indiscipline", child: Text(uiText(context, 'indiscipline'))));
    ListMotifs.add(DropdownMenuItem(
        value: "Autre", child: Text(uiText(context, 'otherReason'))));
    return ListMotifs;
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Refer step 1
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() {
        date = picked.toString();
        date = HumanDateFormat(date);
      });
    }
  }

  String HumanDateFormat(String date) {
    return DateFormat.yMMMd().format(DateTime.parse(date));
  }

  @override
  void initState() {
    super.initState();
    motifs();
  }

  String getGender(String sex) {
    if (sex == '0') {
      return "Masculin";
    } else {
      return "Feminin";
    }
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
            icon: const Icon(Icons.arrow_back_ios)),
        title: Text(
          "CONVOCATION",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: CustomTheme.cardShadow),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 30, bottom: 40, left: 10, right: 10),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: Icon(Icons.calendar_month),
                      title: Text(date),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        _selectDate(context);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: DropdownButton(
                        items: ListMotifs,
                        value: motif,
                        isExpanded: true,
                        onChanged: (value) {
                          motif = value;
                          setState(() {
                            // print(year);
                            motif = value;
                          });
                          // Navigator.pop(context);
                        },
                        elevation: 10,
                        hint: Text(uiText(context, 'conveningReason')),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: TextField(
                        controller: description,
                        decoration: InputDecoration(
                          labelText: uiText(context, 'description'),
                          // border: OutlineInputBorder(

                          // ),
                        ),
                        maxLines: 5, // <-- SEE HERE
                        minLines: 3, // <-- SEE HERE
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 17, right: 17, top: 30),
                      child: CustomButton(
                          text: "Convoquer",
                          onPress: () {
                            // print("students : ${widget.students}");
                            print('Motif $motif');
                            if (motif == null ||
                                description.text == '' ||
                                date == 'Date de convocation') {
                              Fluttertoast.showToast(
                                  msg:
                                      "Assurez vous de remplir tous les champs",
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.BOTTOM,
                                  fontSize: 16.0);
                            } else {
                              StudentServices.getAllStudents(
                                      widget.user.CodeEtablissement)
                                  .then((students) {
                                print(students);
                                for (int i = 0; i < students.length; i++) {
                                  AcademicServices.insertConvocation(
                                      widget.user.code,
                                      students[i].CodeEleve,
                                      motif,
                                      description.text,
                                      '',
                                      date);
                                }
                              });

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: ((context) => ConvocationSuccess(
                                          user: widget.user))));
                            }
                          }),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
