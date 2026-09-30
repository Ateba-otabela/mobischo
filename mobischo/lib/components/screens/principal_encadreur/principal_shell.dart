import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/encardreur/chooseStudents.dart';
import 'package:mobischo/components/screens/encardreur/createConvocation.dart';
import 'package:mobischo/components/screens/changePassword.dart';
import 'package:mobischo/components/screens/layouts/customMenu.dart';
import 'package:mobischo/components/screens/mobischo_ai.dart';
import 'package:mobischo/components/screens/students/ClassStudents.dart';
import 'package:mobischo/models/class.dart';
import 'package:mobischo/models/convocation.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/principal_service.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/welcome.dart';
import 'principal_mock.dart';

class PrincipalShell extends StatefulWidget {
  final User user;

  const PrincipalShell({Key? key, required this.user}) : super(key: key);
  @override
  State<PrincipalShell> createState() => _PrincipalShellState();
}

class _PrincipalShellState extends State<PrincipalShell> {
  final titles = const [
    'MOBISCHO',
    'Classes',
    'Présence',
    'AI',
  ];

  final secondaryTitles = const [
    'Rapports des professeurs',
    'Alertes de présence',
    'Appels des professeurs',
    'Convoquer',
  ];

  late Future<PrincipalDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = PrincipalService.getDashboard(widget.user);
  }

  void _reloadDashboard() {
    setState(() {
      _dashboardFuture = PrincipalService.getDashboard(widget.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomMenu(
      user: widget.user,
      selectedPage: 0,
      principalTitles: titles,
      principalScreens: [
        PrincipalDashboardPage(
          user: widget.user,
          dashboardFuture: _dashboardFuture,
          onRetryDashboard: _reloadDashboard,
        ),
        PrincipalClassesPage(
          dashboardFuture: _dashboardFuture,
          onRetryDashboard: _reloadDashboard,
          onSelectClass: (item) => PrincipalSectionRequest(
            title: 'Élèves',
            screen: ClassStudents(
              user: widget.user,
              classe: _principalClass(item, widget.user.CodeEtablissement),
              embedded: true,
            ),
          ).dispatch(context),
        ),
        PrincipalAttendancePage(user: widget.user),
        MobischoAiScreen(user: widget.user),
      ],
      principalIcons: const [
        Icon(Icons.home),
        Icon(Icons.class_outlined),
        Icon(Icons.fact_check_outlined),
        Icon(Icons.smart_toy_outlined),
      ],
      principalSecondaryTitles: secondaryTitles,
      principalSecondaryScreens: [
        PrincipalReportsPage(user: widget.user),
        PrincipalAlertsPage(user: widget.user),
        PrincipalCallsPage(user: widget.user),
        PrincipalMessagesConvocationsPage(user: widget.user),
      ],
    );
  }
}

Classe _principalClass(
  PrincipalDashboardClassOverview overview,
  String schoolCode,
) {
  return Classe(
    LibelleClasse: overview.name,
    CodeClasse: overview.codeClasse,
    CodeTypeClasse: '',
    CodeCycle: '',
    CodeSpecialite: '',
    codetypeinscrip: '',
    CodeEtablissement: schoolCode,
  );
}

class PrincipalDashboardPage extends StatefulWidget {
  final User user;
  final Future<PrincipalDashboardData> dashboardFuture;
  final VoidCallback onRetryDashboard;

  const PrincipalDashboardPage({
    Key? key,
    required this.user,
    required this.dashboardFuture,
    required this.onRetryDashboard,
  }) : super(key: key);

  @override
  State<PrincipalDashboardPage> createState() => _PrincipalDashboardPageState();
}

class _PrincipalDashboardPageState extends State<PrincipalDashboardPage> {
  late Future<List<PrincipalAttendanceData>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = PrincipalService.getPrincipalAttendance(widget.user);
  }

  String _sessionSubject(PrincipalAttendanceData session) {
    final subject = session.subject.trim();
    if (subject.isNotEmpty) return subject;

    switch (session.codeMatiere.trim().toUpperCase()) {
      case 'MAH':
        return 'MATHEMATICS';
      default:
        return session.codeMatiere.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PrincipalDashboardData>(
      future: widget.dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          if (snapshot.hasError) {
            print('[PrincipalDashboard] Future error type: ${snapshot.error.runtimeType}');
            print('[PrincipalDashboard] Future error message: ${snapshot.error}');
          } else {
            print('[PrincipalDashboard] Future completed without dashboard data');
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger le tableau de bord.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: widget.onRetryDashboard,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        return FutureBuilder<List<PrincipalAttendanceData>>(
          future: _attendanceFuture,
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (attendanceSnapshot.hasError || !attendanceSnapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Impossible de charger les présences.'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _attendanceFuture =
                                PrincipalService.getPrincipalAttendance(
                                    widget.user);
                          });
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return _buildDashboard(
              context,
              snapshot.data!,
              attendanceSnapshot.data!,
            );
          },
        );
      },
    );
  }

  Widget _buildDashboard(
      BuildContext context,
      PrincipalDashboardData dashboard,
      List<PrincipalAttendanceData> attendanceSessions) {
    final recentSessions = [...attendanceSessions]
      ..sort((first, second) {
        final dateComparison = second.date.compareTo(first.date);
        if (dateComparison != 0) return dateComparison;
        return second.time.compareTo(first.time);
      });

    return ListView(padding: const EdgeInsets.all(14), children: [
      _HeaderCard(
          title: 'Principal — Encadreur',
          subtitle: 'Toutes les classes',
          icon: Icons.admin_panel_settings_outlined),
      const SizedBox(height: 12),
      _DashboardActionCard(
        icon: Icons.class_outlined,
        title: 'Classes',
        summary:
            '${dashboard.classes} classes\n'
            '${dashboard.classOverview.where((item) => item.sessionsToday > 0).length} avec des séances aujourd’hui',
        onTap: () => PrincipalTabRequest(1).dispatch(context),
      ),
      _DashboardActionCard(
        icon: Icons.groups_outlined,
        title: 'Élèves',
        summary:
            '${dashboard.students} élèves\n'
            '${dashboard.classOverview.fold<int>(0, (total, item) => total + item.boys)} garçons • '
            '${dashboard.classOverview.fold<int>(0, (total, item) => total + item.girls)} filles',
        onTap: () => PrincipalSectionRequest(
          title: 'Élèves',
          screen: PrincipalClassesPage(
              dashboardFuture: widget.dashboardFuture,
              onRetryDashboard: widget.onRetryDashboard,
              headerTitle: 'Choisir une classe',
              headerSubtitle: 'Sélectionnez une classe pour consulter ses élèves',
              onSelectClass: (item) {
                PrincipalSectionRequest(
                  title: 'Élèves',
                  screen: ClassStudents(
                    user: widget.user,
                    classe: _principalClass(item, widget.user.CodeEtablissement),
                    embedded: true,
                  ),
                ).dispatch(context);
              },
            ),
        ).dispatch(context),
      ),
      _DashboardActionCard(
        icon: Icons.person_outline,
        title: 'Professeurs',
        summary:
            '${dashboard.teachers} professeurs\n'
            '${dashboard.todaySessions.length} appels enregistrés aujourd’hui',
        onTap: () => PrincipalSectionRequest(
          title: 'Professeurs',
          screen: PrincipalTeacherClassesPage(
            user: widget.user,
            onSelectTeacher: (teacherName) {
              PrincipalSectionRequest(
                title: teacherName,
                screen: PrincipalTeacherCallsPage(
                  teacherName: teacherName,
                  attendanceFuture: _attendanceFuture,
                ),
              ).dispatch(context);
            },
          ),
        ).dispatch(context),
      ),
      _DashboardActionCard(
        icon: Icons.fact_check_outlined,
        title: 'Présence',
        summary:
            '${dashboard.todaySessions.fold<int>(0, (total, item) => total + item.present)} présents • '
            '${dashboard.todaySessions.fold<int>(0, (total, item) => total + item.absent)} absents • '
            '${dashboard.todaySessions.fold<int>(0, (total, item) => total + item.late)} retards\n'
            '${dashboard.todayAttendancePercentage == null ? '—' : '${dashboard.todayAttendancePercentage}%'} aujourd’hui',
        onTap: () => PrincipalTabRequest(2).dispatch(context),
      ),
      const SizedBox(height: 14),
      _SectionTitle('Appels du jour'),
      if (dashboard.todaySessions.isEmpty)
        const _Card(child: Text('Aucune session de présence enregistrée.'))
      else
        ...dashboard.todaySessions.map((session) => _DashboardSessionTile(
              session: session,
            )),
      const SizedBox(height: 14),
      _SectionTitle('Vue d’ensemble des classes'),
      if (dashboard.classOverview.isEmpty)
        const _Card(child: Text('Aucune classe disponible.'))
      else
        ...dashboard.classOverview.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _DashboardClassCard(classOverview: item),
            )),
      if (dashboard.classOverview.isNotEmpty)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => PrincipalTabRequest(1).dispatch(context),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Voir plus'),
          ),
        ),
      const SizedBox(height: 8),
      const SizedBox(height: 8),
      _SectionTitle('Appels récents des professeurs'),
      if (recentSessions.isEmpty)
        const _Card(child: Text('Aucune session de présence enregistrée.'))
      else ...[
        ...recentSessions.take(3).toList().asMap().entries.map((entry) {
          final session = entry.value;
          final percentage = session.attendancePercentage ??
              session.calculatedAttendancePercentage;
          debugPrint(
            'DASHBOARD CARD[${entry.key}]: '
            '${session.codeEnseignement} / ${session.codeMatiere} / '
            '${session.className}; present=${session.present}, '
            'absent=${session.absent}, late=${session.late}, '
            'studentCount=${session.studentCount}, '
            'records=${session.records.length}',
          );
          return _DashboardActivityCard(
            assetPath: 'assets/images/landing3.png',
            title: _sessionSubject(session),
            subtitle:
                '${session.className}\n${session.teacher}\n${session.date} • ${session.time}',
            titleTrailing: percentage == null ? '—' : '$percentage%',
            onTap: () {
              debugPrint('=== SELECTED SESSION IDENTITY ===');
              debugPrint('CodeClasse=${session.codeClasse}');
              debugPrint('CodeMatiere=${session.codeMatiere}');
              debugPrint('CodeEnseignement=${session.codeEnseignement}');
              debugPrint('date=${session.date}');
              debugPrint('time=${session.time}');
              debugPrint('=== BEFORE OPENING ATTENDANCE DETAIL ===');
              debugPrint('class: ${session.className}');
              debugPrint('subject: ${session.subject}');
              debugPrint('teacher: ${session.teacher}');
              debugPrint('codeClasse: ${session.codeClasse}');
              debugPrint('codeMatiere: ${session.codeMatiere}');
              debugPrint('codeEnseignement: ${session.codeEnseignement}');
              debugPrint('date: ${session.date}');
              debugPrint('time: ${session.time}');
              debugPrint('present: ${session.present}');
              debugPrint('absent: ${session.absent}');
              debugPrint('late: ${session.late}');
              debugPrint('studentCount: ${session.studentCount}');
              debugPrint('percentage: ${session.attendancePercentage}');
              debugPrint('records: ${session.records.length}');
              debugPrint(
                'SELECTED SESSION: '
                '${session.codeEnseignement} / '
                '${session.codeMatiere} / '
                '${session.className}',
              );
              for (final record in session.records) {
                debugPrint(
                  'STUDENT: code=${record.codeEleve}, '
                  'name=${record.studentName}, '
                  'status=${record.status}',
                );
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrincipalLiveAttendanceSessionPage(
                    session: session,
                    subjectLabel: _sessionSubject(session),
                    preferApiAttendancePercentage: true,
                    showRawStatuses: true,
                  ),
                ),
              );
            },
          );
        }),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => PrincipalTabRequest(2).dispatch(context),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Voir plus'),
          ),
        ),
      ],
    ]);
  }
}

class PrincipalClassesPage extends StatefulWidget {
  final Future<PrincipalDashboardData> dashboardFuture;
  final VoidCallback onRetryDashboard;
  final ValueChanged<PrincipalDashboardClassOverview>? onSelectClass;
  final String headerTitle;
  final String headerSubtitle;

  const PrincipalClassesPage({
    Key? key,
    required this.dashboardFuture,
    required this.onRetryDashboard,
    this.onSelectClass,
    this.headerTitle = 'Classes',
    this.headerSubtitle = 'Accès à toutes les classes de l’établissement',
  }) : super(key: key);

  @override
  State<PrincipalClassesPage> createState() => _PrincipalClassesPageState();
}

class _PrincipalClassesPageState extends State<PrincipalClassesPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PrincipalDashboardData>(
      future: widget.dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger les classes.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: widget.onRetryDashboard,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final classes = (snapshot.data?.classOverview ?? []).where((schoolClass) {
          final normalizedQuery = query.toLowerCase();
          return normalizedQuery.isEmpty || schoolClass.name.toLowerCase().contains(normalizedQuery);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _HeaderCard(
              title: widget.headerTitle,
              subtitle: widget.headerSubtitle,
              icon: Icons.class_outlined,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher une classe',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 12),
            if (classes.isEmpty)
              const _Card(
                  child: Text('Aucune classe ne correspond à la recherche.'))
            else
              ...classes.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DashboardClassCard(
                      classOverview: item,
                      onTap: widget.onSelectClass == null
                          ? null
                          : () => widget.onSelectClass!(item),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class PrincipalTeacherClassesPage extends StatefulWidget {
  final User user;
  final ValueChanged<String>? onSelectTeacher;

  const PrincipalTeacherClassesPage({
    Key? key,
    required this.user,
    this.onSelectTeacher,
  }) : super(key: key);

  @override
  State<PrincipalTeacherClassesPage> createState() =>
      _PrincipalTeacherClassesPageState();
}

class _PrincipalTeacherClassesPageState
    extends State<PrincipalTeacherClassesPage> {
  late Future<List<PrincipalClassSummary>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = PrincipalService.getPrincipalTeacherClasses(widget.user);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PrincipalClassSummary>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Impossible de charger les classes.'));
          }

          final classes = snapshot.data ?? <PrincipalClassSummary>[];
          return ListView(
            padding: const EdgeInsets.all(14),
            children: classes.isEmpty
                ? [const _Card(child: Text('Aucun professeur disponible.'))]
                : classes
                    .map((schoolClass) => _Card(
                          child: ExpansionTile(
                            title: Text(schoolClass.name),
                            subtitle:
                                Text('${schoolClass.teachers.length} professeurs'),
                            children: schoolClass.teachers
                                .map((teacher) => ListTile(
                                      leading: const Icon(
                                        Icons.person_outline,
                                        color: CustomTheme.blue,
                                      ),
                                      title: Text(teacher.fullName),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                      onTap: widget.onSelectTeacher == null
                                          ? null
                                          : () => widget.onSelectTeacher!(
                                              teacher.fullName),
                                    ))
                                .toList(),
                          ),
                        ))
                    .toList(),
          );
        },
      );
}

class PrincipalTeacherCallsPage extends StatelessWidget {
  final String teacherName;
  final Future<List<PrincipalAttendanceData>> attendanceFuture;

  const PrincipalTeacherCallsPage({
    Key? key,
    required this.teacherName,
    required this.attendanceFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PrincipalAttendanceData>>(
        future: attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = (snapshot.data ?? <PrincipalAttendanceData>[])
              .where((session) => session.teacher == teacherName)
              .toList()
            ..sort((first, second) => second.date.compareTo(first.date));

          if (snapshot.hasError) {
            return const Center(
              child: Text('Impossible de charger les appels du professeur.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(14),
            children: sessions.isEmpty
                ? [const _Card(child: Text('Aucun appel disponible.'))]
                : sessions
                    .map((session) => _DashboardActivityCard(
                          assetPath: 'assets/images/landing3.png',
                          title: session.subject.isNotEmpty
                              ? session.subject
                              : session.codeMatiere,
                          subtitle:
                              '${session.className}\n${session.date} • ${session.time}',
                          titleTrailing: session.attendancePercentage == null
                              ? '—'
                              : '${session.attendancePercentage}%',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PrincipalLiveAttendanceSessionPage(
                                session: session,
                                preferApiAttendancePercentage: true,
                                showRawStatuses: true,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
          );
        },
      );
}

class PrincipalMessagesConvocationsPage extends StatefulWidget {
  final User user;

  const PrincipalMessagesConvocationsPage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<PrincipalMessagesConvocationsPage> createState() =>
      _PrincipalMessagesConvocationsPageState();
}

class _PrincipalMessagesConvocationsPageState
    extends State<PrincipalMessagesConvocationsPage> {
  late Future<List<Convocation>> _convocationsFuture;

  @override
  void initState() {
    super.initState();
    _convocationsFuture =
        AcademicServices.getTeacherConvocation(widget.user.code);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    void openClassPicker(BuildContext flowContext) {
      PrincipalSectionRequest(
        title: 'Choisir une classe',
        screen: PrincipalConvocationClassesPage(
          user: user,
          onSelectClass: (classContext, schoolClass) {
            PrincipalSectionRequest(
              title: 'Convoquer des élèves',
              screen: ChooseStudents(
                classe: schoolClass,
                user: user,
                embedded: true,
                onCreate: (createContext, selectedStudents) {
                  PrincipalSectionRequest(
                    title: 'Créer une convocation',
                    screen: CreateEncardreurConvocation(
                      user: user,
                      students: selectedStudents,
                      classe: schoolClass,
                      embedded: true,
                      onSaved: (saveContext) {
                        PrincipalSectionRequest(
                          title: 'Convocations récentes',
                          screen: PrincipalMessagesConvocationsPage(user: user),
                        ).dispatch(saveContext);
                      },
                    ),
                  ).dispatch(createContext);
                },
              ),
            ).dispatch(classContext);
          },
        ),
      ).dispatch(flowContext);
    }

    return FutureBuilder<List<Convocation>>(
        future: _convocationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final convocations = snapshot.data ?? <Convocation>[];
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const _HeaderCard(
                title: 'Convocations récentes',
                subtitle: 'Suivi des convocations envoyées aux élèves',
                icon: Icons.mark_email_unread_outlined,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: _SectionTitle('Convocations envoyées'),
                  ),
                  IconButton(
                    tooltip: 'Créer une convocation',
                    icon: const Icon(Icons.add),
                    onPressed: () => openClassPicker(context),
                  ),
                ],
              ),
              if (convocations.isEmpty)
                const _Card(child: Text('Aucune convocation envoyée.'))
              else
                ...convocations.map((item) => _Card(
                      child: ListTile(
                        leading: const Icon(Icons.assignment_outlined,
                            color: CustomTheme.blue),
                        title: Text(item.motif),
                        subtitle: Text(
                          '${item.CodeEleve} • ${item.dateConvocation}\n'
                          '${item.description}',
                        ),
                        isThreeLine: true,
                        trailing: item.CodeMatiere.isEmpty
                            ? null
                            : Text(item.CodeMatiere),
                      ),
                    )),
            ],
          );
        },
      );
  }
}

class PrincipalConvocationClassesPage extends StatefulWidget {
  final User user;
  final void Function(BuildContext, Classe) onSelectClass;

  const PrincipalConvocationClassesPage({
    Key? key,
    required this.user,
    required this.onSelectClass,
  }) : super(key: key);

  @override
  State<PrincipalConvocationClassesPage> createState() =>
      _PrincipalConvocationClassesPageState();
}

class _PrincipalConvocationClassesPageState
    extends State<PrincipalConvocationClassesPage> {
  late Future<List<PrincipalClassSummary>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = PrincipalService.getClasses(widget.user);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PrincipalClassSummary>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final classes = snapshot.data ?? <PrincipalClassSummary>[];
          return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final item = classes[index];
                return _Card(
                  child: ListTile(
                    title: Text(item.name),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      final schoolClass = Classe(
                        LibelleClasse: item.name,
                        CodeClasse: item.codeClasse,
                        CodeTypeClasse: '',
                        CodeCycle: '',
                        CodeSpecialite: '',
                        codetypeinscrip: '',
                        CodeEtablissement:
                            widget.user.CodeEtablissement,
                      );
                      widget.onSelectClass(context, schoolClass);
                    },
                  ),
                );
              },
          );
        },
      );
}

class PrincipalClassDetailPage extends StatelessWidget {
  final PrincipalClass schoolClass;
  const PrincipalClassDetailPage({Key? key, required this.schoolClass})
      : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: CustomTheme.grey,
        appBar: AppBar(
            title: Text(schoolClass.name), backgroundColor: CustomTheme.blue),
        body: ListView(padding: const EdgeInsets.all(14), children: [
          _ClassCard(schoolClass: schoolClass),
          const SizedBox(height: 10),
          _SectionTitle('Appel récent'),
          ...PrincipalMockService.attendanceSessions
              .where((session) => session.schoolClass.name == schoolClass.name)
              .map((session) => _SessionTile(
                    session: session,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PrincipalAttendanceSessionPage(
                                session: session))),
                  )),
          const SizedBox(height: 10),
          _SectionTitle('Élèves'),
          ...schoolClass.students.map((student) => _StudentTile(
              student: student,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PrincipalStudentDetailPage(student: student)))))
        ]),
      );
}

class PrincipalAttendancePage extends StatefulWidget {
  final User user;

  const PrincipalAttendancePage({Key? key, required this.user}) : super(key: key);

  @override
  State<PrincipalAttendancePage> createState() => _PrincipalAttendancePageState();
}

class _PrincipalAttendancePageState extends State<PrincipalAttendancePage> {
  String classFilter = 'Toutes les classes';
  String subjectFilter = 'Toutes les matières';
  String teacherFilter = 'Tous les enseignants';
  String statusFilter = 'Tous les statuts';
  String? dateFilter;
  String? apiDateFilter;
  late Future<List<PrincipalAttendanceData>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = PrincipalService.getPrincipalAttendance(widget.user);
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) return;
    final apiDate = '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
    setState(() {
      dateFilter = '${selectedDate.day.toString().padLeft(2, '0')}/'
          '${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
      apiDateFilter = apiDate;
      _attendanceFuture =
          PrincipalService.getPrincipalAttendance(widget.user, date: apiDate);
    });
  }

  void _clearDate() {
    setState(() {
      dateFilter = null;
      apiDateFilter = null;
      _attendanceFuture = PrincipalService.getPrincipalAttendance(widget.user);
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'P':
        return 'Présent';
      case 'A':
        return 'Absent';
      case 'R':
        return 'Retard';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrincipalAttendanceData>>(
      future: _attendanceFuture,
      builder: (context, snapshot) {
        debugPrint(
          'PRESENCE FUTURE: state=${snapshot.connectionState}, '
          'hasData=${snapshot.hasData}, '
          'error=${snapshot.error}',
        );
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger les présences.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _attendanceFuture = PrincipalService.getPrincipalAttendance(
                        widget.user,
                        date: apiDateFilter,
                      );
                    }),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final allSessions = snapshot.data ?? <PrincipalAttendanceData>[];
  debugPrint('PRESENCE FETCHED: sessions count = ${allSessions.length}');
        final totalPresent = allSessions.fold<int>(
          0, (total, session) => total + session.present);
        final totalStudents = allSessions.fold<int>(
          0, (total, session) => total + session.studentCount);
        final overallAttendance = allSessions.isEmpty
            ? null
            : allSessions.every((session) => session.hasValidTotals) &&
              totalStudents > 0 &&
              totalPresent >= 0 &&
              totalPresent <= totalStudents
            ? '${(totalPresent / totalStudents * 100).round()}%'
            : '—';
        final classSessions = classFilter == 'Toutes les classes'
            ? allSessions
            : allSessions
                .where((session) => session.className == classFilter)
                .toList();
        final subjectOptions = <String>{
          'Toutes les matières',
          ...classSessions.map((session) => session.subject),
        }.toList();
        final subjectSessions = subjectFilter == 'Toutes les matières'
            ? classSessions
            : classSessions
                .where((session) => session.subject == subjectFilter)
                .toList();
        final teacherOptions = <String>{
          'Tous les enseignants',
          ...subjectSessions.map((session) => session.teacher),
        }.toList();
        final sessions = subjectSessions.where((session) {
          final hasStatus = statusFilter == 'Tous les statuts' ||
              session.records.any(
                  (record) => _statusLabel(record.status) == statusFilter);
          return (teacherFilter == 'Tous les enseignants' ||
                  session.teacher == teacherFilter) &&
              hasStatus;
        }).toList();

        debugPrint('PRESENCE: sessions count = ${sessions.length}');
        if (sessions.isNotEmpty) {
          final session = sessions.first;
          debugPrint(
            'PRESENCE FIRST SESSION: '
            'class=${session.className}, '
            'subject=${session.subject}, '
            'teacher=${session.teacher}, '
            'present=${session.present}, '
            'studentCount=${session.studentCount}, '
            'percentage=${session.attendancePercentage}',
          );
        }

        if (!subjectOptions.contains(subjectFilter)) {
          subjectFilter = 'Toutes les matières';
        }
        if (!teacherOptions.contains(teacherFilter)) {
          teacherFilter = 'Tous les enseignants';
        }

        return ListView(padding: const EdgeInsets.all(14), children: [
          _HeaderCard(
              title: 'Présence',
              subtitle: 'Suivi de toutes les classes',
              icon: Icons.fact_check_outlined),
          if (overallAttendance != null) ...[
            const SizedBox(height: 10),
            _Card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Présence globale'),
                trailing: Text(overallAttendance),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _Card(
              child: Column(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: CustomTheme.blue),
              title: Text(dateFilter ?? 'Toutes les dates'),
              subtitle: const Text('Date'),
              trailing: dateFilter == null
                  ? const Icon(Icons.arrow_forward_ios, size: 16)
                  : IconButton(
                      tooltip: 'Réinitialiser la date',
                      icon: const Icon(Icons.clear),
                      onPressed: _clearDate,
                    ),
              onTap: _selectDate,
            ),
            DropdownButtonFormField<String>(
                value: classFilter,
                decoration: const InputDecoration(labelText: 'Classe'),
                items: <String>{
                  'Toutes les classes',
                  ...allSessions.map((session) => session.className),
                }
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() {
                      classFilter = value!;
                      subjectFilter = 'Toutes les matières';
                      teacherFilter = 'Tous les enseignants';
                    })),
            DropdownButtonFormField<String>(
                value: subjectFilter,
                decoration: const InputDecoration(labelText: 'Matière'),
                items: subjectOptions
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() {
                      subjectFilter = value!;
                      teacherFilter = 'Tous les enseignants';
                    })),
            DropdownButtonFormField<String>(
                value: teacherFilter,
                decoration: const InputDecoration(labelText: 'Enseignant'),
                items: teacherOptions
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => teacherFilter = value!)),
            DropdownButtonFormField<String>(
                value: statusFilter,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: ['Tous les statuts', 'Présent', 'Absent', 'Retard']
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => statusFilter = value!))
          ])),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            const _Card(child: Text('Aucune session ne correspond aux filtres.'))
          else
            ...sessions.map((session) => _PrincipalAttendanceSessionTile(
                  session: session,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PrincipalLiveAttendanceSessionPage(session: session),
                    ),
                  ),
                )),
        ]);
      },
    );
  }
}

class PrincipalStudentDetailPage extends StatelessWidget {
  final PrincipalStudent student;
  const PrincipalStudentDetailPage({Key? key, required this.student})
      : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
          title: const Text('Détail de l’élève'),
          backgroundColor: CustomTheme.blue),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        _Card(
            child: Row(children: [
          CircleAvatar(radius: 34, backgroundImage: AssetImage(student.photo)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(student.name,
                    style: Theme.of(context).textTheme.headlineMedium),
                Text(student.code),
                Text(student.className)
              ]))
        ])),
        const SizedBox(height: 12),
        _StatsGrid(items: [
          _StatItem('Présence', '${(student.attendance * 100).round()}%',
              Icons.percent),
          _StatItem('Présents', '${student.present}', Icons.check),
          _StatItem('Absences', '${student.absent}', Icons.close),
          _StatItem('Retards', '${student.late}', Icons.schedule)
        ]),
        const SizedBox(height: 12),
        _SectionTitle('Historique de présence'),
        ...PrincipalMockService.attendance
            .where((item) => item.student.code == student.code)
            .map((item) => _Card(
                child: ListTile(
                    title: Text('${item.date} • ${item.subject}'),
                    subtitle: Text('${item.teacher} • ${item.time}'),
                    trailing: Text(item.status))))
      ]));
}

class PrincipalAttendanceSessionPage extends StatelessWidget {
  final PrincipalAttendanceSession session;

  const PrincipalAttendanceSessionPage({Key? key, required this.session})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: CustomTheme.grey,
        appBar: AppBar(
          title: const Text('Détail de la présence'),
          backgroundColor: CustomTheme.blue,
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Detail('Date', session.date),
                  _Detail('Heure', session.time),
                  _Detail('Classe', session.schoolClass.name),
                  _Detail('Matière', session.subject),
                  _Detail('Enseignant', session.teacher),
                  _Detail('Élèves', '${session.total}'),
                  _Detail('Présents', '${session.present}'),
                  _Detail('Absents', '${session.absent}'),
                  _Detail('Retards', '${session.late}'),
                  _Detail(
                    'Présence',
                    session.attendance == null
                        ? 'Aucune donnée'
                        : '${(session.attendance! * 100).round()}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionTitle('Élèves'),
            ...session.records.map((record) => _StudentTile(
                  student: record.student,
                  subtitle:
                      '${record.student.code} • ${record.student.className}',
                  status: record.status,
                )),
          ],
        ),
      );
}

class PrincipalReportsPage extends StatefulWidget {
  final User user;

  const PrincipalReportsPage({Key? key, required this.user}) : super(key: key);

  @override
  State<PrincipalReportsPage> createState() => _PrincipalReportsPageState();
}

class _PrincipalReportsPageState extends State<PrincipalReportsPage> {
  late Future<List<PrincipalAttendanceData>> _future;

  @override
  void initState() {
    super.initState();
    _future = PrincipalService.getPrincipalAttendance(widget.user);
  }

  void _reload() {
    setState(() {
      _future = PrincipalService.getPrincipalAttendance(widget.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrincipalAttendanceData>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger les rapports des professeurs.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _reload,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final sessions = snapshot.data ?? const <PrincipalAttendanceData>[];

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _HeaderCard(
                title: 'Rapports des professeurs',
                subtitle: 'Appels de présence transmis par les enseignants',
                icon: Icons.assignment_outlined),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              _Card(
                child: Text('Aucun rapport de présence pour le moment.'),
              )
            else
              ...sessions.map((session) => _Card(
                    child: ListTile(
                      title: Text('${session.className} • ${session.subject}'),
                      subtitle: Text(
                          '${session.date} à ${session.time} • ${session.teacher}\n'
                          '${session.present} présents • ${session.absent} absents • ${session.late} retards'),
                      isThreeLine: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrincipalLiveAttendanceSessionPage(
                            session: session,
                          ),
                        ),
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class ParentReportDetailPage extends StatefulWidget {
  final User user;
  final InvestigationAlertData alert;
  final VoidCallback onUpdated;

  const ParentReportDetailPage({
    Key? key,
    required this.user,
    required this.alert,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<ParentReportDetailPage> createState() => _ParentReportDetailPageState();
}

class _ParentReportDetailPageState extends State<ParentReportDetailPage> {
  bool _submitting = false;

  Future<void> _submitStatus(String status) async {
    setState(() => _submitting = true);
    try {
      await PrincipalService.updateInvestigationAlert(
        widget.user,
        alertId: widget.alert.id?.toString() ?? '',
        status: status,
      );
      if (!mounted) return;
      widget.onUpdated();
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final studentName = alert.studentName.isNotEmpty ? alert.studentName : alert.studentCode;

    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
          title: const Text('Détail du signalement'),
          backgroundColor: CustomTheme.blue),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        _Card(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Detail('Élève', studentName),
          _Detail('Classe', alert.codeClasse),
          _Detail('Date d’absence', alert.dateAbsence),
          _Detail('Statut parent', alert.parentStatusLabel),
          _Detail('Statut professeur', alert.teacherStatusLabel),
          _Detail('Status', alert.displayStatus),
          _Detail('Note', alert.notes.isNotEmpty ? alert.notes : 'Aucune note'),
        ])),
        const SizedBox(height: 14),
        CustomButton(
            text: 'Valider la présence du professeur',
            loading: _submitting,
            onPress: () => _submitStatus('validated')),
        const SizedBox(height: 8),
        OutlinedButton(
            onPressed: _submitting ? null : () => _submitStatus('rejected'),
            child: const Text('Rejeter la présence du professeur')),
      ]),
    );
  }
}

class PrincipalAlertsPage extends StatefulWidget {
  final User user;

  const PrincipalAlertsPage({Key? key, required this.user}) : super(key: key);

  @override
  State<PrincipalAlertsPage> createState() => _PrincipalAlertsPageState();
}

class _PrincipalAlertsPageState extends State<PrincipalAlertsPage> {
  late Future<List<InvestigationAlertData>> _future;

  @override
  void initState() {
    super.initState();
    _future = PrincipalService.getInvestigations(widget.user);
  }

  void _reload() {
    setState(() {
      _future = PrincipalService.getInvestigations(widget.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InvestigationAlertData>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger les alertes.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _reload,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final alerts = snapshot.data ?? const <InvestigationAlertData>[];
        final pendingAlerts = alerts.where((alert) => alert.status == 'pending').toList();

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _HeaderCard(
                title: 'Alertes de présence',
                subtitle:
                    'Consultez ici les présences nécessitant une vérification.',
                icon: Icons.info_outline),
            const SizedBox(height: 12),
            if (pendingAlerts.isEmpty)
              _Card(
                child: Text('Aucune alerte de présence à vérifier.'),
              )
            else
              ...pendingAlerts.map((alert) => Card(
                    margin: EdgeInsets.zero,
                    color: Colors.red.shade50,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                      ),
                      title: Text(
                        '${alert.studentName.isNotEmpty ? alert.studentName : alert.studentCode} • ${alert.codeClasse}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Parent : ${alert.parentStatusLabel} • Professeur : ${alert.teacherStatusLabel}',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      trailing: Text(
                        'À vérifier',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentReportDetailPage(
                            user: widget.user,
                            alert: alert,
                            onUpdated: _reload,
                          ),
                        ),
                      ).then((_) => _reload()),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class PrincipalCallsPage extends StatefulWidget {
  final User user;

  const PrincipalCallsPage({Key? key, required this.user}) : super(key: key);

  @override
  State<PrincipalCallsPage> createState() => _PrincipalCallsPageState();
}

class _PrincipalCallsPageState extends State<PrincipalCallsPage> {
  String classFilter = 'Toutes les classes';
  String teacherFilter = 'Tous les enseignants';
  late Future<List<PrincipalAttendanceData>> _future;

  @override
  void initState() {
    super.initState();
    _future = PrincipalService.getPrincipalAttendance(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrincipalAttendanceData>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger les appels des professeurs.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() => _future = PrincipalService.getPrincipalAttendance(widget.user)),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final allSessions = snapshot.data ?? const <PrincipalAttendanceData>[];
        final allClasses = <String>{'Toutes les classes', ...allSessions.map((item) => item.className)}.toList();
        final allTeachers = <String>{'Tous les enseignants', ...allSessions.map((item) => item.teacher)}.toList();

        if (!allClasses.contains(classFilter)) {
          classFilter = 'Toutes les classes';
        }
        if (!allTeachers.contains(teacherFilter)) {
          teacherFilter = 'Tous les enseignants';
        }

        final calls = allSessions.where((session) {
          final matchesClass = classFilter == 'Toutes les classes' || session.className == classFilter;
          final matchesTeacher = teacherFilter == 'Tous les enseignants' ||
              session.teacher.toLowerCase().contains(teacherFilter.toLowerCase());
          return matchesClass && matchesTeacher;
        }).toList();

        return ListView(padding: const EdgeInsets.all(14), children: [
          _HeaderCard(
              title: 'Appels des professeurs',
              subtitle: 'Suivi des appels de présence',
              icon: Icons.assignment_outlined),
          const SizedBox(height: 12),
          _Card(
              child: Column(children: [
            DropdownButtonFormField<String>(
                value: classFilter,
                decoration: const InputDecoration(labelText: 'Classe'),
                items: allClasses
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => classFilter = value ?? classFilter)),
            DropdownButtonFormField<String>(
                value: teacherFilter,
                decoration: const InputDecoration(labelText: 'Enseignant'),
                items: allTeachers
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => teacherFilter = value ?? teacherFilter)),
          ])),
          const SizedBox(height: 10),
          if (calls.isEmpty)
            const _Card(child: Text('Aucun appel ne correspond aux filtres.'))
          else
            ...calls.map((session) => _Card(
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrincipalLiveAttendanceSessionPage(session: session),
                      ),
                    ),
                    title: Text('${session.className} • ${session.subject}'),
                    subtitle: Text(
                      '${session.date} à ${session.time} • ${session.teacher}\n'
                      '${session.present} présents • ${session.absent} absents • ${session.late} retards',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      session.calculatedAttendancePercentage == null
                          ? '—'
                          : '${session.calculatedAttendancePercentage}%',
                    ),
                  ),
                )),
        ]);
      },
    );
  }
}

class PrincipalProfilePage extends StatelessWidget {
  final User user;

  const PrincipalProfilePage({Key? key, required this.user}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(14), children: [
        _HeaderCard(
            title: 'Principal — Encadreur',
            subtitle: 'Toutes les classes',
            icon: Icons.person_outline),
        const SizedBox(height: 12),
        _Card(
            child: Column(children: [
          ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Accès local temporaire'),
              subtitle: const Text('Les données affichées sont simulées.')),
          ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Vérification enseignant'),
              subtitle: const Text('Préparer un futur appel en classe'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const KioskTeacherCodePage())))
        ])),
        const SizedBox(height: 12),
        _Card(
            child: Column(children: [
          ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Changer le mot de passe'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ChangePassword(user: user, localOnly: true)))),
          ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const Welcome()),
                  (route) => false)),
        ]))
      ]);
}

class KioskTeacherCodePage extends StatefulWidget {
  const KioskTeacherCodePage({Key? key}) : super(key: key);
  @override
  State<KioskTeacherCodePage> createState() => _KioskTeacherCodePageState();
}

class _KioskTeacherCodePageState extends State<KioskTeacherCodePage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
          title: const Text('Vérification enseignant'),
          backgroundColor: CustomTheme.blue),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: _Card(
            child: Column(children: [
          const Icon(Icons.badge_outlined, size: 54, color: CustomTheme.blue),
          const Text('Code enseignant'),
          TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Ex. ENS-001')),
          const SizedBox(height: 16),
          CustomButton(
              text: 'Continuer',
              onPress: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const KioskVerificationPage()))),
        ])),
      ),
    );
  }
}

class KioskVerificationPage extends StatefulWidget {
  const KioskVerificationPage({Key? key}) : super(key: key);
  @override
  State<KioskVerificationPage> createState() => _KioskVerificationPageState();
}

class _KioskVerificationPageState extends State<KioskVerificationPage> {
  bool verified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
          title: const Text('Vérification caméra'),
          backgroundColor: CustomTheme.blue),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _Card(
            child: Column(
              children: [
                const CircleAvatar(
                    radius: 44,
                    backgroundImage:
                        AssetImage('assets/images/avatar-s-19.jpg')),
                const SizedBox(height: 12),
                const Text('M. Kouame',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(verified
                    ? 'Identité vérifiée'
                    : 'Vérification caméra simulée'),
                const SizedBox(height: 18),
                CustomButton(
                    text:
                        verified ? 'Commencer l’appel' : 'Vérifier l’identité',
                    onPress: () => setState(() => verified = true)),
                if (verified)
                  TextButton(
                      onPressed: () => setState(() => verified = false),
                      child:
                          const Text('Échec de la vérification / Réessayer')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _HeaderCard(
      {required this.title, required this.subtitle, required this.icon});
  @override
  Widget build(BuildContext context) => _Card(
          child: Row(children: [
        Icon(icon, color: CustomTheme.blue, size: 38),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              Text(subtitle)
            ]))
      ]));
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem(this.label, this.value, this.icon);
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: items
            .map((item) => _ParentDashboardCard(
                  icon: item.icon,
                  title: item.value,
                  subtitle: item.label,
                  height: 108,
                  iconSize: 24,
                ))
            .toList(),
      );
}

class _DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: CustomTheme.blue, size: 30),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(summary),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          isThreeLine: summary.contains('\n'),
        ),
      );
}

class _DashboardClassCard extends StatelessWidget {
  final PrincipalDashboardClassOverview classOverview;
  final String? teacherName;
  final VoidCallback? onTap;

  const _DashboardClassCard({
    required this.classOverview,
    this.teacherName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final attendanceRate = classOverview.attendancePercentage == null
        ? '—'
        : '${classOverview.attendancePercentage}%';
    final rows = <MapEntry<String, String>>[
      MapEntry('Effectif', '${classOverview.studentCount}'),
      MapEntry('Garçons', '${classOverview.boys}'),
      MapEntry('Filles', '${classOverview.girls}'),
      MapEntry('Enseignant principal', teacherName ?? 'Non renseigné'),
      MapEntry('Total matières', '${classOverview.subjectCount}'),
      MapEntry('Séances du jour', '${classOverview.sessionsToday}'),
      MapEntry("Présence aujourd'hui", attendanceRate),
    ];

    final greyTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 10,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Image(
                  image: AssetImage('assets/images/landing6.png'),
                  height: 36,
                  width: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    classOverview.name,
                    textAlign: TextAlign.left,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: CustomTheme.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          row.key,
                          textAlign: TextAlign.left,
                          style: greyTextStyle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            row.value,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: row.key == "Présence aujourd'hui"
                                ? greyTextStyle?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _attendancePercentageColor(
                                        row.value),
                                  )
                                : greyTextStyle?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          ),
        ),
      ),
    );
  }

  Color _attendancePercentageColor(String value) {
    if (value == '—') {
      return Colors.grey.shade700;
    }

    final percentage = int.tryParse(value.replaceAll('%', '').trim());
    if (percentage == null) {
      return Colors.grey.shade700;
    }

    return percentage < 50 ? Colors.red : CustomTheme.blue;
  }
}

class _ClassCard extends StatelessWidget {
  final PrincipalClass schoolClass;
  final VoidCallback? onTap;
  const _ClassCard({required this.schoolClass, this.onTap});

  @override
  Widget build(BuildContext context) {
    final allSessions = PrincipalMockService.attendanceSessions;
    final classSessions = allSessions
        .where((session) => session.schoolClass.name == schoolClass.name)
        .toList();
    final latestDate = allSessions.isEmpty
        ? null
        : allSessions.map((session) => session.date).reduce(
            (first, second) => _isLaterDate(first, second) ? first : second);
    final daySessions = latestDate == null
        ? <PrincipalAttendanceSession>[]
        : classSessions.where((session) => session.date == latestDate).toList();
    final totalPresent =
        daySessions.fold<int>(0, (sum, session) => sum + session.present);
    final totalStudents =
        daySessions.fold<int>(0, (sum, session) => sum + session.total);
    final attendanceRate = totalStudents == 0
        ? 'Aucune donnée'
        : '${(totalPresent / totalStudents * 100).round()}%';

    final rows = <MapEntry<String, String>>[
      MapEntry('Effectif', '${schoolClass.students.length}'),
      MapEntry('Garçons', '${schoolClass.boys}'),
      MapEntry('Filles', '${schoolClass.girls}'),
      MapEntry('Enseignant principal', 'Non renseigné'),
      MapEntry('Total matières',
          '${classSessions.map((session) => session.subject).toSet().length}'),
      MapEntry('Séances du jour', '${daySessions.length}'),
      MapEntry('Taux de présence', attendanceRate),
    ];

    final greyTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 10,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image(
                    image: const AssetImage('assets/images/landing6.png'),
                    height: 36,
                    width: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      schoolClass.name,
                      textAlign: TextAlign.left,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: CustomTheme.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...rows.map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            row.key,
                            textAlign: TextAlign.left,
                            style: greyTextStyle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              row.value,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              style: row.key == 'Taux de présence'
                                  ? greyTextStyle?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _attendancePercentageColor(row.value),
                                    )
                                  : greyTextStyle?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Color _attendancePercentageColor(String value) {
    if (value == 'Aucune donnée') {
      return Colors.grey.shade700;
    }

    final cleanedValue = value.replaceAll('%', '').trim();
    final percentage = int.tryParse(cleanedValue);
    if (percentage == null) {
      return Colors.grey.shade700;
    }

    return percentage < 50 ? Colors.red : CustomTheme.blue;
  }

  bool _isLaterDate(String first, String second) {
    final firstParts = first.split('/');
    final secondParts = second.split('/');
    if (firstParts.length != 3 || secondParts.length != 3) {
      return first.compareTo(second) > 0;
    }
    final firstDate = DateTime(
      int.parse(firstParts[2]),
      int.parse(firstParts[1]),
      int.parse(firstParts[0]),
    );
    final secondDate = DateTime(
      int.parse(secondParts[2]),
      int.parse(secondParts[1]),
      int.parse(secondParts[0]),
    );
    return firstDate.isAfter(secondDate);
  }
}

class _DashboardActivityCard extends StatelessWidget {
  final String assetPath;
  final String title;
  final String subtitle;
  final String? status;
  final String? titleTrailing;
  final bool isAlert;
  final VoidCallback? onTap;
  const _DashboardActivityCard(
      {required this.assetPath,
      required this.title,
      required this.subtitle,
      this.status,
      this.titleTrailing,
      this.isAlert = false,
      this.onTap});

  @override
  Widget build(BuildContext context) => _ParentDashboardCard(
        assetPath: assetPath,
        title: title,
        subtitle: status == null ? subtitle : '$subtitle\n$status',
        titleTrailing: titleTrailing,
        onTap: onTap,
        isAlert: isAlert,
      );
}

class _ParentDashboardCard extends StatelessWidget {
  final String? assetPath;
  final IconData? icon;
  final String title;
  final String subtitle;
  final String? titleTrailing;
  final VoidCallback? onTap;
  final double height;
  final double iconSize;
  final bool isAlert;
  const _ParentDashboardCard(
      {this.assetPath,
      this.icon,
      required this.title,
      required this.subtitle,
      this.titleTrailing,
      this.onTap,
      this.height = 140,
      this.iconSize = 36,
      this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    final titleStyle = isAlert
        ? Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red.shade800,
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.headlineSmall;

    final subtitleStyle = isAlert
        ? Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            )
        : Theme.of(context).textTheme.bodySmall;

    final iconColor = isAlert ? Colors.red.shade700 : CustomTheme.blue;

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(1),
      child: Card(
        color: isAlert ? Colors.red.shade50 : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side: isAlert
              ? BorderSide(color: Colors.red.shade400, width: 1.5)
              : BorderSide.none,
        ),
        elevation: isAlert ? 3 : 10,
        child: InkWell(
          onTap: onTap,
          child: height == 108
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon ?? Icons.warning_amber_rounded,
                          color: iconColor, size: iconSize),
                      const SizedBox(height: 4),
                      Text(title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle),
                      Text(subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleStyle),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: isAlert
                          ? Icon(Icons.warning_amber_rounded,
                              color: iconColor, size: 32)
                          : icon == null
                              ? Image(
                                  image: AssetImage(assetPath!),
                                  height: 36,
                                  width: double.infinity,
                                )
                              : Icon(icon, color: iconColor, size: iconSize),
                    ),
                    ListTile(
                      title: titleTrailing == null
                          ? Text(title,
                              textAlign: TextAlign.center, style: titleStyle)
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  titleTrailing ?? '—',
                                  style: subtitleStyle?.copyWith(
                                    color: CustomTheme.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                      subtitle: Text(subtitle,
                          textAlign: TextAlign.center, style: subtitleStyle),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final PrincipalStudent student;
  final String? subtitle;
  final String? status;
  final VoidCallback? onTap;
  const _StudentTile(
      {required this.student, this.subtitle, this.status, this.onTap});
  @override
  Widget build(BuildContext context) => _Card(
      child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundImage: AssetImage(student.photo)),
          title: Text(student.name),
          subtitle: Text(subtitle ?? '${student.code} • ${student.className}'),
          trailing: status == null ? null : Text(status!)));
}

class _DashboardSessionTile extends StatelessWidget {
  final PrincipalDashboardSession session;

  const _DashboardSessionTile({required this.session});

  @override
  Widget build(BuildContext context) => _Card(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              const Icon(Icons.fact_check_outlined, color: CustomTheme.blue),
          title: Text(
            '${session.className} • ${session.subject}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${session.date} à ${session.time} • ${session.teacher}\n'
            '${session.present} présents • ${session.absent} absents • ${session.late} retards',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          trailing: Text(
            session.attendancePercentage == null
                ? 'Aucune donnée'
                : '${session.attendancePercentage}%',
            style: session.attendancePercentage == null
                ? null
                : TextStyle(
                    color: session.attendancePercentage! < 50
                        ? Colors.red
                        : CustomTheme.blue,
                    fontWeight: FontWeight.bold,
                  ),
          ),
        ),
      );
}

class _PrincipalAttendanceSessionTile extends StatelessWidget {
  final PrincipalAttendanceData session;
  final VoidCallback? onTap;

  const _PrincipalAttendanceSessionTile({
    required this.session,
    this.onTap,
  });

  String _statusLabel(String status) {
    switch (status) {
      case 'P':
        return 'Présent';
      case 'A':
        return 'Absent';
      case 'R':
        return 'Retard';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendancePercentage = session.calculatedAttendancePercentage;
    return _Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading:
              const Icon(Icons.fact_check_outlined, color: CustomTheme.blue),
          title: Text(
            '${session.className} • ${session.subject}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${session.date} à ${session.time} • ${session.teacher}\n'
            '${session.present} présents • ${session.absent} absents • ${session.late} retards',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          trailing: Text(
            attendancePercentage == null ? '—' : '$attendancePercentage%',
            style: attendancePercentage == null
                ? null
                : TextStyle(
                    color: attendancePercentage < 50
                        ? Colors.red
                        : CustomTheme.blue,
                    fontWeight: FontWeight.bold,
                  ),
          ),
        ),
      );
  }
}

class PrincipalLiveAttendanceSessionPage extends StatelessWidget {
  final PrincipalAttendanceData session;
  final String? subjectLabel;
  final bool preferApiAttendancePercentage;
  final bool showRawStatuses;

  const PrincipalLiveAttendanceSessionPage({
    Key? key,
    required this.session,
    this.subjectLabel,
    this.preferApiAttendancePercentage = false,
    this.showRawStatuses = false,
  }) : super(key: key);

  String _statusLabel(String status) {
    switch (status) {
      case 'P':
        return 'Présent';
      case 'A':
        return 'Absent';
      case 'R':
        return 'Retard';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('=== DETAIL RECEIVED SESSION IDENTITY ===');
    debugPrint('CodeClasse=${session.codeClasse}');
    debugPrint('CodeMatiere=${session.codeMatiere}');
    debugPrint('CodeEnseignement=${session.codeEnseignement}');
    debugPrint('date=${session.date}');
    debugPrint('time=${session.time}');
    debugPrint(
      'DETAIL RECEIVED: '
      'class=${session.className}, present=${session.present}, '
      'absent=${session.absent}, late=${session.late}, '
      'studentCount=${session.studentCount}, records=${session.records.length}',
    );
    for (final record in session.records) {
      debugPrint(
        'DETAIL STUDENT: '
        'code=${record.codeEleve}, '
        'name=${record.studentName}, '
        'status=${record.status}',
      );
    }
    final attendancePercentage = preferApiAttendancePercentage
        ? session.attendancePercentage ?? session.calculatedAttendancePercentage
        : session.calculatedAttendancePercentage;
    return Scaffold(
        backgroundColor: CustomTheme.grey,
        appBar: AppBar(
          title: const Text('Détail de la présence'),
          backgroundColor: CustomTheme.blue,
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Detail('Date', session.date),
                  _Detail('Heure', session.time),
                  _Detail('Classe', session.className),
                  _Detail('Matière', subjectLabel ?? session.subject),
                  _Detail('Enseignant', session.teacher),
                  _Detail(
                    preferApiAttendancePercentage ? 'Total élèves' : 'Élèves',
                    '${session.studentCount}',
                  ),
                  _Detail('Présents', '${session.present}'),
                  _Detail('Absents', '${session.absent}'),
                  _Detail('Retards', '${session.late}'),
                  _Detail(
                    'Présence',
                    attendancePercentage == null
                        ? '—'
                        : '$attendancePercentage%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionTitle('Élèves'),
            ...session.records.map((record) => _Card(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(record.studentName.isEmpty
                        ? record.codeEleve
                        : record.studentName),
                    subtitle: Text(record.codeEleve),
                    trailing: Text(showRawStatuses
                      ? record.status
                      : _statusLabel(record.status)),
                  ),
                )),
          ],
        ),
        );
      }
}

class _SessionTile extends StatelessWidget {
  final PrincipalAttendanceSession session;
  final VoidCallback? onTap;

  const _SessionTile({required this.session, this.onTap});

  @override
  Widget build(BuildContext context) => _Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading:
              const Icon(Icons.fact_check_outlined, color: CustomTheme.blue),
          title: Text(
            '${session.schoolClass.name} • ${session.subject}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${session.date} à ${session.time} • ${session.teacher}\n'
            '${session.present} présents • ${session.absent} absents • ${session.late} retards',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          trailing: Text(
            session.attendance == null
                ? 'Aucune donnée'
                : '${(session.attendance! * 100).round()}%',
            style: session.attendance == null
                ? null
                : TextStyle(
                    color: (session.attendance! * 100).round() < 50
                        ? Colors.red
                        : CustomTheme.blue,
                    fontWeight: FontWeight.bold,
                  ),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall));
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: CustomTheme.cardShadow),
      child: child);
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;
  const _Detail(this.label, this.value, {this.labelColor, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 125,
            child: Text(label,
                style: TextStyle(
                    color: labelColor ?? Colors.black87,
                    fontWeight: FontWeight.w500))),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? Colors.black87,
                    fontWeight: FontWeight.bold)))
      ]));
}
