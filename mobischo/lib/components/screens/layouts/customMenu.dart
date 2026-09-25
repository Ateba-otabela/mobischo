// ignore_for_file: unrelated_type_equality_checks, avoid_print, file_names

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/encardreur/EncardreurconvocationList.dart';
import 'package:mobischo/components/screens/encardreur/StudentClassList.dart';
import 'package:mobischo/components/screens/encardreur/classList.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/MyAccount.dart';
import 'package:mobischo/components/screens/layouts/sidebar.dart';
import 'package:mobischo/components/screens/parent/MyChildren.dart';
import 'package:mobischo/components/screens/parent/MyChildrenAbsences.dart';
import 'package:mobischo/components/screens/parent/MyChildrenNotes.dart';
import 'package:mobischo/components/screens/parent/SchoolAdvertScreen.dart';
import 'package:mobischo/components/screens/teachers.dart/absences.dart';
import 'package:mobischo/components/screens/courses/courses_list.dart';
import 'package:mobischo/components/screens/teachers.dart/marks.dart';
import 'package:mobischo/components/screens/teachers.dart/convocation_detail.dart';
import 'package:mobischo/components/screens/users/user_list.dart';
import 'package:mobischo/landing.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/utils/custom_theme.dart';

class CustomMenu extends StatefulWidget {
  final User user;
  final int selectedPage;
  final Widget? initialBody;
  final List<Widget>? principalScreens;
  final List<String>? principalTitles;
  final List<Widget>? principalIcons;
  final List<Widget>? principalSecondaryScreens;
  final List<String>? principalSecondaryTitles;

  const CustomMenu({
    Key? key,
    required this.user,
    required this.selectedPage,
    this.initialBody,
    this.principalScreens,
    this.principalTitles,
    this.principalIcons,
    this.principalSecondaryScreens,
    this.principalSecondaryTitles,
  }) : super(key: key);

  @override
  State<CustomMenu> createState() => _CustomMenuState();
}

class _CustomMenuState extends State<CustomMenu>
    with SingleTickerProviderStateMixin {
  late TabController _tcontroller;

  final List<String> admintitleList = [
    "MOBISCHO",
    "UTILISATEURS",
    "NOTES",
    "MON COMPTE"
  ];
  final List<String> teachertitleList = [
    "MOBISCHO",
    "REGISTRE D'APPEL",
    "NOTES",
    "MATIERES"
  ];

  final List<String> parenttitleList = [
    "MOBISCHO",
    "ABSENCES",
    "MES ENFANTS",
    "NOTES",
  ];

  final List<String> encardreurTitleList = [
    "MOBISCHO",
    "CONVOQUER",
    "CONVOCATIONS",
    "ELEVES",
  ];

  late String currentTitle;
  late int currentIndex = 0;
  bool showingInitialBody = true;
  Widget? principalSecondaryBody;

  @override
  void initState() {
    if (currentIndex != widget.selectedPage) {
      setState(() {
        currentIndex = widget.selectedPage;
      });
    }

    if (widget.initialBody is SchoolAdvertScreen) {
      currentTitle = 'École / Université';
      currentIndex = 0;
      showingInitialBody = true;
    } else if (widget.user.admin == '1') {
      currentTitle = admintitleList[0];
    } else {
      if (widget.user.account_type == 'parent') {
        currentTitle = parenttitleList[0];
      } else if (widget.user.account_type == 'principal_encadreur') {
        currentTitle = widget.principalTitles![0];
      } else {
        if (widget.user.account_type == 'encardreur') {
          currentTitle = encardreurTitleList[0];
        } else {
          currentTitle = teachertitleList[0];
        }
      }
    }
    _tcontroller = TabController(
        length: widget.user.account_type == 'principal_encadreur'
            ? widget.principalTitles!.length
            : 4,
        vsync: this);
    _tcontroller.addListener(changeTitle);
    // Registering listener
    _tcontroller.index = widget.selectedPage;
    super.initState();
  }

  // This function is called, every time active tab is changed
  void changeTitle() {
    setState(() {
      if (widget.initialBody is SchoolAdvertScreen) {
        currentTitle = 'École / Université';
        return;
      }

      // get index of active tab & change current appbar title
      if (widget.user.admin == '1') {
        currentTitle = admintitleList[currentIndex];
      } else {
        if (widget.user.account_type == 'parent') {
          currentTitle = parenttitleList[currentIndex];
        } else if (widget.user.account_type == 'principal_encadreur') {
          currentTitle = widget.principalTitles![currentIndex];
        } else {
          if (widget.user.account_type == 'encardreur') {
            currentTitle = encardreurTitleList[currentIndex];
          } else {
            currentTitle = teachertitleList[currentIndex];
          }
        }
      }
    });
  }

  _tabBarIcons() {
    if (widget.user.account_type == 'principal_encadreur') {
      return widget.principalIcons!;
    } else if (widget.user.admin == '1') {
      final items = <Widget>[
        const Icon(Icons.home),
        const Icon(Icons.person_outlined),
        const Icon(Icons.list_alt),
        const Icon(Icons.edit),
      ];
      return items;
    } else {
      if (widget.user.account_type == 'parent') {
        final items = <Widget>[
          const Icon(Icons.home),
          const Icon(Icons.timer),
          const Icon(Icons.person),
          const Icon(Icons.note_add_rounded),
        ];
        return items;
      } else {
        if (widget.user.account_type == 'encardreur') {
          final items = <Widget>[
            const Icon(Icons.home),
            const Icon(Icons.message),
            const Icon(Icons.list_alt_sharp),
            const Icon(Icons.person)
          ];
          return items;
        } else {
          final items = <Widget>[
            const Icon(Icons.home),
            const Icon(Icons.timer),
            const Icon(Icons.note_add_outlined),
            const Icon(Icons.menu_book),
          ];
          return items;
        }
      }
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

  void _restoreDashboardShell() {
    if (widget.initialBody is! SchoolAdvertScreen) {
      Navigator.of(context).pop();
      return;
    }

    if (widget.initialBody is ConvocationDetail) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      showingInitialBody = false;
      currentIndex = 0;
      changeTitle();
    });
  }

  void _restorePrincipalSecondary() {
    setState(() {
      principalSecondaryBody = null;
      currentTitle = widget.principalTitles![currentIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    var screens = [];
    if (widget.user.account_type == 'principal_encadreur') {
      screens = widget.principalScreens ?? [];
    } else if (widget.user.admin == '1') {
      setState(() {
        screens = [
          landingScreen(user: widget.user),
          const UsersScreen(),
          MarkScreen(
            user: widget.user,
          ),
          MyAccount(
            user: widget.user,
          )
        ];
      });
    } else {
      if (widget.user.account_type == 'parent') {
        setState(() {
          screens = [
            landingScreen(user: widget.user),
            MyChildrenAbsences(
              user: widget.user,
            ),
            MyChildren(
              user: widget.user,
            ),
            MyChildrenNotes(
              user: widget.user,
            ),
          ];
        });
      } else {
        if (widget.user.account_type == 'encardreur') {
          setState(() {
            screens = [
              landingScreen(user: widget.user),
              ClassListScreen(user: widget.user),
              EncardreurConvocationList(user: widget.user),
              StudentClassListScreen(user: widget.user),
            ];
          });
        } else {
          setState(() {
            screens = [
              landingScreen(user: widget.user),
              AbsencesScreen(
                user: widget.user,
              ),
              MarkScreen(
                user: widget.user,
              ),
              CoursesScreen(user: widget.user)
            ];
          });
        }
      }
    }

    return WillPopScope(
      onWillPop: () async {
        if (principalSecondaryBody != null) {
          _restorePrincipalSecondary();
          return false;
        }
        if (widget.initialBody is SchoolAdvertScreen && showingInitialBody) {
          _restoreDashboardShell();
          return false;
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          // elevation: 0,
          leading: ((widget.initialBody is SchoolAdvertScreen ||
                      widget.initialBody is ConvocationDetail) &&
                  showingInitialBody)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _restoreDashboardShell,
                )
              : principalSecondaryBody != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _restorePrincipalSecondary,
                    )
                  : null,
          title: Text(
            (widget.initialBody is SchoolAdvertScreen && showingInitialBody)
                ? 'École / Université'
                : (widget.initialBody is ConvocationDetail &&
                        showingInitialBody)
                    ? 'Convocation'
                    : currentTitle,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          iconTheme: const IconThemeData(color: CustomTheme.blue),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Image(
                image: AssetImage('assets/images/icon.png'),
                width: 40,
                height: 40,
              ),
            ),
          ],
        ),

        backgroundColor: CustomTheme.grey,
        // bottomNavigationBar: _tabBarIcons(),
        body: showingInitialBody && widget.initialBody != null
            ? widget.initialBody!
            : principalSecondaryBody ?? screens[currentIndex],

        bottomNavigationBar: Theme(
          data: Theme.of(context)
              .copyWith(iconTheme: const IconThemeData(color: Colors.white)),
          child: CurvedNavigationBar(
            items: _tabBarIcons(),
            index: currentIndex,
            backgroundColor: Colors.transparent,
            color: CustomTheme.blue,
            height: 60,
            buttonBackgroundColor: CustomTheme.blue,
            onTap: (index) {
              if (isLoaded == true) {
                _interstitialAd!.show();
              }
              setState(() {
                showingInitialBody = false;
                principalSecondaryBody = null;
                currentIndex = index;

                changeTitle();
              });
            },
          ),
        ),

        drawer: Drawer(
          child: SideBarMenu(
            user: widget.user,
            principalTitles: widget.principalSecondaryTitles,
            principalScreens: widget.principalSecondaryScreens,
            onPrincipalSelect: (screen) {
              if (!mounted) return;
              final secondaryIndex =
                  widget.principalSecondaryScreens?.indexOf(screen) ?? -1;
              setState(() {
                principalSecondaryBody = screen;
                currentTitle = secondaryIndex >= 0 &&
                        widget.principalSecondaryTitles != null
                    ? widget.principalSecondaryTitles![secondaryIndex]
                    : currentTitle;
              });
            },
          ),
        ),
      ),
    );
  }
}
