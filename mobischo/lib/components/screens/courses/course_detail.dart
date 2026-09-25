// ignore_for_file: unnecessary_import, implementation_imports, sort_child_properties_last, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/students/students_list.dart';
import 'package:mobischo/components/screens/teachers.dart/absences_list.dart';
import 'package:mobischo/components/screens/teachers.dart/mark_lists.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/school.dart';
// ignore: unused_import
import 'package:mobischo/services/services.dart';
import 'package:mobischo/utils/custom_theme.dart';

import '../../../services/courses.dart';
import '../../../utils/custom_theme.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final User user;
  const CourseDetailScreen({Key? key, required this.course, required this.user})
      : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
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
            //             _numInterstitialLoadAttempts += 1;
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
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              BottomForm(context);
            },
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
          )
        ],
        centerTitle: true,
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
                  snapshot.data ?? "",
                  style: Theme.of(context).textTheme.titleLarge,
                );
              }
            }),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: Text(widget.course.CodeEnseignement),
            subtitle: const Text('Code Enseignement'),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future: CourseServices.getMainCourse(widget.course.CodeMatiere),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return const Text('Loading ...');
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: const Text('Matiere'),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: FutureBuilder<String>(
              future: CourseServices.getMainClass(widget.course.CodeClasse),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return const Text('Loading ...');
                } else {
                  return Text(snapshot.data ?? "");
                }
              },
            ),
            subtitle: const Text('Matiere'),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
            title: Text(widget.course.Coefficient.trim().isEmpty
                ? 'Non renseigné'
                : widget.course.Coefficient),
            subtitle: const Text("Coefficient"),
          ),
          ListTile(
            leading: const Icon(Icons.timer, color: CustomTheme.blue),
            title: Text(widget.course.NBRHEURE.trim().isEmpty
                ? 'Non renseigné'
                : widget.course.NBRHEURE),
            subtitle: const Text("Nombre D'Heures"),
          ),
          ListTile(
              leading: const Icon(Icons.menu_book, color: CustomTheme.blue),
              title: FutureBuilder<String>(
                future: SchoolServices.getMainSchool('11201'),
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.data == null) {
                    return const Text('Loading ...');
                  } else {
                    return Text(snapshot.data ?? "");
                  }
                },
              ),
              subtitle: const Text("Etablissement"))
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
            height: 230,
            width: double.infinity,
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(
                      Icons.menu_book,
                      color: CustomTheme.blue,
                    ),
                    title: const Text('Notes'),
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
                                  MarkListScreen(course: widget.course))));
                    },
                  ),
                  const Divider(
                      // height: 1,
                      ),
                  ListTile(
                    leading: const Icon(Icons.timer, color: CustomTheme.blue),
                    title: const Text('Absences'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => AbsenceListScreen(
                                  course: widget.course, user: widget.user))));
                    },
                  ),
                  const Divider(
                      // height: 1,
                      ),
                  ListTile(
                    leading: const Icon(Icons.inventory_outlined,
                        color: CustomTheme.blue),
                    title: const Text("Liste d'Eleves"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => StudentListScreen(
                                  listType: 'course_students',
                                  user: widget.user,
                                  course: widget.course))));
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
