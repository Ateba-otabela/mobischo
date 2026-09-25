// ignore_for_file: camel_case_types, sort_child_properties_last, prefer_typing_uninitialized_variables, non_constant_identifier_names, file_names

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/teachers.dart/convocation_detail.dart';
import 'package:mobischo/components/screens/teachers.dart/CreateConvocation.dart';
import 'package:mobischo/models/class.dart';
import 'package:mobischo/models/convocation.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class TeacherConvocationList extends StatefulWidget {
  final User user;
  const TeacherConvocationList({Key? key, required this.user})
      : super(key: key);

  @override
  State<TeacherConvocationList> createState() => _TeacherConvocationListState();
}

class _TeacherConvocationListState extends State<TeacherConvocationList> {
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

  bool isLoaded = false;
  List<Classe> _classes = [];
  Classe? _selectedClass;
  List<Convocation> _convocations = [];
  bool _loadingClasses = true;
  bool _loadingConvocations = false;

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
    super.initState();
    sequences();
    years();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final courses = await CourseServices.getTeacherCourses(widget.user.code);
    final assignedCodes = courses.map((course) => course.CodeClasse).toSet();
    final allClasses = await AcademicServices.getAllClasses();
    if (!mounted) return;
    setState(() {
      _classes = allClasses
          .where(
              (schoolClass) => assignedCodes.contains(schoolClass.CodeClasse))
          .toList();
      _loadingClasses = false;
    });
  }

  Future<void> _selectClass(Classe? schoolClass) async {
    setState(() {
      _selectedClass = schoolClass;
      _convocations = [];
      _loadingConvocations = schoolClass != null;
    });
    if (schoolClass == null) return;
    final convocations = await AcademicServices.getTeacherConvocation(
      widget.user.code,
      codeClasse: schoolClass.CodeClasse,
    );
    if (!mounted || _selectedClass?.CodeClasse != schoolClass.CodeClasse) {
      return;
    }
    setState(() {
      _convocations = convocations;
      _loadingConvocations = false;
    });
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
              // color: CustomTheme.blue,
            )),
        title: Text(
          'MESSAGES AUX PARENTS',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //       onPressed: () {
        //         BottomForm(context);
        //       },
        //       icon: const Icon(
        //         Icons.more_vert,
        //       ))
        // ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: _loadingClasses
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<Classe>(
                    value: _selectedClass,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Classe',
                      border: OutlineInputBorder(),
                    ),
                    items: _classes
                        .map((schoolClass) => DropdownMenuItem<Classe>(
                              value: schoolClass,
                              child: Text(schoolClass.LibelleClasse),
                            ))
                        .toList(),
                    onChanged: _selectClass,
                  ),
          ),
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
                                title: const Text('Eleves Convoques'),
                                subtitle:
                                    const Text('Cliquez pour plus de details'),
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
          Flexible(
            child: _selectedClass == null
                ? const Center(child: Text('Sélectionnez une classe.'))
                : _loadingConvocations
                    ? const Center(child: CircularProgressIndicator())
                    : _convocations.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_available_outlined,
                                    size: 48,
                                    color: CustomTheme.blue,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucune convocation pour cette classe pour le moment.',
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Vous pouvez créer une nouvelle convocation avec le bouton +.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : convocationList(
                            widget: widget,
                            convocations: _convocations,
                          ),
          ),
        ],
      ),
      floatingActionButton: _selectedClass == null
          ? null
          : FloatingActionButton(
              onPressed: _openCreateConvocation,
              backgroundColor: CustomTheme.blue,
              child: const Icon(Icons.add),
            ),
    );
  }

  Future<void> _openCreateConvocation() async {
    final selectedClass = _selectedClass;
    if (selectedClass == null) return;
    final students = await StudentServices.getCourseStudents(
      selectedClass.CodeClasse,
    );

    if (!mounted) return;
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun élève disponible.')),
      );
      return;
    }

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateConvocation(
          user: widget.user,
          students: students,
          codeClasse: selectedClass.CodeClasse,
          returnToList: true,
        ),
      ),
    );
    if (saved == true && mounted) {
      _selectClass(selectedClass);
    }
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
                              // Navigator.push(context, MaterialPageRoute(builder: ((context) => SortedTeacherConvocationList(course: widget.course, sequence: sequence, year: year))));
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
                            // Navigator.push(context, MaterialPageRoute(builder: ((context) => SortedTeacherConvocationList(course: widget.course, sequence: sequence, year: year))));
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
                          // Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: ((context) => SortedTeacherConvocationList(
                          //             course: widget.course,
                          //             sequence: sequence,
                          //             year: year))));
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

class convocationList extends StatelessWidget {
  final TeacherConvocationList widget;
  final List<Convocation> convocations;

  const convocationList({
    Key? key,
    required this.widget,
    required this.convocations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomTheme.grey,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: convocations.length,
        itemBuilder: (BuildContext context, int index) {
          final convocation = convocations[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                title: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FutureBuilder<String>(
                        future: StudentServices.getMainStudent(
                          convocation.CodeEleve,
                        ),
                        builder: (context, snapshot) {
                          return Text(snapshot.data ?? 'loading ...');
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(convocation.dateConvocation),
                    ),
                  ],
                ),
                children: [
                  ListTile(
                    title: Text(
                      'Convoqué le ${convocation.dateConvocation} pour ${convocation.motif}',
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConvocationDetail(
                            convocation: convocation,
                            user: widget.user,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('MESSAGE'),
                    subtitle: Text(convocation.description),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConvocationDetail(
                            convocation: convocation,
                            user: widget.user,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
