// ignore_for_file: file_names, non_constant_identifier_names, prefer_const_constructors, import_of_legacy_library_into_null_safe, prefer_typing_uninitialized_variables, avoid_print

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:mobischo/l10n/ui_text.dart';

class CreateConvocation extends StatefulWidget {
  final User user;
  final Student? student;
  final List<Student>? students;
  final List<String>? initialStudentCodes;
  final String? codeClasse;
  final String? appBarTitle;
  final bool returnToList;
  final bool useClassCourses;

  const CreateConvocation({
    Key? key,
    required this.user,
    this.student,
    this.students,
    this.initialStudentCodes,
    this.codeClasse,
    this.appBarTitle,
    this.returnToList = false,
    this.useClassCourses = false,
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
  bool _isPickingAttachment = false;
  Uint8List? _attachmentBytes;
  String? _attachmentName;

  static const _maxAttachmentSize = 10 * 1024 * 1024;

  List<DropdownMenuItem<String>> ListCourses = [];
  List<DropdownMenuItem<String>> ListMotifs = [];
  TextEditingController description = TextEditingController();

  List<DropdownMenuItem> motifs() {
    ListMotifs.clear();
    ListMotifs.add(DropdownMenuItem(
        value: "Insubordination",
        child: Text(uiText(context, 'insubordination'))));
    ListMotifs.add(DropdownMenuItem(
        value: "Retards Abusive",
        child: Text(uiText(context, 'excessiveLateness'))));
    ListMotifs.add(DropdownMenuItem(
        value: "Indiscipline", child: Text(uiText(context, 'indiscipline'))));
    ListMotifs.add(DropdownMenuItem(
        value: "Autre", child: Text(uiText(context, 'otherReason'))));
    return ListMotifs;
  }

  Future<List<DropdownMenuItem>> courses() {
    ListCourses.clear();
    final classCode = widget.codeClasse ?? widget.student?.CodeClasse;
    if (classCode == null || classCode.isEmpty) {
      return Future.value(List<DropdownMenuItem>.from(ListCourses));
    }

    final availableCourses = widget.useClassCourses
        ? CourseServices.getClassCourses(classCode)
        : CourseServices.getTeacherCourses(widget.user.code);
    Future<List<DropdownMenuItem>> all_class_courses =
        availableCourses.then((courses) {
      final all_class_courses =
          courses.where((course) => course.CodeClasse == classCode).toList();
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
                  return Text(uiText(context, 'loadingEllipsis'));
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

  Future<void> _pickAttachment() async {
    setState(() => _isPickingAttachment = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null) return;

      final file = result.files.single;
      if (file.bytes == null) {
        _showMessage(uiText(context, 'documentReadError'));
        return;
      }
      if (file.size > _maxAttachmentSize) {
        _showMessage(uiText(context, 'documentTooLarge'));
        return;
      }

      setState(() {
        _attachmentBytes = file.bytes;
        _attachmentName = file.name;
      });
    } on PlatformException catch (error) {
      debugPrint('Picking convocation attachment failed (${error.code}).');
      if (mounted) _showMessage(uiText(context, 'documentSelectError'));
    } on Exception catch (error) {
      debugPrint(
          'Picking convocation attachment failed (${error.runtimeType}).');
      if (mounted) _showMessage(uiText(context, 'documentSelectError'));
    } finally {
      if (mounted) setState(() => _isPickingAttachment = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      widget.initialStudentCodes ??
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
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(uiText(context, 'selectStudents')),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        labelText: uiText(context, 'searchByName'),
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
                          uiText(context, 'selectedStudentsCount', parameters: {
                            'selected': '${_selectedStudentCodes.length}',
                            'total': '${_availableStudents.length}',
                          }),
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
                                ? uiText(context, 'deselectAll')
                                : uiText(context, 'selectAll'),
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
                        child: Text(uiText(context, 'continueButton')),
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
          widget.appBarTitle ?? "Convocation",
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
                      ? uiText(context, 'selectedStudentsCount', parameters: {
                          'selected': '0',
                          'total': '${_availableStudents.length}',
                        })
                      : uiText(context, 'selectedStudentsCount', parameters: {
                          'selected': '${_selectedStudentCodes.length}',
                          'total': '${_availableStudents.length}',
                        }),
                ),
                subtitle: Text(uiText(context, 'selectStudents'),
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
                      title: Text(date.isEmpty
                          ? uiText(context, 'conveningDate')
                          : date),
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
                        hint: Text(uiText(context, 'subject')),
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
                        hint: Text(uiText(context, 'conveningReason')),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: TextField(
                        controller: description,
                        decoration: InputDecoration(
                          labelText: uiText(context, 'description'),
                          // border: OutlineInputBorder(),
                        ),
                        maxLines: 5, // <-- SEE HERE
                        minLines: 3, // <-- SEE HERE
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(17, 16, 17, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(uiText(context, 'optionalSupportingDocument')),
                          const SizedBox(height: 6),
                          if (_attachmentBytes == null)
                            OutlinedButton.icon(
                              onPressed:
                                  _isPickingAttachment ? null : _pickAttachment,
                              icon: _isPickingAttachment
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.attach_file),
                              label:
                                  Text(uiText(context, 'addDocumentOrPhoto')),
                            )
                          else
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.description_outlined),
                              title: Text(
                                _attachmentName ??
                                    uiText(context, 'selectedDocument'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                tooltip: uiText(context, 'deleteDocument'),
                                onPressed: () => setState(() {
                                  _attachmentBytes = null;
                                  _attachmentName = null;
                                }),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            uiText(context, 'fileSizeLimit'),
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 17, right: 17, top: 30),
                      child: CustomButton(
                        text: uiText(context, 'convoke'),
                        loading: _isSaving,
                        onPress: () {
                          if (motif == null ||
                              course == null ||
                              description.text == '' ||
                              date.isEmpty ||
                              _selectedStudentCodes.isEmpty) {
                            Fluttertoast.showToast(
                              msg: uiText(
                                  context, 'selectStudentAndCompleteFields'),
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
      documentBytes: _attachmentBytes,
      documentName: _attachmentName,
    );
    if (!mounted) return;
    final success = result.toLowerCase().contains('success');
    setState(() {
      _isSaving = false;
    });
    if (widget.returnToList && success) {
      Fluttertoast.showToast(msg: uiText(context, 'convocationSaved'));
      Navigator.pop(context, true);
      return;
    }
    if (!success) {
      Fluttertoast.showToast(
        msg: uiText(context, 'convocationSaveFailed'),
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
