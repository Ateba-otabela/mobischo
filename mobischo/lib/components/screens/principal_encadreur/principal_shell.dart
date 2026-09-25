import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/changePassword.dart';
import 'package:mobischo/components/screens/layouts/customMenu.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/welcome.dart';
import 'principal_mock.dart';

class PrincipalShell extends StatefulWidget {
  const PrincipalShell({Key? key}) : super(key: key);
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

  final principalUser = User(
    nom: 'Principal',
    prenom: 'Encadreur',
    contacts: '',
    sex: '',
    email: '',
    login: 'principal.demo',
    code: 'principal-local',
    account_type: 'principal_encadreur',
    text_password: '',
    address: '',
    admin: '0',
    CodeEtablissement: 'local',
  );

  @override
  Widget build(BuildContext context) {
    return CustomMenu(
      user: principalUser,
      selectedPage: 0,
      principalTitles: titles,
      principalScreens: [
        PrincipalDashboardPage(),
        PrincipalClassesPage(),
        PrincipalAttendancePage(),
        PrincipalProfilePage(user: principalUser),
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

class PrincipalDashboardPage extends StatelessWidget {
  const PrincipalDashboardPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final classes = PrincipalMockService.classes;
    final students = classes.expand((item) => item.students).toList();
    final sessions = PrincipalMockService.attendanceSessions;
    final present = sessions.fold<int>(0, (sum, item) => sum + item.present);
    final absent = sessions.fold<int>(0, (sum, item) => sum + item.absent);
    final late = sessions.fold<int>(0, (sum, item) => sum + item.late);
    final total = sessions.fold<int>(0, (sum, item) => sum + item.total);
    final teacherCount =
        PrincipalMockService.calls.map((call) => call.teacher).toSet().length;
    final attendancePercentage = total == 0 ? null : (present / total * 100).round();
    return ListView(padding: const EdgeInsets.all(14), children: [
      _HeaderCard(
          title: 'Principal — Encadreur',
          subtitle: 'Toutes les classes',
          icon: Icons.admin_panel_settings_outlined),
      const SizedBox(height: 12),
      _StatsGrid(items: [
        _StatItem('Classes', classes.length.toString(), Icons.class_outlined),
        _StatItem('Professeurs', teacherCount.toString(), Icons.person_outline),
        _StatItem('Élèves', students.length.toString(), Icons.groups_outlined),
        _StatItem(
            'Présence',
            attendancePercentage == null ? 'Aucune donnée' : '$attendancePercentage%',
            Icons.check_circle_outline)
      ]),
      const SizedBox(height: 12),
      _SectionTitle('Présence générale'),
      _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            attendancePercentage == null
                ? 'Aucune donnée'
                : '$attendancePercentage%',
            style: Theme.of(context).textTheme.headlineLarge),
        if (attendancePercentage != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: present / total, minHeight: 9, color: CustomTheme.blue),
          const SizedBox(height: 6),
          Text('$present présents • $absent absents • $late retards')
        ]
      ])),
      const SizedBox(height: 14),
      _SectionTitle('Appels du jour'),
      if (sessions.isEmpty)
        const _Card(child: Text('Aucune session de présence enregistrée.'))
      else
        ...sessions.map((session) => _SessionTile(
              session: session,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PrincipalAttendanceSessionPage(session: session))),
            )),
      const SizedBox(height: 14),
      _SectionTitle('Vue d’ensemble des classes'),
      ...classes.map((item) => _ClassCard(
          schoolClass: item,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      PrincipalClassDetailPage(schoolClass: item))))),
      const SizedBox(height: 8),
      _SectionTitle('Alertes récentes'),
        _DashboardActivityCard(
          assetPath: 'assets/images/landing5.png',
          title: 'Différence de présence à vérifier',
          subtitle: 'Aminata Diallo • 24/09/2026',
          status: 'À vérifier',
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AlertDetailPage()))),
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
      ...PrincipalMockService.calls.take(2).map((item) =>
          _DashboardActivityCard(
              assetPath: 'assets/images/landing3.png',
              title: '${item.schoolClass.name} • ${item.subject}',
              subtitle: '${item.date} à ${item.time} • ${item.teacher}',
                status: 'Appel effectué',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherCallDetailPage(call: item))))),
    ]);
  }
}

class PrincipalClassesPage extends StatefulWidget {
  const PrincipalClassesPage({Key? key}) : super(key: key);
  @override
  State<PrincipalClassesPage> createState() => _PrincipalClassesPageState();
}

class _PrincipalClassesPageState extends State<PrincipalClassesPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final classes = PrincipalMockService.classes.where((schoolClass) {
      final normalizedQuery = query.toLowerCase();
      return normalizedQuery.isEmpty ||
          schoolClass.name.toLowerCase().contains(normalizedQuery) ||
          schoolClass.students.any((student) =>
              student.name.toLowerCase().contains(normalizedQuery));
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
            labelText: 'Rechercher une classe ou un élève',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 12),
        if (classes.isEmpty)
          const _Card(child: Text('Aucune classe ne correspond à la recherche.'))
        else
          ...classes.map((item) => _ClassCard(
              schoolClass: item,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PrincipalClassDetailPage(schoolClass: item)))))
      ],
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
  const PrincipalAttendancePage({Key? key}) : super(key: key);
  @override
  State<PrincipalAttendancePage> createState() =>
      _PrincipalAttendancePageState();
}

class _PrincipalAttendancePageState extends State<PrincipalAttendancePage> {
  String classFilter = 'Toutes les classes';
  String subjectFilter = 'Toutes les matières';
  String teacherFilter = 'Tous les enseignants';
  String statusFilter = 'Tous les statuts';
  String? dateFilter;

  Future<void> _selectDate() async {
    final initialDate = dateFilter == null
        ? DateTime(2026, 9, 24)
        : _parseDate(dateFilter!);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) return;
    setState(() => dateFilter = _formatDate(selectedDate));
  }

  DateTime _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }
    return DateTime(2026, 9, 24);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final allSessions = PrincipalMockService.attendanceSessions;
    final classSessions = classFilter == 'Toutes les classes'
        ? allSessions
        : allSessions
            .where((session) => session.schoolClass.name == classFilter)
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
    if (!subjectOptions.contains(subjectFilter)) {
      subjectFilter = 'Toutes les matières';
    }
    if (!teacherOptions.contains(teacherFilter)) {
      teacherFilter = 'Tous les enseignants';
    }
    final sessions = subjectSessions.where((session) {
      final hasStatus = statusFilter == 'Tous les statuts' ||
          session.records.any((record) => record.status == statusFilter);
      return (dateFilter == null || session.date == dateFilter) &&
          (teacherFilter == 'Tous les enseignants' ||
              session.teacher == teacherFilter) &&
          hasStatus;
    }).toList();
    return ListView(padding: const EdgeInsets.all(14), children: [
      _HeaderCard(
          title: 'Présence',
          subtitle: 'Suivi de toutes les classes',
          icon: Icons.fact_check_outlined),
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
              onPressed: () => setState(() => dateFilter = null),
            ),
          onTap: _selectDate,
        ),
        DropdownButtonFormField<String>(
            value: classFilter,
            decoration: const InputDecoration(labelText: 'Classe'),
          items: <String>{
            'Toutes les classes',
            ...allSessions.map((session) => session.schoolClass.name),
          }
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
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
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
          onChanged: (value) => setState(() {
            subjectFilter = value!;
            teacherFilter = 'Tous les enseignants';
          })),
        DropdownButtonFormField<String>(
          value: teacherFilter,
          decoration: const InputDecoration(labelText: 'Enseignant'),
          items: teacherOptions
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
          onChanged: (value) => setState(() => teacherFilter = value!)),
        DropdownButtonFormField<String>(
            value: statusFilter,
            decoration: const InputDecoration(labelText: 'Statut'),
            items: [
              'Tous les statuts',
              'Présent',
              'Absent',
              'Retard',
              'À vérifier'
            ]
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => statusFilter = value!))
      ])),
      const SizedBox(height: 12),
      if (sessions.isEmpty)
        const _Card(child: Text('Aucune session ne correspond aux filtres.'))
      else
        ...sessions.map((session) => _SessionTile(
              session: session,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PrincipalAttendanceSessionPage(session: session))),
            ))
    ]);
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
                  subtitle: '${record.student.code} • ${record.student.className}',
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
            subtitle: 'Différences nécessitant une vérification',
            icon: Icons.warning_amber_outlined),
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
                _Detail('Élève', 'Aminata Diallo'),
                _Detail('Date', '24/09/2026'),
                _Detail('Motif', 'Maladie'),
                _Detail('Message', 'Aminata sera absente ce matin.'),
              ])),
          const SizedBox(height: 12),
          _SectionTitle('Appel du professeur'),
          _Card(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _Detail('Enseignant', 'M. Kouame'),
                _Detail('Classe', '6e A'),
                _Detail('Matière', 'Mathématiques'),
                _Detail('Date', '24/09/2026'),
                _Detail('Heure', '08:05'),
                _Detail('Statut enregistré', 'Présent'),
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
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
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
        ]))
              ,
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
        : allSessions
            .map((session) => session.date)
            .reduce((first, second) => _isLaterDate(first, second) ? first : second);
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

    return _ParentDashboardCard(
      assetPath: 'assets/images/landing6.png',
      title: schoolClass.name,
      height: 220,
      subtitle: 'Effectif : ${schoolClass.students.length}\n'
          'Garçons : ${schoolClass.boys} • Filles : ${schoolClass.girls}\n'
          'Enseignant principal : Non renseigné\n'
          'Total matières : ${classSessions.map((session) => session.subject).toSet().length}\n'
          'Séances du jour : ${daySessions.length}\n'
          'Taux de présence : $attendanceRate',
      onTap: onTap,
    );
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
    final VoidCallback? onTap;
  const _DashboardActivityCard(
      {required this.assetPath,
      required this.title,
      required this.subtitle,
      required this.status,
      this.onTap});

  @override
  Widget build(BuildContext context) => _ParentDashboardCard(
        assetPath: assetPath,
        title: title,
        subtitle: '$subtitle\n$status',
        onTap: onTap,
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
  const _ParentDashboardCard(
      {this.assetPath,
      this.icon,
      required this.title,
      required this.subtitle,
      this.onTap,
      this.height = 140,
      this.iconSize = 36});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.all(1),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          elevation: 10,
          child: InkWell(
            onTap: onTap,
            child: height == 108
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: CustomTheme.blue, size: iconSize),
                        const SizedBox(height: 4),
                        Text(title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: icon == null
                            ? Image(
                                image: AssetImage(assetPath!),
                                height: 36,
                                width: double.infinity)
                            : Icon(icon,
                                color: CustomTheme.blue, size: iconSize),
                      ),
                      ListTile(
                        title: Text(title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall),
                        subtitle: Text(subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
          ),
        ),
      );
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

class _SessionTile extends StatelessWidget {
  final PrincipalAttendanceSession session;
  final VoidCallback? onTap;

  const _SessionTile({required this.session, this.onTap});

  @override
  Widget build(BuildContext context) => _Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.fact_check_outlined, color: CustomTheme.blue),
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
  const _Detail(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 125, child: Text(label)),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold)))
      ]));
}
