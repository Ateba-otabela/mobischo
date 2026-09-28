// ignore_for_file: file_names

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/models/class.dart';
import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/students/student_detail.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';

class ClassStudents extends StatefulWidget {
  final Classe classe;
  final User user;
  final bool embedded;

  const ClassStudents({
    Key? key,
    required this.classe,
    required this.user,
    this.embedded = false,
  }) : super(key: key);

  @override
  State<ClassStudents> createState() => _ClassStudentsState();
}

class _ClassStudentsState extends State<ClassStudents> {
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = StudentServices.getCourseStudents(
      widget.classe.CodeClasse,
      code: widget.user.code,
      codeEtablissement: widget.user.CodeEtablissement,
    );
  }

  @override
  void didUpdateWidget(covariant ClassStudents oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classe.CodeClasse != widget.classe.CodeClasse) {
      _studentsFuture = StudentServices.getCourseStudents(
        widget.classe.CodeClasse,
        code: widget.user.code,
        codeEtablissement: widget.user.CodeEtablissement,
      );
    }
  }

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
    final normalized = sex.trim().toLowerCase();
    if (normalized == '1' || normalized == 'm' || normalized == 'masculin') {
      return "Masculin";
    }
    if (normalized == '0' || normalized == 'f' || normalized == 'feminin') {
      return "Féminin";
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<List<Student>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Impossible de charger les élèves.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _studentsFuture = StudentServices.getCourseStudents(
                        widget.classe.CodeClasse);
                  }),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final students = (snapshot.data ?? <Student>[])
          .where((student) => student.CodeClasse == widget.classe.CodeClasse)
          .toList();
        if (students.isEmpty) {
          return const Center(child: Text('Aucun élève dans cette classe.'));
        }

        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: ListTile(
                  leading: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/avatar-s-19.jpg'),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  title: Text(
                    '${student.Nom} ${student.Prenom}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    getGender(student.Sex),
                    style: const TextStyle(color: CustomTheme.blue),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    if (isLoaded) _interstitialAd?.show();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailScreen(
                          user: widget.user,
                          student: student,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );

    if (widget.embedded) {
      return Container(color: CustomTheme.grey, child: content);
    }

    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text('Élèves', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: content,
    );
  }
}
