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

  bool get _isPrincipal => widget.principalScreens != null ||
      widget.user.account_type == 'principal_encadreur';

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
        title: const Text('MODIFIER LE MOT DE PASSE'),
        subtitle: const Text('Sécurisez votre compte'),
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
        title: const Text('DÉCONNEXION'),
        subtitle: const Text('Quitter votre session'),
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
          const [
            'Signalements des parents',
            'Alertes de présence',
            'Appels des professeurs',
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
                title: const Text('Principal — Encadreur'),
                subtitle: const Text('Toutes les classes'),
              ),
            ),
          ),
          ...List.generate(
              titles.length,
              (index) => Column(
                    children: [
                      ListTile(
                        leading: Icon(icons[index], color: CustomTheme.blue),
                        title: Text(titles[index]),
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
          const ListTile(
            leading: Icon(
              Icons.child_care,
              color: CustomTheme.blue,
            ),
            title: Text('ELEVES'),
            subtitle: Text(
              'Liste des eleves',
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
                    subtitle: Text(widget.user.account_type,
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
              title: const Text('ACEUIL'),
              subtitle: const Text(
                "Page d'Aceuil",
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
              title: const Text('NOTES'),
              subtitle: const Text(
                'Notes de vos enfants',
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
              title: const Text("ABSENCES"),
              subtitle: const Text(
                "Absences de vos enfants",
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
              title: const Text("HISTORIQUE D'INSCRIPTIONS"),
              subtitle: const Text(
                "Consultez l'Historique",
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
              title: const Text('MESSAGES'),
              subtitle: const Text(
                'Consulter',
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
              title: const Text('MON COMPTE'),
              subtitle: const Text(
                'Vos information personnel',
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
                      subtitle: Text(widget.user.account_type,
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
                title: const Text('ACEUIL'),
                subtitle: const Text(
                  "Page d'Aceuil",
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
                title: const Text('MES NOTES'),
                subtitle: const Text(
                  'Toutes vos notes enregistrees',
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
                title: const Text("HEURES D'ABSENCES"),
                subtitle: const Text(
                  "Ajoutez et consultez des absenses",
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
                title: const Text('MES COLLEGUES'),
                subtitle: const Text(
                  'Liste de vos collegues',
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
                title: const Text('CONVOCATIONS'),
                subtitle: const Text(
                  'Envoyez et consultez',
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
                title: const Text('MON COMPTE'),
                subtitle: const Text(
                  'Vos information personnel',
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
                      subtitle: Text(widget.user.account_type,
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
                title: const Text('ACEUIL'),
                subtitle: const Text(
                  "Page d'Aceuil",
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
                title: const Text('ENVOYER MESSAGES'),
                subtitle: const Text(
                  'Convoquez des eleves',
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
                title: const Text("CONSULTER MESSAGES"),
                subtitle: const Text(
                  "Consulter les convocations",
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
                title: const Text('MES COLLEGUES'),
                subtitle: const Text(
                  'Liste de vos collegues',
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
                title: const Text('ELEVES'),
                subtitle: const Text(
                  'Consultez les listes',
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
                title: const Text('MON COMPTE'),
                subtitle: const Text(
                  'Vos information personnel',
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
