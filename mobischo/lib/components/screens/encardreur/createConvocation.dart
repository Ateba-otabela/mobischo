// ignore_for_file: file_names, non_constant_identifier_names, prefer_const_constructors, import_of_legacy_library_into_null_safe, prefer_typing_uninitialized_variables, avoid_print

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/models/class.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/components/screens/teachers.dart/convocation_success.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/utils/custom_theme.dart';

class CreateEncardreurConvocation extends StatefulWidget {
  final User user;
  final List students;
  final Classe classe;
  const CreateEncardreurConvocation(
      {Key? key,
      required this.user,
      required this.students,
      required this.classe})
      : super(key: key);

  @override
  State<CreateEncardreurConvocation> createState() =>
      _CreateEncardreurConvocationState();
}

class _CreateEncardreurConvocationState
    extends State<CreateEncardreurConvocation> {
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
        value: "Insubordination", child: Text('Insurbodination')));
    ListMotifs.add(DropdownMenuItem(
        value: "Retard Abusive", child: Text('Retard Abusive')));
    ListMotifs.add(
        DropdownMenuItem(value: "Violence", child: Text('Violence')));
    ListMotifs.add(
        DropdownMenuItem(value: "Indiscipline", child: Text('Indiscipline')));
    ListMotifs.add(DropdownMenuItem(value: "Autre", child: Text('Autre')));
    return ListMotifs;
  }

  Future<List<DropdownMenuItem>> courses() {
    ListCourses.clear();
    Future<List<DropdownMenuItem>> all_class_courses =
        CourseServices.getClassCourses(widget.classe.CodeClasse)
            .then((all_class_courses) {
      // print("length : $all_class_courses.length");
      for (var i = 0; i < all_class_courses.length; i++) {
        ListCourses.add(DropdownMenuItem(
          value: all_class_courses[i].CodeEnseignement.toString(),
          child: FutureBuilder<String>(
              future: CourseServices.getMainCourse(
                  all_class_courses[i].CodeMatiere),
              builder: (
                BuildContext context,
                AsyncSnapshot<String> snapshot,
              ) {
                if (snapshot.data == null) {
                  return const Text('loading ...');
                } else {
                  return Text(
                    snapshot.data ?? "",
                    style: const TextStyle(color: Colors.black),
                  );
                }
              }),
        ));
      }
      return ListCourses;
    });
    // print("list courses");
    print(all_class_courses);
    return all_class_courses;
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
    courses();
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
        actions: [
          IconButton(
              onPressed: () {
                BottomForm(context);
              },
              icon: const Icon(Icons.menu_open))
        ],
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
                        items: ListCourses,
                        value: course,
                        isExpanded: true,
                        onChanged: (value) {
                          course = value;
                          setState(() {
                            // print(year);
                            course = value;
                          });
                          // Navigator.push(context, MaterialPageRoute(builder: ((context) => SortedMarkListScreen(course: widget.course, sequence: sequence, year: year))));
                          // Navigator.pop(context);
                        },
                        elevation: 10,
                        hint: const Text('Matiere'),
                      ),
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
                        hint: const Text('Motif de convocation'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: TextField(
                        controller: description,
                        decoration: InputDecoration(
                          labelText: 'Description',
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
                                course == null ||
                                description.text == '' ||
                                date == 'Date de convocation') {
                              Fluttertoast.showToast(
                                  msg:
                                      "Assurez vous de remplir tous les champs",
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.BOTTOM,
                                  fontSize: 16.0);
                            } else {
                              for (int i = 0; i < widget.students.length; i++) {
                                AcademicServices.insertConvocation(
                                    widget.user.code,
                                    widget.students[i]['CodeEleve'],
                                    motif,
                                    description.text,
                                    course,
                                    date);
                              }
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

  Future<void> BottomForm(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          return Container(
            height: 300,
            width: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  color: CustomTheme.blue,
                  child: ListTile(
                    title: Text(
                      'Eleves qui seront convoqués',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // trailing: const Icon(Icons.arrow_forward_ios),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.students.length,
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
                              title: Text(widget.students[index]['name'],
                                  style: const TextStyle(fontSize: 13)),
                              subtitle: Text(
                                getGender(
                                    getGender(widget.students[index]['Sex'])),
                                style: const TextStyle(color: CustomTheme.blue),
                              ),
                              // trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      }),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
