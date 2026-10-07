// ignore_for_file: unrelated_type_equality_checks, avoid_print, file_names

import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/components/screens/encardreur/EncardreurconvocationList.dart';
import 'package:mobischo/components/screens/encardreur/StudentClassList.dart';
import 'package:mobischo/components/screens/encardreur/classList.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mobischo/components/screens/notifications/notification_bell.dart';
import 'package:mobischo/components/screens/notifications/notification_list_screen.dart';
import 'package:mobischo/components/screens/mobischo_ai.dart';
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
import 'package:mobischo/services/notification_inbox_service.dart';
import 'package:mobischo/services/notification_service.dart';
import 'package:mobischo/utils/custom_theme.dart';

class PrincipalTabRequest extends Notification {
  final int index;

  PrincipalTabRequest(this.index);
}

class PrincipalSectionRequest extends Notification {
  final String title;
  final Widget screen;

  const PrincipalSectionRequest({required this.title, required this.screen});
}

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tcontroller;
  StreamSubscription? _notificationSubscription;
  int _unreadNotificationCount = 0;

  final List<String> admintitleList = [
    "MOBISCHO",
    "UTILISATEURS",
    "NOTES",
    "AI"
  ];
  final List<String> teachertitleList = [
    "MOBISCHO",
    "REGISTRE D'APPEL",
    "NOTES",
    "MATIERES",
    "AI",
  ];

  final List<String> parenttitleList = [
    "MOBISCHO",
    "ABSENCES",
    "MES ENFANTS",
    "NOTES",
  ];

  final List<String> encadreurTitleList = [
    "MOBISCHO",
    "CONVOQUER",
    "CONVOCATIONS",
    "ELEVES",
  ];

  late String currentTitle;
  late int currentIndex = 0;
  bool showingInitialBody = true;
  Widget? principalSecondaryBody;

  bool get _isPrincipalShell => widget.principalScreens != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationSubscription =
        NotificationService.instance.notificationEvents.listen((_) {
      _refreshUnreadNotificationCount();
    });
    _refreshUnreadNotificationCount();

    currentIndex = widget.selectedPage;

    currentTitle = '';
    if (widget.initialBody is SchoolAdvertScreen) {
      currentIndex = 0;
      showingInitialBody = true;
    }
    _tcontroller = TabController(
        length: _isPrincipalShell
            ? widget.principalTitles!.length
            : widget.user.admin == '1'
                ? admintitleList.length
                : widget.user.account_type == 'parent'
                    ? parenttitleList.length
                    : widget.user.account_type == 'encadreur'
                        ? encadreurTitleList.length
                        : teachertitleList.length,
        vsync: this);
    _tcontroller.addListener(changeTitle);
    // Registering listener
    _tcontroller.index = widget.selectedPage;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUnreadNotificationCount();
    }
  }

  Future<void> _refreshUnreadNotificationCount() async {
    try {
      final page = await NotificationInboxService.load();
      if (!mounted) return;
      setState(() => _unreadNotificationCount = page.unreadCount);
    } on Exception catch (error) {
      debugPrint(
        'Refreshing notification badge failed (${error.runtimeType}).',
      );
    }
  }

  void _openNotifications() {
    Navigator.of(context)
        .push<int>(
          MaterialPageRoute(
            builder: (_) => NotificationListScreen(
              user: widget.user,
              onUnreadCountChanged: (count) {
                if (mounted) {
                  setState(() => _unreadNotificationCount = count);
                }
              },
            ),
          ),
        )
        .then((_) => _refreshUnreadNotificationCount());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    _tcontroller.dispose();
    super.dispose();
  }

  // This function is called, every time active tab is changed
  void changeTitle() {
    setState(() {
      currentTitle = _titleAt(currentIndex);
    });
  }

  String _titleAt(int index) {
    final l10n = AppLocalizations.of(context);
    if (widget.initialBody is SchoolAdvertScreen) {
      return l10n.schoolUniversity;
    }

    if (_isPrincipalShell) {
      return localizedMenuTitle(context, widget.principalTitles![index]);
    }

    final titles = widget.user.admin == '1'
        ? [
            l10n.appName.toUpperCase(),
            l10n.users.toUpperCase(),
            l10n.notes.toUpperCase(),
            l10n.ai.toUpperCase()
          ]
        : widget.user.account_type == 'parent'
            ? [
                l10n.appName.toUpperCase(),
                l10n.absences.toUpperCase(),
                l10n.myChildren.toUpperCase(),
                l10n.notes.toUpperCase(),
              ]
            : widget.user.account_type == 'encadreur'
                ? [
                    l10n.appName.toUpperCase(),
                    l10n.convoke.toUpperCase(),
                    l10n.convocations.toUpperCase(),
                    l10n.students.toUpperCase(),
                  ]
                : [
                    l10n.appName.toUpperCase(),
                    l10n.registerCall.toUpperCase(),
                    l10n.notes.toUpperCase(),
                    l10n.subjects.toUpperCase(),
                    l10n.ai.toUpperCase()
                  ];
    return titles[index];
  }

  _tabBarIcons() {
    if (_isPrincipalShell) {
      return widget.principalIcons!;
    } else if (widget.user.admin == '1') {
      final items = <Widget>[
        const Icon(Icons.home),
        const Icon(Icons.person_outlined),
        const Icon(Icons.list_alt),
        const Icon(Icons.smart_toy_outlined),
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
        if (widget.user.account_type == 'encadreur') {
          final items = <Widget>[
            const Icon(Icons.home),
            const Icon(Icons.message),
            const Icon(Icons.list_alt_sharp),
            const Icon(Icons.person),
          ];
          return items;
        } else {
          final items = <Widget>[
            const Icon(Icons.home),
            const Icon(Icons.timer),
            const Icon(Icons.note_add_outlined),
            const Icon(Icons.menu_book),
            const Icon(Icons.smart_toy_outlined),
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
    currentTitle = _titleAt(currentIndex);
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
      currentTitle = _titleAt(currentIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    var screens = [];
    if (_isPrincipalShell) {
      screens = widget.principalScreens ?? [];
    } else if (widget.user.admin == '1') {
      setState(() {
        screens = [
          landingScreen(user: widget.user),
          const UsersScreen(),
          MarkScreen(
            user: widget.user,
          ),
          MobischoAiScreen(user: widget.user),
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
        if (widget.user.account_type == 'encadreur') {
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
              CoursesScreen(user: widget.user),
              MobischoAiScreen(user: widget.user),
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
          leadingWidth: 104,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (scaffoldContext) {
                  final showingBack =
                      ((widget.initialBody is SchoolAdvertScreen ||
                                  widget.initialBody is ConvocationDetail) &&
                              showingInitialBody) ||
                          principalSecondaryBody != null;
                  return IconButton(
                    icon: Icon(showingBack ? Icons.arrow_back : Icons.menu),
                    onPressed: () {
                      if ((widget.initialBody is SchoolAdvertScreen ||
                              widget.initialBody is ConvocationDetail) &&
                          showingInitialBody) {
                        _restoreDashboardShell();
                      } else if (principalSecondaryBody != null) {
                        _restorePrincipalSecondary();
                      } else {
                        Scaffold.of(scaffoldContext).openDrawer();
                      }
                    },
                  );
                },
              ),
              NotificationBell(
                unreadCount: _unreadNotificationCount,
                onPressed: _openNotifications,
              ),
            ],
          ),
          title: Text(
            (widget.initialBody is SchoolAdvertScreen && showingInitialBody)
                ? localizedMenuTitle(context, 'École / Université')
                : (widget.initialBody is ConvocationDetail &&
                        showingInitialBody)
                    ? localizedMenuTitle(context, 'Convocation')
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
        body: NotificationListener<PrincipalSectionRequest>(
          onNotification: (request) {
            if (!_isPrincipalShell) return false;
            setState(() {
              showingInitialBody = false;
              principalSecondaryBody = request.screen;
              currentTitle = localizedMenuTitle(context, request.title);
            });
            return true;
          },
          child: NotificationListener<PrincipalTabRequest>(
            onNotification: (request) {
              if (!_isPrincipalShell ||
                  request.index < 0 ||
                  request.index >= screens.length) {
                return false;
              }

              setState(() {
                showingInitialBody = false;
                principalSecondaryBody = null;
                currentIndex = request.index;
                _tcontroller.index = request.index;
              });
              changeTitle();
              return true;
            },
            child: showingInitialBody && widget.initialBody != null
                ? widget.initialBody!
                : principalSecondaryBody ?? screens[currentIndex],
          ),
        ),

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
                    ? localizedMenuTitle(
                        context,
                        widget.principalSecondaryTitles![secondaryIndex],
                      )
                    : currentTitle;
              });
            },
          ),
        ),
      ),
    );
  }
}
