// ignore_for_file: unrelated_type_equality_checks

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/MyAccount.dart';
import 'package:mobischo/components/screens/parent/MyChildrenAbsences.dart';
import 'package:mobischo/components/screens/parent/MyChildren.dart';
import 'package:mobischo/components/screens/parent/devoirs_messages.dart';
import 'package:mobischo/components/screens/parent/SchoolAdvertScreen.dart';
import 'package:mobischo/components/screens/teachers.dart/teacher_devoirs.dart';
import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/teachers.dart/TeacherConvocationList.dart';
import 'package:mobischo/home.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/courses.dart';
import 'package:mobischo/services/students_services.dart';
// ignore: unused_import
import 'package:mobischo/utils/custom_theme.dart';

class MainMenu extends StatefulWidget {
  final User user;
  const MainMenu({Key? key, required this.user}) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

int courseNum = 0;

class _MainMenuState extends State<MainMenu> {
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

  String title = '';

  @override
  void initState() {
    super.initState();
    CourseServices.getTeacherCourses(widget.user.code).then((courses) {
      setState(() {
        courseNum = courses.length;
        if (widget.user.account_type == 'enseignant') {
          title = "Nombre de Matieres";
        } else {
          title = "Nombre d'Enfants";
        }
      });
    });
    if (widget.user.account_type == 'parent') {
      StudentServices.getParentStudents(widget.user.code).then((students) {
        setState(() {
          courseNum = students.length;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.admin == '1') {
      return Container();
    }

    //parent landing page
    else {
      if (widget.user.account_type == 'enseignant') {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                            child: Container(
                          width: double.infinity,
                          height: 140,
                          padding: const EdgeInsets.all(1),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 10,
                            child: InkWell(
                              onTap: () {
                                if (isLoaded == true) {
                                  _interstitialAd!.show();
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Home(
                                            user: widget.user,
                                            selectedPage: 1,
                                          )),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  // ignore: prefer_const_constructors
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: const Image(
                                      image: AssetImage(
                                          'assets/images/landing2.png'),
                                      height: 36,
                                      width: double.infinity,
                                    ),
                                  ),
                                  ListTile(
                                    title: Text(
                                      "REGISTRE D'APPEL",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    subtitle: Text(
                                      'Ajoutez & Consultez',
                                      textAlign: TextAlign.center,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ))
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                            child: Container(
                          width: double.infinity,
                          height: 140,
                          padding: const EdgeInsets.all(1),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 10,
                            child: InkWell(
                              onTap: () {
                                if (isLoaded == true) {
                                  _interstitialAd!.show();
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          TeacherConvocationList(
                                              user: widget.user)),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Image(
                                        image: AssetImage(
                                            'assets/images/landing3.png'),
                                        height: 36,
                                        width: double.infinity),
                                  ),
                                  ListTile(
                                    title: Text(
                                      "MESSAGES",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    subtitle: const Text(
                                      'Messages aux parents',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ))
                      ],
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                            child: Container(
                          width: double.infinity,
                          height: 140,
                          padding: const EdgeInsets.all(1),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 10,
                            child: InkWell(
                              onTap: () {
                                if (isLoaded == true) {
                                  _interstitialAd!.show();
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Home(
                                            user: widget.user,
                                            selectedPage: 2,
                                          )),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Image(
                                      image: AssetImage(
                                          'assets/images/landing6.png'),
                                      height: 36,
                                      width: double.infinity,
                                    ),
                                  ),
                                  ListTile(
                                    title: Text(
                                      "NOTES",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    subtitle: Text(
                                      'Ajoutez & Consultez',
                                      textAlign: TextAlign.center,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ))
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                            child: Container(
                          width: double.infinity,
                          height: 140,
                          padding: const EdgeInsets.all(1),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 10,
                            child: InkWell(
                              onTap: () {
                                if (isLoaded == true) {
                                  _interstitialAd!.show();
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Home(
                                            user: widget.user,
                                            selectedPage: 3,
                                          )),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Image(
                                        image: AssetImage(
                                            'assets/images/landing5.png'),
                                        height: 36,
                                        width: double.infinity),
                                  ),
                                  ListTile(
                                    title: Text(
                                      'MATIERES',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    subtitle: const Text(
                                      'Consultez',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ))
                      ],
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: SizedBox(
                width: double.infinity,
                height: 140,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 10,
                  child: InkWell(
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Home(
                            user: widget.user,
                            selectedPage: 0,
                            initialBody:
                                TeacherDevoirsScreen(user: widget.user),
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Image(
                          image: AssetImage('assets/images/landing2.png'),
                          height: 36,
                          width: double.infinity,
                        ),
                        ListTile(
                          title: Text(
                            'DEVOIRS',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          subtitle: const Text(
                            'Ajoutez et consultez',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      } else {
        if (widget.user.account_type == 'parent') {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Container(
                            width: double.infinity,
                            height: 140,
                            padding: const EdgeInsets.all(1),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 10,
                              child: InkWell(
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Home(
                                              user: widget.user,
                                              selectedPage: 0,
                                              initialBody:
                                                  DevoirsMessagesScreen(
                                                user: widget.user,
                                                onBack: () =>
                                                    Navigator.of(context).pop(),
                                              ),
                                            )),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Image(
                                        image: AssetImage(
                                            'assets/images/landing2.png'),
                                        height: 36,
                                        width: double.infinity,
                                      ),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "DEVOIR & MESSAGE",
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      subtitle: Text(
                                        'Ajoutez & Consultez',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Container(
                            width: double.infinity,
                            height: 140,
                            padding: const EdgeInsets.all(1),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 10,
                              child: InkWell(
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Home(
                                        user: widget.user,
                                        selectedPage: 0,
                                        initialBody: MyChildrenAbsences(
                                          user: widget.user,
                                          embedded: true,
                                          onBack: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Image(
                                          image: AssetImage(
                                              'assets/images/landing3.png'),
                                          height: 36,
                                          width: double.infinity),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "RETARD ET ABSENCE",
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      subtitle: const Text(
                                        'consultez',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Container(
                            width: double.infinity,
                            height: 140,
                            padding: const EdgeInsets.all(1),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 10,
                              child: InkWell(
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Home(
                                              user: widget.user,
                                              selectedPage: 2,
                                              initialBody: MyChildren(
                                                user: widget.user,
                                                origin: MyChildrenOrigin.notes,
                                              ),
                                            )),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Image(
                                        image: AssetImage(
                                            'assets/images/landing6.png'),
                                        height: 36,
                                        width: double.infinity,
                                      ),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "NOTES",
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      subtitle: Text(
                                        'Consultez',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Container(
                            width: double.infinity,
                            height: 140,
                            padding: const EdgeInsets.all(1),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 10,
                              child: InkWell(
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Home(
                                              user: widget.user,
                                              selectedPage: 2,
                                              initialBody: MyChildren(
                                                user: widget.user,
                                                origin:
                                                    MyChildrenOrigin.scolarite,
                                              ),
                                            )),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Image(
                                          image: AssetImage(
                                              'assets/images/landing5.png'),
                                          height: 36,
                                          width: double.infinity),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "SCOLARITE",
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      subtitle: const Text(
                                        'Consultez',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(2),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: InkWell(
                        onTap: () {
                          if (isLoaded == true) {
                            _interstitialAd!.show();
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Home(
                                user: widget.user,
                                selectedPage: 0,
                                initialBody: SchoolAdvertScreen(
                                  userCode: widget.user.code,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 8),
                              child: Image(
                                image: AssetImage('assets/images/landing5.png'),
                                height: 40,
                                width: double.infinity,
                              ),
                            ),
                            Text(
                              'École / Université',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Découvrez les écoles, universités et opportunités de formation.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Container(
                            width: double.infinity,
                            height: 140,
                            padding: const EdgeInsets.all(1),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 10,
                              child: InkWell(
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Home(
                                              user: widget.user,
                                              selectedPage: 1,
                                            )),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Image(
                                        image: AssetImage(
                                            'assets/images/landing2.png'),
                                        height: 36,
                                        width: double.infinity,
                                      ),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "ENVOYER DES MESSAGES",
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      subtitle: Text(
                                        'Convoquez des parents',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Container(
                            width: double.infinity,
                            height: 140,
                            padding: const EdgeInsets.all(1),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 10,
                              child: InkWell(
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Home(
                                              user: widget.user,
                                              selectedPage: 2,
                                            )),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Image(
                                          image: AssetImage(
                                              'assets/images/landing3.png'),
                                          height: 36,
                                          width: double.infinity),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "CONSULTEZ DES MESSAGES",
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      subtitle: const Text(
                                        'Consultez les messages envoyees',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Container(
                            width: double.infinity,
                            height: 140,
                            padding: const EdgeInsets.all(1),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 10,
                              child: InkWell(
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Home(
                                              user: widget.user,
                                              selectedPage: 3,
                                            )),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Image(
                                        image: AssetImage(
                                            'assets/images/landing6.png'),
                                        height: 36,
                                        width: double.infinity,
                                      ),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "LISTE D'ELEVES",
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      subtitle: Text(
                                        'Consultez',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Container(
                            width: double.infinity,
                            height: 140,
                            padding: const EdgeInsets.all(1),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 10,
                              child: InkWell(
                                onTap: () {
                                  if (isLoaded == true) {
                                    _interstitialAd!.show();
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            MyAccount(user: widget.user)),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Image(
                                          image: AssetImage(
                                              'assets/images/landing5.png'),
                                          height: 36,
                                          width: double.infinity),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "MON COMPTE",
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      subtitle: const Text(
                                        'Consultez',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          );
        }
      }
    }
  }
}
