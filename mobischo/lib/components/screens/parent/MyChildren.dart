// ignore_for_file: file_names, non_constant_identifier_names

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/parent/allStudentAbsences.dart';
import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/parent/MyChildrenInscription.dart';
import 'package:mobischo/components/screens/parent/MyChildrenNotes.dart';
import 'package:mobischo/components/screens/students/StudentCourseList.dart';
import 'package:mobischo/components/screens/students/student_detail.dart';
import 'package:mobischo/models/inscription.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/services/inscription_services.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

enum MyChildrenOrigin { notes, scolarite }

class MyChildren extends StatefulWidget {
  final User user;
  final MyChildrenOrigin origin;

  const MyChildren({
    Key? key,
    required this.user,
    this.origin = MyChildrenOrigin.scolarite,
  }) : super(key: key);

  @override
  State<MyChildren> createState() => _MyChildrenState();
}

class _MyChildrenState extends State<MyChildren> {
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

  Student? selectedStudent;
  Inscription? selectedInscription;

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

  @override
  Widget build(BuildContext context) {
    if (widget.origin == MyChildrenOrigin.notes && selectedStudent != null) {
      return MyChildrenNotes(
        user: widget.user,
        initialStudent: selectedStudent,
        onBack: () => setState(() {
          selectedStudent = null;
        }),
      );
    }

    if (selectedStudent != null && selectedInscription != null) {
      return _buildInscriptionDetailContent();
    }

    if (selectedStudent != null) {
      return _buildSelectedChildContent();
    }

    return Container(
      color: CustomTheme.grey,
      child: Center(
        child: FutureBuilder(
          future: StudentServices.getParentStudents(widget.user.code),
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
                            image: AssetImage('assets/images/welcome.png')),
                        title: Text(
                          "Cliquez sur un enfant pour plus de details",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: CustomTheme.grey,
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data.length,
                          itemBuilder: (BuildContext context, int index) {
                            final student = snapshot.data[index];
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
                                  title: Text(getStudentDisplayName(student),
                                      style: const TextStyle(fontSize: 13)),
                                  subtitle: Text(
                                    getGender(student.Sex),
                                    style: const TextStyle(
                                        color: CustomTheme.blue),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    setState(() {
                                      selectedStudent = student;
                                      selectedInscription = null;
                                    });
                                  },
                                ),
                              ),
                            );
                          }),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSelectedChildContent() {
    return Container(
      color: CustomTheme.grey,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedStudent = null;
                        selectedInscription = null;
                      });
                    },
                    icon: const Icon(Icons.arrow_back_ios,
                        color: CustomTheme.blue),
                  ),
                  Expanded(
                    child: Text(
                      getStudentDisplayName(selectedStudent!),
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Inscription>>(
                future: InscriptionServices.getStudentInscription(
                  selectedStudent!.CodeEleve,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final inscriptions = snapshot.data ?? <Inscription>[];
                  if (inscriptions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/money.png',
                              height: 88,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              uiText(context, 'noEnrollmentYet'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF424242),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              uiText(context, 'enrollmentDetailsWillAppear'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF757575),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    itemCount: inscriptions.length,
                    itemBuilder: (context, index) {
                      final inscription = inscriptions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedInscription = inscription;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_outlined,
                                          color: CustomTheme.blue),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Inscription',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'N° RECU : ${inscription.NUMFAC}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Date de paiement : ${inscription.DateInscription}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInscriptionDetailContent() {
    final inscription = selectedInscription!;

    return Container(
      color: CustomTheme.grey,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedInscription = null;
                      });
                    },
                    icon: const Icon(Icons.arrow_back_ios,
                        color: CustomTheme.blue),
                  ),
                  const Text(
                    '← Retour',
                    style: TextStyle(
                      color: CustomTheme.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  ListTile(
                    leading: const Icon(Icons.inventory_outlined,
                        color: CustomTheme.blue),
                    title: Text(inscription.NUMFAC),
                    subtitle: Text(uiText(context, 'invoiceNumber')),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.menu_book, color: CustomTheme.blue),
                    title: Text(inscription.libinscrip),
                    subtitle: Text(uiText(context, 'registrationLabel')),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.menu_book, color: CustomTheme.blue),
                    title: Text(inscription.Tranche),
                    subtitle: Text(uiText(context, 'installment')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person, color: CustomTheme.blue),
                    title: FutureBuilder<String>(
                      future:
                          StudentServices.getMainStudent(inscription.CodeEleve),
                      builder: (context, snapshot) {
                        if (snapshot.data == null) {
                          return Text(uiText(context, 'loadingEllipsis'));
                        }
                        return Text(snapshot.data ?? '');
                      },
                    ),
                    subtitle: Text(uiText(context, 'studentName')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.monetization_on_sharp,
                        color: CustomTheme.blue),
                    title: Text('${inscription.Montantins} FCFA'),
                    subtitle: Text(uiText(context, 'registrationAmount')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.monetization_on_rounded,
                        color: CustomTheme.blue),
                    title: Text('${inscription.Avance} FCFA'),
                    subtitle: Text(uiText(context, 'advance')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.monetization_on_outlined,
                        color: CustomTheme.blue),
                    title: Text('${inscription.Reste} FCFA'),
                    subtitle: Text(uiText(context, 'remaining')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.monetization_on,
                        color: CustomTheme.blue),
                    title: Text('${inscription.Montantt} FCFA'),
                    subtitle: Text(uiText(context, 'totalAmount')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month,
                        color: CustomTheme.blue),
                    title: Text(inscription.DateInscription),
                    subtitle: Text(uiText(context, 'enrollmentDate')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> BottomForm(BuildContext context, Student student) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          return Container(
            height: 280,
            width: double.infinity,
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.person, color: CustomTheme.blue),
                    title: Text(uiText(context, 'details')),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => StudentDetailScreen(
                                    student: student,
                                    user: widget.user,
                                  ))));
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.menu_book, color: CustomTheme.blue),
                    title: Text(uiText(context, 'notes')),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => StudentCoursesScreen(
                                    student: student,
                                    user: widget.user,
                                  ))));
                    },
                  ),
                  const Divider(
                      // height: 1,
                      ),
                  ListTile(
                    leading: const Icon(Icons.timer, color: CustomTheme.blue),
                    title: Text(uiText(context, 'absences')),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => AllStudentAbsences(
                                    student: student,
                                    user: widget.user,
                                  ))));
                    },
                  ),
                  const Divider(
                      // height: 1,
                      ),
                  ListTile(
                    leading: const Icon(Icons.inventory_outlined,
                        color: CustomTheme.blue),
                    title: Text(uiText(context, 'enrollmentHistory')),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => MyChildrenInscriptions(
                                    user: widget.user,
                                    student: student,
                                  ))));
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
