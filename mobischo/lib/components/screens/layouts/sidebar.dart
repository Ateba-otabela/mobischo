// ignore_for_file: avoid_print, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/MyAccount.dart';
import 'package:mobischo/components/screens/changePassword.dart';
import 'package:mobischo/services/mobile_api_service.dart';
// ignore: unused_import
import 'package:mobischo/components/screens/courses/courses_list.dart';
import 'package:mobischo/components/screens/parent/devoirs_messages.dart';
import 'package:mobischo/components/screens/teachers.dart/TeacherConvocationList.dart';
import 'package:mobischo/components/screens/users/MyCollegues.dart';
import 'package:mobischo/home.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/welcome.dart';
import 'package:mobischo/l10n/ui_text.dart';

class SideBarMenu extends StatefulWidget {
  final User user;
  final List<String>? principalTitles;
  final List<Widget>? principalScreens;
  final ValueChanged<Widget>? onPrincipalSelect;
  const SideBarMenu(
      {Key? key,
      required this.user,
      this.principalTitles,
      this.principalScreens,
      this.onPrincipalSelect})
      : super(key: key);

  @override
  State<SideBarMenu> createState() => _SideBarMenuState();
}

class _SideBarMenuState extends State<SideBarMenu> {
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

  bool isLoaded = false;

  bool get _isPrincipal =>
      widget.principalScreens != null ||
      widget.user.account_type == 'principal_encadreur';

  String _localizedAccountType(BuildContext context) {
    switch (widget.user.account_type) {
      case 'parent':
        return uiText(context, 'parent');
      case 'enseignant':
      case 'teacher':
        return uiText(context, 'teacher');
      case 'encadreur':
        return uiText(context, 'encadreur');
      case 'principal':
        return uiText(context, 'principal');
      default:
        return widget.user.account_type;
    }
  }

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

  List<Widget> _accountActions(BuildContext context) {
    return [
      const Divider(height: 2),
      ListTile(
        leading: const Icon(Icons.lock_outline, color: CustomTheme.blue),
        title: Text(uiText(context, 'changePassword')),
        subtitle: Text(uiText(context, 'secureAccount')),
        onTap: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.push(MaterialPageRoute(
            builder: (_) => ChangePassword(
              user: widget.user,
              localOnly: _isPrincipal,
            ),
          ));
        },
      ),
      const Divider(height: 2),
      ListTile(
        leading: const Icon(Icons.logout, color: CustomTheme.blue),
        title: Text(uiText(context, 'signOut')),
        subtitle: Text(uiText(context, 'leaveSession')),
        onTap: () async {
          await MobileApiService.logout();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const Welcome()),
            (route) => false,
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isPrincipal) {
      final titles = widget.principalTitles ??
          [
            uiText(context, 'teacherReports'),
            uiText(context, 'teacherPresence'),
            uiText(context, 'teacherCallHistory'),
          ];
      final icons = const [
        Icons.message_outlined,
        Icons.warning_amber_outlined,
        Icons.assignment_outlined,
        Icons.mark_email_unread_outlined,
      ];
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 150,
            child: DrawerHeader(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/avatar-s-19.jpg'),
                  radius: 30,
                ),
                title: Text(
                    '${uiText(context, 'principal')} — ${uiText(context, 'encadreur')}'),
                subtitle: Text(uiText(context, 'allClasses')),
              ),
            ),
          ),
          ...List.generate(
              titles.length,
              (index) => Column(
                    children: [
                      ListTile(
                        leading: Icon(icons[index], color: CustomTheme.blue),
                        title: Text(localizedMenuTitle(context, titles[index])),
                        onTap: () {
                          if (widget.principalScreens == null ||
                              index >= widget.principalScreens!.length) {
                            return;
                          }
                          final screen = widget.principalScreens![index];
                          Navigator.of(context).pop();
                          widget.onPrincipalSelect?.call(screen);
                        },
                      ),
                      const Divider(height: 2),
                    ],
                  )),
          ..._accountActions(context),
        ],
      );
    } else if (1 == widget.user.admin) {
      return ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Text(widget.user.nom),
          ),
          ListTile(
            leading: Icon(
              Icons.child_care,
              color: CustomTheme.blue,
            ),
            title: Text(uiText(context, 'studentListUpper')),
            subtitle: Text(
              uiText(context, 'studentList'),
              style: TextStyle(color: Colors.grey),
            ),
            trailing: Icon(
              Icons.circle,
              color: CustomTheme.grey,
            ),
          ),
          const Divider(
            height: 2,
          ),
          ..._accountActions(context),
        ],
      );
    } else {
      if (widget.user.account_type == 'parent') {
        return ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 150,
              child: DrawerHeader(
                  decoration: const BoxDecoration(
                      // color: CustomTheme.blue,
                      ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white,
                      foregroundColor: CustomTheme.grey,
                      backgroundImage:
                          AssetImage('assets/images/avatar-s-19.jpg'),
                      radius: 30,
                      // child: Text("hello"),
                    ),
                    title: Text(
                        "${widget.user.nom.toUpperCase()} ${widget.user.prenom.toUpperCase()}",
                        style: Theme.of(context).textTheme.headlineMedium),
                    subtitle: Text(_localizedAccountType(context),
                        style: Theme.of(context).textTheme.bodyMedium),
                    onTap: () {
                      if (isLoaded == true) {
                        _interstitialAd!.show();
                      }
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MyAccount(user: widget.user)),
                      );
                    },
                  )),
            ),
            ListTile(
              leading: const Icon(
                Icons.home,
                color: CustomTheme.blue,
              ),
              title: Text(uiText(context, 'pageHome')),
              subtitle: Text(
                uiText(context, 'pageHome'),
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                if (isLoaded == true) {
                  _interstitialAd!.show();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Home(
                            user: widget.user,
                            selectedPage: 0,
                          )),
                );
              },
            ),
            const Divider(
              height: 2,
            ),
            ListTile(
              leading: const Icon(
                Icons.note_add_rounded,
                color: CustomTheme.blue,
              ),
              title: Text(uiText(context, 'notes')),
              subtitle: Text(
                uiText(context, 'childrenGradesDescription'),
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                if (isLoaded == true) {
                  _interstitialAd!.show();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Home(
                            user: widget.user,
                            selectedPage: 3,
                          )),
                );
              },
            ),
            const Divider(
              height: 2,
            ),
            ListTile(
              leading: const Icon(
                Icons.timer,
                color: CustomTheme.blue,
              ),
              title: Text(uiText(context, 'absences')),
              subtitle: Text(
                uiText(context, 'childrenAbsencesDescription'),
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                if (isLoaded == true) {
                  _interstitialAd!.show();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Home(
                            user: widget.user,
                            selectedPage: 1,
                          )),
                );
              },
            ),
            const Divider(
              height: 2,
            ),
            ListTile(
              leading: const Icon(
                Icons.person_pin,
                color: CustomTheme.blue,
              ),
              title: Text(uiText(context, 'enrollmentHistory')),
              subtitle: Text(
                uiText(context, 'consultEnrollmentHistory'),
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                if (isLoaded == true) {
                  _interstitialAd!.show();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Home(
                            user: widget.user,
                            selectedPage: 2,
                          )),
                );
              },
            ),
            const Divider(
              height: 2,
            ),
            ListTile(
              leading: const Icon(
                Icons.security,
                color: CustomTheme.blue,
              ),
              title: Text(uiText(context, 'messages')),
              subtitle: Text(
                uiText(context, 'mainMenuView'),
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                if (isLoaded == true) {
                  _interstitialAd!.show();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Home(
                      user: widget.user,
                      selectedPage: 0,
                      initialBody: DevoirsMessagesScreen(
                        user: widget.user,
                        initialTab: 1,
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                );
              },
            ),
            const Divider(
              height: 2,
            ),
            ListTile(
              leading: const Icon(
                Icons.person,
                color: CustomTheme.blue,
              ),
              title: Text(uiText(context, 'myAccount')),
              subtitle: Text(
                uiText(context, 'personalInformation'),
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                if (isLoaded == true) {
                  _interstitialAd!.show();
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyAccount(user: widget.user)),
                );
              },
            ),
            const Divider(
              height: 2,
            ),
            ..._accountActions(context),
          ],
        );
      } else {
        if (widget.user.account_type == 'enseignant') {
          return ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 150,
                child: DrawerHeader(
                    decoration: const BoxDecoration(
                        // color: Colors.,
                        ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        foregroundColor: CustomTheme.grey,
                        backgroundImage:
                            AssetImage('assets/images/avatar-s-19.jpg'),
                        radius: 30,
                        // child: Text("hello"),
                      ),
                      title: Text(
                          "${widget.user.nom.toUpperCase()} ${widget.user.prenom.toUpperCase()}",
                          style: Theme.of(context).textTheme.headlineMedium),
                      subtitle: Text(_localizedAccountType(context),
                          style: Theme.of(context).textTheme.bodyMedium),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MyAccount(user: widget.user)),
                        );
                      },
                    )),
              ),
              ListTile(
                leading: const Icon(
                  Icons.home,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'pageHome')),
                subtitle: Text(
                  uiText(context, 'pageHome'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Home(
                              user: widget.user,
                              selectedPage: 0,
                            )),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                leading: const Icon(
                  Icons.note_add_rounded,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'notes')),
                subtitle: Text(
                  uiText(context, 'allGradesRegistered'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Home(
                              user: widget.user,
                              selectedPage: 2,
                            )),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                leading: const Icon(
                  Icons.timer,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'absences')),
                subtitle: Text(
                  uiText(context, 'manageAbsencesDescription'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Home(
                              user: widget.user,
                              selectedPage: 1,
                            )),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_pin,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'colleagues')),
                subtitle: Text(
                  uiText(context, 'colleaguesListDescription'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Home(
                              user: widget.user,
                              selectedPage: 0,
                              initialBody: MyCollegues(user: widget.user),
                            )),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                leading: const Icon(
                  Icons.security,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'convocations')),
                subtitle: Text(
                  uiText(context, 'sendAndView'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TeacherConvocationList(user: widget.user)),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                leading: const Icon(
                  Icons.person,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'myAccount')),
                subtitle: Text(
                  uiText(context, 'personalInformation'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyAccount(user: widget.user)),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ..._accountActions(context),
            ],
          );
        } else {
          return ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 150,
                child: DrawerHeader(
                    decoration: const BoxDecoration(
                        // color: Colors.,
                        ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        foregroundColor: CustomTheme.grey,
                        backgroundImage:
                            AssetImage('assets/images/avatar-s-19.jpg'),
                        radius: 30,
                        // child: Text("hello"),
                      ),
                      title: Text(
                          "${widget.user.nom.toUpperCase()} ${widget.user.prenom.toUpperCase()}",
                          style: Theme.of(context).textTheme.headlineMedium),
                      subtitle: Text(_localizedAccountType(context),
                          style: Theme.of(context).textTheme.bodyMedium),
                      onTap: () {
                        if (isLoaded == true) {
                          _interstitialAd!.show();
                        }
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MyAccount(user: widget.user)),
                        );
                      },
                    )),
              ),
              ListTile(
                leading: const Icon(
                  Icons.home,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'pageHome')),
                subtitle: Text(
                  uiText(context, 'pageHome'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Home(
                              user: widget.user,
                              selectedPage: 1,
                            )),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                leading: const Icon(
                  Icons.note_add_rounded,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'sendMessages')),
                subtitle: Text(
                  uiText(context, 'conveneParents'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Home(
                              user: widget.user,
                              selectedPage: 1,
                            )),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                leading: const Icon(
                  Icons.timer,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'viewMessages')),
                subtitle: Text(
                  uiText(context, 'viewMessagesDescription'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Home(
                              user: widget.user,
                              selectedPage: 2,
                            )),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_pin,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'colleagues')),
                subtitle: Text(
                  uiText(context, 'colleaguesListDescription'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Home(
                              user: widget.user,
                              selectedPage: 0,
                              initialBody: MyCollegues(user: widget.user),
                            )),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                leading: const Icon(
                  Icons.security,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'students')),
                subtitle: Text(
                  uiText(context, 'viewStudentLists'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Home(
                              user: widget.user,
                              selectedPage: 1,
                            )),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                leading: const Icon(
                  Icons.person,
                  color: CustomTheme.blue,
                ),
                title: Text(uiText(context, 'myAccount')),
                subtitle: Text(
                  uiText(context, 'personalInformation'),
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (isLoaded == true) {
                    _interstitialAd!.show();
                  }
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyAccount(user: widget.user)),
                  );
                },
              ),
              const Divider(
                height: 2,
              ),
              ..._accountActions(context),
            ],
          );
        }
      }
    }
  }
}
