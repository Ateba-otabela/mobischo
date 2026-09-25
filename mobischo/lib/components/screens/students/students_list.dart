import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/students/student_detail.dart';
import 'package:mobischo/models/course.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class StudentListScreen extends StatefulWidget {
  final String listType;
  final Course course;
  final User user;
  const StudentListScreen(
      {Key? key,
      required this.listType,
      required this.course,
      required this.user})
      : super(key: key);

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
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

  @override
  Widget build(BuildContext context) {
    if (widget.listType == 'course_students') {
      return Scaffold(
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
          title: Text('LISTE DES ELEVES',
              style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
        ),
        body: Center(
          child: FutureBuilder(
            future: StudentServices.getCourseStudents(widget.course.CodeClasse),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return Container(
                  color: CustomTheme.grey,
                  child: ListView.builder(
                      itemCount: snapshot.data.length,
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
                              title: Text(
                                  "${snapshot.data[index].Nom} ${snapshot.data[index].Prenom}",
                                  style: const TextStyle(fontSize: 13)),
                              subtitle: Text(
                                getGender(snapshot.data[index].Sex),
                                style: const TextStyle(color: CustomTheme.blue),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                if (isLoaded == true) {
                                  _interstitialAd!.show();
                                }
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: ((context) =>
                                            StudentDetailScreen(
                                                user: widget.user,
                                                student:
                                                    snapshot.data[index]))));
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
      );
    } else {
      return const Center(
        child: Text("Liste des eleves"),
      );
    }
  }
}
