// ignore_for_file: file_names, non_constant_identifier_names, prefer_const_constructors, import_of_legacy_library_into_null_safe, prefer_typing_uninitialized_variables, avoid_print

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/components/screens/teachers.dart/convocation_success.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/utils/custom_theme.dart';

class CreateConvocation extends StatefulWidget {
  final User user;
  final Student? student;
  final List<Student>? students;
  final String? codeClasse;
  final bool returnToList;

  const CreateConvocation({
    Key? key,
    required this.user,
    this.student,
    this.students,
    this.codeClasse,
    this.returnToList = false,
  }) : super(key: key);

  @override
  State<CreateConvocation> createState() => _CreateConvocationState();
}

class _CreateConvocationState extends State<CreateConvocation> {
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
  String date = '';
  var motif;
  final Set<String> _selectedStudentCodes = <String>{};
  bool _isSaving = false;

  List<DropdownMenuItem<String>> ListCourses = [];
  List<DropdownMenuItem<String>> ListMotifs = [];
  TextEditingController description = TextEditingController();

  List<DropdownMenuItem> motifs() {
    ListMotifs.clear();
    ListMotifs.add(DropdownMenuItem(
        value: "Insubordination", child: Text('Insurbodination')));
    ListMotifs.add(DropdownMenuItem(
        value: "Retards Abusive", child: Text('Retard Abusive')));
    ListMotifs.add(
        DropdownMenuItem(value: "Indiscipline", child: Text('Indiscipline')));
    ListMotifs.add(DropdownMenuItem(value: "Autre", child: Text('Autre')));
    return ListMotifs;
  }

  Future<List<DropdownMenuItem>> courses() {
    ListCourses.clear();
    final classCode = widget.codeClasse ?? widget.student?.CodeClasse;
    if (classCode == null || classCode.isEmpty) {
      return Future.value(List<DropdownMenuItem>.from(ListCourses));
    }
    Future<List<DropdownMenuItem>> all_class_courses =
        CourseServices.getTeacherCourses(widget.user.code)
            .then((teacherCourses) {
      final all_class_courses = teacherCourses
          .where((course) => course.CodeClasse == classCode)
          .toList();
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
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        date = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final initialStudents = widget.students != null
        ? <Student>[]
        : (widget.student == null ? <Student>[] : [widget.student!]);
    _selectedStudentCodes.addAll(
      initialStudents.map((student) => student.CodeEleve),
    );
    courses().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    motifs();
  }

  List<Student> get _availableStudents =>
      widget.students ??
      (widget.student == null ? <Student>[] : [widget.student!]);

  Future<void> _selectStudents() async {
    final searchController = TextEditingController();
    final selected = await showModalBottomSheet<List<Student>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = searchController.text.trim().toLowerCase();
          final filteredStudents = _availableStudents.where((student) {
            final name = '${student.Nom} ${student.Prenom}'.toLowerCase();
            return query.isEmpty || name.contains(query);
          }).toList();

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text('Sélectionner les élèves'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Rechercher par nom',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedStudentCodes.length} / ${_availableStudents.length} élèves sélectionnés',
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              if (_selectedStudentCodes.length ==
                                  _availableStudents.length) {
                                _selectedStudentCodes.clear();
                              } else {
                                _selectedStudentCodes.addAll(_availableStudents
                                    .map((student) => student.CodeEleve));
                              }
                            });
                          },
                          child: Text(
                            _selectedStudentCodes.length ==
                                    _availableStudents.length
                                ? 'Tout désélectionner'
                                : 'Tout sélectionner',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: filteredStudents.map((student) {
                        return CheckboxListTile(
                          value:
                              _selectedStudentCodes.contains(student.CodeEleve),
                          title: Text('${student.Nom} ${student.Prenom}'),
                          onChanged: (checked) {
                            setSheetState(() {
                              if (checked == true) {
                                _selectedStudentCodes.add(student.CodeEleve);
                              } else {
                                _selectedStudentCodes.remove(student.CodeEleve);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          _availableStudents
                              .where((student) => _selectedStudentCodes
                                  .contains(student.CodeEleve))
                              .toList(),
                        ),
                        child: const Text('Continuer'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    searchController.dispose();
    if (selected != null && mounted) {
      setState(() {});
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
          "Convocation",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: CustomTheme.cardShadow),
              child: ListTile(
                leading:
                    Image(image: AssetImage('assets/images/avatar-s-19.jpg')),
                title: Text(
                  _selectedStudentCodes.isEmpty
                      ? '0 / ${_availableStudents.length} élèves sélectionnés'
                      : '${_selectedStudentCodes.length} / ${_availableStudents.length} élèves sélectionnés',
                ),
                subtitle: const Text('Sélectionner les élèves',
                    style: TextStyle(
                      color: CustomTheme.blue,
                    )),
                onTap: () {
                  _selectStudents();
                },
              ),
            ),
          ),
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
                      title: Text(date.isEmpty ? 'Date de convocation' : date),
                      onTap: () {
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
                          // border: OutlineInputBorder(),
                        ),
                        maxLines: 5, // <-- SEE HERE
                        minLines: 3, // <-- SEE HERE
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 17, right: 17, top: 30),
                      child: CustomButton(
                        text: "Convoquer",
                        loading: _isSaving,
                        onPress: () {
                          if (motif == null ||
                              course == null ||
                              description.text == '' ||
                              date.isEmpty ||
                              _selectedStudentCodes.isEmpty) {
                            Fluttertoast.showToast(
                              msg:
                                  "Sélectionnez au moins un élève et remplissez tous les champs",
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              fontSize: 16.0,
                            );
                          } else {
                            _saveConvocation();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConvocation() async {
    if (_isSaving || _selectedStudentCodes.isEmpty) return;
    final studentCodes = List<String>.from(_selectedStudentCodes);
    if (studentCodes.isEmpty) return;
    setState(() {
      _isSaving = true;
    });
    final result = await AcademicServices.insertConvocations(
      widget.user.code,
      studentCodes,
      motif,
      description.text,
      course,
      date,
      codeClasse: widget.codeClasse ?? _availableStudents.first.CodeClasse,
    );
    if (!mounted) return;
    final success = result.toLowerCase().contains('success');
    setState(() {
      _isSaving = false;
    });
    if (widget.returnToList && success) {
      Fluttertoast.showToast(msg: 'Convocation enregistrée avec succès');
      Navigator.pop(context, true);
      return;
    }
    if (!success) {
      Fluttertoast.showToast(
        msg: 'Échec de l’enregistrement. Vérifiez les champs et réessayez.',
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }
    if (!widget.returnToList) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConvocationSuccess(user: widget.user),
        ),
      );
    }
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }
}
