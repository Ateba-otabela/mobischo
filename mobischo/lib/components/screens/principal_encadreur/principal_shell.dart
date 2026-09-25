import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/changePassword.dart';
import 'package:mobischo/components/screens/layouts/customMenu.dart';
import 'package:mobischo/models/user.dart';
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
    'Mobischo',
    'Toutes les classes',
    'Présence',
    'Profil',
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
        ),
        PrincipalAttendancePage(user: widget.user),
        PrincipalProfilePage(user: widget.user),
      ],
      principalIcons: const [
        Icon(Icons.home),
        Icon(Icons.class_outlined),
        Icon(Icons.fact_check_outlined),
        Icon(Icons.person_outline),
      ],
      principalSecondaryTitles: const [
        'Signalements des parents',
        'Alertes de présence',
        'Appels des professeurs',
      ],
      principalSecondaryScreens: const [
        PrincipalReportsPage(),
        PrincipalAlertsPage(),
        PrincipalCallsPage(),
      ],
    );
  }
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
      _StatsGrid(items: [
        _StatItem('Classes', dashboard.classes.toString(), Icons.class_outlined),
        _StatItem('Professeurs', dashboard.teachers.toString(), Icons.person_outline),
        _StatItem('Élèves', dashboard.students.toString(), Icons.groups_outlined),
        _StatItem(
            'Présence',
            dashboard.todayAttendancePercentage == null
                ? 'Aucune donnée'
                : '${dashboard.todayAttendancePercentage}%',
            Icons.check_circle_outline)
      ]),
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
      _SectionTitle('Alertes récentes'),
      _DashboardActivityCard(
        assetPath: 'assets/images/landing5.png',
        title: 'Différence de présence à vérifier',
        subtitle: 'Aminata Diallo • 24/09/2026',
        status: 'À vérifier',
        isAlert: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AlertDetailPage()),
        ),
      ),
      const SizedBox(height: 8),
      _SectionTitle('Signalements des parents'),
      ...PrincipalMockService.reports.take(2).map((item) =>
          _DashboardActivityCard(
              assetPath: 'assets/images/landing2.png',
              title: item.student.name,
              subtitle: '${item.reason} • ${item.date}',
              status: item.status,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ParentReportDetailPage(report: item))))),
      const SizedBox(height: 8),
      _SectionTitle('Appels récents des professeurs'),
      if (recentSessions.isEmpty)
        const _Card(child: Text('Aucune session de présence enregistrée.'))
      else ...[
        ...recentSessions.take(3).map((session) => _DashboardActivityCard(
              assetPath: 'assets/images/landing3.png',
              title: '${session.className} • ${session.subject}',
              subtitle:
                  '${session.date} à ${session.time} • ${session.teacher}',
              status: session.attendancePercentage == null
                  ? '—'
                  : '${session.attendancePercentage}%',
            )),
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

  const PrincipalClassesPage({
    Key? key,
    required this.dashboardFuture,
    required this.onRetryDashboard,
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
                title: 'Toutes les classes',
                subtitle: 'Accès à toutes les classes de l’établissement',
                icon: Icons.class_outlined),
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
                    ),
                  )),
          ],
        );
      },
    );
  }
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

class PrincipalReportsPage extends StatelessWidget {
  const PrincipalReportsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _HeaderCard(
            title: 'Signalements des parents',
            subtitle: 'Consultation des signalements reçus',
            icon: Icons.message_outlined),
        const SizedBox(height: 12),
        ...PrincipalMockService.reports.map((report) => _Card(
              child: ListTile(
                title: Text(report.student.name),
                subtitle: Text(
                    '${report.student.className} • ${report.parent}\n${report.date} • ${report.reason}'),
                isThreeLine: true,
                trailing: Text(report.status),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ParentReportDetailPage(report: report))),
              ),
            )),
      ],
    );
  }
}

class ParentReportDetailPage extends StatelessWidget {
  final ParentReport report;
  const ParentReportDetailPage({Key? key, required this.report})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
          title: const Text('Détail du signalement'),
          backgroundColor: CustomTheme.blue),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        _Card(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Detail('Élève', report.student.name),
          _Detail('Classe', report.student.className),
          _Detail('Parent', report.parent),
          _Detail('Date', report.date),
          _Detail('Motif', report.reason),
          _Detail('Message', report.message),
          _Detail('Statut', report.status),
        ])),
        const SizedBox(height: 14),
        CustomButton(
            text: 'Vérifier',
            onPress: () {
              report.status = 'Vérifiée';
              Navigator.pop(context);
            }),
        const SizedBox(height: 8),
        OutlinedButton(
            onPressed: () {
              report.status = 'Rejetée';
              Navigator.pop(context);
            },
            child: const Text('Rejeter')),
      ]),
    );
  }
}

class PrincipalAlertsPage extends StatelessWidget {
  const PrincipalAlertsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _HeaderCard(
            title: 'Alertes de présence',
            subtitle:
                'Consultez ici les présences nécessitant une vérification.',
            icon: Icons.info_outline),
        const SizedBox(height: 12),
        Card(
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
              'Présence nécessitant une vérification',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Aminata Diallo • Parent : Absent • Appel professeur : Présent',
              style: TextStyle(color: Colors.red.shade700),
            ),
            trailing: Text(
              'À vérifier',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AlertDetailPage())),
          ),
        ),
      ],
    );
  }
}

class AlertDetailPage extends StatelessWidget {
  const AlertDetailPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
          title: const Text('Détail de l’alerte'),
          backgroundColor: CustomTheme.blue),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _SectionTitle('Signalement du parent'),
          _Card(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _Detail('Élève', 'Aminata Diallo',
                    labelColor: Colors.grey.shade700,
                    valueColor: Colors.grey.shade700),
                _Detail('Date', '24/09/2026',
                    labelColor: Colors.grey.shade700,
                    valueColor: Colors.grey.shade700),
                _Detail('Motif', 'Maladie',
                    labelColor: Colors.grey.shade700,
                    valueColor: Colors.grey.shade700),
                _Detail('Message', 'Aminata sera absente ce matin.',
                    labelColor: Colors.grey.shade700,
                    valueColor: Colors.grey.shade700),
              ])),
          const SizedBox(height: 12),
          _SectionTitle('Appel du professeur'),
          _Card(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _Detail('Enseignant', 'M. Kouame',
                    labelColor: Colors.grey.shade700,
                    valueColor: Colors.grey.shade700),
                _Detail('Classe', '6e A',
                    labelColor: Colors.grey.shade700,
                    valueColor: Colors.grey.shade700),
                _Detail('Matière', 'Mathématiques',
                    labelColor: Colors.grey.shade700,
                    valueColor: Colors.grey.shade700),
                _Detail('Date', '24/09/2026',
                    labelColor: Colors.grey.shade700,
                    valueColor: Colors.grey.shade700),
                _Detail('Heure', '08:05',
                    labelColor: Colors.grey.shade700,
                    valueColor: Colors.grey.shade700),
                _Detail('Statut enregistré', 'Présent',
                    labelColor: Colors.grey.shade700,
                    valueColor: Colors.grey.shade700),
              ])),
          const SizedBox(height: 12),
          _Card(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Différence détectée',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Une différence a été détectée entre le signalement du parent et l’appel de présence. Une vérification est nécessaire.',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  'La présence déclarée par le parent diffère de l’appel du professeur et doit être vérifiée.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ])),
          const SizedBox(height: 12),
          CustomButton(text: 'Vérifier', onPress: () => Navigator.pop(context)),
          OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Rejeter')),
        ],
      ),
    );
  }
}

class PrincipalCallsPage extends StatefulWidget {
  const PrincipalCallsPage({Key? key}) : super(key: key);
  @override
  State<PrincipalCallsPage> createState() => _PrincipalCallsPageState();
}

class _PrincipalCallsPageState extends State<PrincipalCallsPage> {
  String classFilter = 'Toutes les classes';
  String teacherFilter = '';

  @override
  Widget build(BuildContext context) {
    final calls = PrincipalMockService.calls.where((call) {
      return (classFilter == 'Toutes les classes' ||
              call.schoolClass.name == classFilter) &&
          (teacherFilter.isEmpty ||
              call.teacher.toLowerCase().contains(teacherFilter.toLowerCase()));
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
            value: 'Toutes les classes',
            decoration: const InputDecoration(labelText: 'Classe'),
            items: [
              'Toutes les classes',
              ...PrincipalMockService.classes.map((item) => item.name)
            ]
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) =>
                setState(() => classFilter = value ?? classFilter)),
        TextField(
            decoration: const InputDecoration(labelText: 'Enseignant'),
            onChanged: (value) => setState(() => teacherFilter = value))
      ])),
      const SizedBox(height: 10),
      if (calls.isEmpty)
        const _Card(child: Text('Aucun appel ne correspond aux filtres.'))
      else
        ...calls.map((call) => _CallTile(
            call: call,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TeacherCallDetailPage(call: call)))))
    ]);
  }
}

class TeacherCallDetailPage extends StatelessWidget {
  final TeacherCall call;
  const TeacherCallDetailPage({Key? key, required this.call}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
          title: const Text('Détail de l’appel'),
          backgroundColor: CustomTheme.blue),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        _Card(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Detail('Enseignant', call.teacher),
          _Detail('Classe', call.schoolClass.name),
          _Detail('Matière', call.subject),
          _Detail('Date', call.date),
          _Detail('Heure', call.time),
          _Detail('Statut', call.status)
        ])),
        const SizedBox(height: 12),
        const _Card(
            child: Text('Présence physique du professeur : Non vérifiée')),
        const SizedBox(height: 12),
        _SectionTitle('Présence des élèves'),
        ...call.schoolClass.students.map((student) => _StudentTile(
            student: student,
            status: student.absent > 0 ? 'Absent' : 'Présent'))
      ]));
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

class _DashboardClassCard extends StatelessWidget {
  final PrincipalDashboardClassOverview classOverview;
  final String? teacherName;

  const _DashboardClassCard({required this.classOverview, this.teacherName});

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
                            style: row.key == 'Taux de présence'
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
  final String status;
  final bool isAlert;
  final VoidCallback? onTap;
  const _DashboardActivityCard(
      {required this.assetPath,
      required this.title,
      required this.subtitle,
      required this.status,
      this.isAlert = false,
      this.onTap});

  @override
  Widget build(BuildContext context) => _ParentDashboardCard(
        assetPath: assetPath,
        title: title,
        subtitle: '$subtitle\n$status',
        onTap: onTap,
        isAlert: isAlert,
      );
}

class _ParentDashboardCard extends StatelessWidget {
  final String? assetPath;
  final IconData? icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final double height;
  final double iconSize;
  final bool isAlert;
  const _ParentDashboardCard(
      {this.assetPath,
      this.icon,
      required this.title,
      required this.subtitle,
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
                      title: Text(title,
                          textAlign: TextAlign.center, style: titleStyle),
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

class _CallTile extends StatelessWidget {
  final TeacherCall call;
  final VoidCallback? onTap;
  const _CallTile({required this.call, this.onTap});
  @override
  Widget build(BuildContext context) => _Card(
      child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading:
              const Icon(Icons.assignment_outlined, color: CustomTheme.blue),
          title: Text('${call.schoolClass.name} • ${call.subject}'),
          subtitle: Text(
              '${call.date} à ${call.time} • ${call.teacher}\n${call.schoolClass.students.length} élèves'),
          isThreeLine: true,
          trailing: const Text('Appel effectué')));
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

  const PrincipalLiveAttendanceSessionPage({
    Key? key,
    required this.session,
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
    final attendancePercentage = session.calculatedAttendancePercentage;
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
                  _Detail('Matière', session.subject),
                  _Detail('Enseignant', session.teacher),
                  _Detail('Élèves', '${session.studentCount}'),
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
                    trailing: Text(_statusLabel(record.status)),
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
