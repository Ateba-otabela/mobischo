import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/components/screens/encardreur/chooseStudents.dart';
import 'package:mobischo/components/screens/changePassword.dart';
import 'package:mobischo/components/screens/layouts/customMenu.dart';
import 'package:mobischo/components/screens/mobischo_ai.dart';
import 'package:mobischo/components/screens/principal_encadreur/principal_students.dart';
import 'package:mobischo/components/screens/students/ClassStudents.dart';
import 'package:mobischo/components/screens/teachers.dart/CreateConvocation.dart';
import 'package:mobischo/models/class.dart';
import 'package:mobischo/models/convocation.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/services/academic_services.dart';
import 'package:mobischo/services/principal_service.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/welcome.dart';
import 'package:url_launcher/url_launcher.dart';
import 'principal_mock.dart';

class PrincipalShell extends StatefulWidget {
  final User user;

  const PrincipalShell({Key? key, required this.user}) : super(key: key);
  @override
  State<PrincipalShell> createState() => _PrincipalShellState();
}

class _PrincipalShellState extends State<PrincipalShell> {
  List<String> _titles(BuildContext context) => [
        'MOBISCHO',
        uiText(context, 'classes'),
        uiText(context, 'presence'),
        uiText(context, 'ai'),
      ];

  List<String> _secondaryTitles(BuildContext context) => [
        uiText(context, 'teacherReports'),
        uiText(context, 'investigationAlerts'),
        uiText(context, 'teacherCalls'),
        uiText(context, 'convoke'),
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
      principalTitles: _titles(context),
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
            title: uiText(context, 'studentListNav'),
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
      principalSecondaryTitles: _secondaryTitles(context),
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
            print(
                '[PrincipalDashboard] Future error type: ${snapshot.error.runtimeType}');
            print(
                '[PrincipalDashboard] Future error message: ${snapshot.error}');
          } else {
            print(
                '[PrincipalDashboard] Future completed without dashboard data');
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(uiText(context, 'principalDashboardLoadError')),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: widget.onRetryDashboard,
                    child: Text(uiText(context, 'retry')),
                  ),
                ],
              ),
            ),
          );
        }

        return FutureBuilder<List<PrincipalAttendanceData>>(
          future: _attendanceFuture,
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (attendanceSnapshot.hasError || !attendanceSnapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(uiText(context, 'principalAttendanceLoadError')),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _attendanceFuture =
                                PrincipalService.getPrincipalAttendance(
                                    widget.user);
                          });
                        },
                        child: Text(uiText(context, 'retry')),
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

  Widget _buildDashboard(BuildContext context, PrincipalDashboardData dashboard,
      List<PrincipalAttendanceData> attendanceSessions) {
    final recentSessions = [...attendanceSessions]..sort((first, second) {
        final dateComparison = second.date.compareTo(first.date);
        if (dateComparison != 0) return dateComparison;
        return second.time.compareTo(first.time);
      });

    return ListView(padding: const EdgeInsets.all(14), children: [
      _HeaderCard(
          title: widget.user.account_type.toLowerCase() == 'encadreur'
              ? uiText(context, 'encadreur')
              : uiText(context, 'principal'),
          subtitle: widget.user.account_type.toLowerCase() == 'encadreur'
              ? uiText(context, 'assignedClasses')
              : uiText(context, 'allSchoolClasses'),
          icon: Icons.admin_panel_settings_outlined),
      const SizedBox(height: 12),
      _DashboardActionCard(
        icon: Icons.class_outlined,
        title: uiText(context, 'classes'),
        summary: '${dashboard.classes} ${uiText(context, 'classes')}\n'
            '${uiText(context, 'classesWithSessionsToday', parameters: <String, String>{
              'count':
                  '${dashboard.classOverview.where((item) => item.sessionsToday > 0).length}'
            })}',
        onTap: () => PrincipalTabRequest(1).dispatch(context),
      ),
      _DashboardActionCard(
        icon: Icons.groups_outlined,
        title: uiText(context, 'studentListNav'),
        summary: uiText(
          context,
          'studentNumbersSummary',
          parameters: <String, String>{
            'count': '${dashboard.students}',
            'boys':
                '${dashboard.classOverview.fold<int>(0, (total, item) => total + item.boys)}',
            'girls':
                '${dashboard.classOverview.fold<int>(0, (total, item) => total + item.girls)}',
          },
        ),
        onTap: () => PrincipalSectionRequest(
          title: uiText(context, 'studentListNav'),
          screen: PrincipalStudentClassesPage(user: widget.user),
        ).dispatch(context),
      ),
      _DashboardActionCard(
        icon: Icons.person_outline,
        title: uiText(context, 'teachers'),
        summary: '${dashboard.teachers} ${uiText(context, 'teachers')}\n'
            '${uiText(context, 'teacherCallsRecordedToday', parameters: <String, String>{
              'count': '${dashboard.todaySessions.length}'
            })}',
        onTap: () => PrincipalSectionRequest(
          title: uiText(context, 'teachers'),
          screen: PrincipalTeacherClassesPage(
            user: widget.user,
            onSelectTeacher: (schoolClass, teacher) {
              PrincipalSectionRequest(
                title: teacher.fullName,
                screen: PrincipalTeacherCallsPage(
                  user: widget.user,
                  teacherName: teacher.fullName,
                  teacherCode: teacher.code,
                  classCode: schoolClass.codeClasse,
                ),
              ).dispatch(context);
            },
          ),
        ).dispatch(context),
      ),
      _DashboardActionCard(
        icon: Icons.fact_check_outlined,
        title: uiText(context, 'presence'),
        summary: uiText(
          context,
          'todayAttendanceSummary',
          parameters: <String, String>{
            'present':
                '${dashboard.todaySessions.fold<int>(0, (total, item) => total + item.present)}',
            'absent':
                '${dashboard.todaySessions.fold<int>(0, (total, item) => total + item.absent)}',
            'late':
                '${dashboard.todaySessions.fold<int>(0, (total, item) => total + item.late)}',
            'percentage': dashboard.todayAttendancePercentage == null
                ? '—'
                : '${dashboard.todayAttendancePercentage}%',
          },
        ),
        onTap: () => PrincipalTabRequest(2).dispatch(context),
      ),
      const SizedBox(height: 14),
      _SectionTitle(uiText(context, 'alertsAndNotifications')),
      _DashboardRecentAlerts(
        user: widget.user,
        onViewAll: () => PrincipalSectionRequest(
          title: uiText(context, 'investigationAlerts'),
          screen: PrincipalAlertsPage(user: widget.user),
        ).dispatch(context),
      ),
      const SizedBox(height: 14),
      _SectionTitle(uiText(context, 'recentJustifications')),
      _DashboardRecentJustifications(
        onViewAll: () => PrincipalSectionRequest(
          title: uiText(context, 'recentJustifications'),
          screen: const DashboardJustificationsPage(),
        ).dispatch(context),
      ),
      const SizedBox(height: 14),
      _SectionTitle(uiText(context, 'callsToday')),
      if (dashboard.todaySessions.isEmpty)
        _Card(child: Text(uiText(context, 'noAttendanceSession')))
      else
        ...dashboard.todaySessions.map((session) => _DashboardSessionTile(
              session: session,
            )),
      const SizedBox(height: 14),
      _SectionTitle(uiText(context, 'classOverview')),
      if (dashboard.classOverview.isEmpty)
        _Card(child: Text(uiText(context, 'noClassAvailable')))
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
            label: Text(uiText(context, 'viewMore')),
          ),
        ),
      const SizedBox(height: 8),
      const SizedBox(height: 8),
      _SectionTitle(uiText(context, 'recentTeacherCalls')),
      if (recentSessions.isEmpty)
        _Card(child: Text(uiText(context, 'noAttendanceSession')))
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
            label: Text(uiText(context, 'viewMore')),
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
                  Text(uiText(context, 'classesLoadError')),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: widget.onRetryDashboard,
                    child: Text(uiText(context, 'retry')),
                  ),
                ],
              ),
            ),
          );
        }

        final classes =
            (snapshot.data?.classOverview ?? []).where((schoolClass) {
          final normalizedQuery = query.toLowerCase();
          return normalizedQuery.isEmpty ||
              schoolClass.name.toLowerCase().contains(normalizedQuery);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _HeaderCard(
              title: widget.headerTitle == 'Classes'
                  ? uiText(context, 'classes')
                  : widget.headerTitle,
              subtitle: widget.headerSubtitle ==
                      'Accès à toutes les classes de l’établissement'
                  ? uiText(context, 'classAccessDescription')
                  : widget.headerSubtitle,
              icon: Icons.class_outlined,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: uiText(context, 'searchClass'),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 12),
            if (classes.isEmpty)
              _Card(child: Text(uiText(context, 'classSearchEmpty')))
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
  final void Function(
          PrincipalClassSummary schoolClass, PrincipalClassTeacher teacher)?
      onSelectTeacher;

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
  Widget build(BuildContext context) =>
      FutureBuilder<List<PrincipalClassSummary>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(uiText(context, 'classesLoadError')));
          }

          final classes = snapshot.data ?? <PrincipalClassSummary>[];
          return ListView(
            padding: const EdgeInsets.all(14),
            children: classes.isEmpty
                ? [_Card(child: Text(uiText(context, 'noTeacherAvailable')))]
                : classes
                    .map((schoolClass) => _Card(
                          child: ExpansionTile(
                            title: Text(schoolClass.name),
                            subtitle: Text(uiText(
                              context,
                              'teacherCount',
                              parameters: <String, String>{
                                'count': '${schoolClass.teachers.length}',
                              },
                            )),
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
                                          : () {
                                              print(
                                                'SELECTED TEACHER CODE: ${teacher.code}',
                                              );
                                              widget.onSelectTeacher!(
                                                  schoolClass, teacher);
                                            },
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
  final User user;
  final String teacherName;
  final String teacherCode;
  final String classCode;

  const PrincipalTeacherCallsPage({
    Key? key,
    required this.user,
    required this.teacherName,
    required this.teacherCode,
    required this.classCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<PrincipalTeacherPresenceData>>(
        future: _loadTeacherPresenceHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(uiText(context, 'teacherAttendanceLoadError')),
            );
          }

          final sessions = snapshot.data ?? <PrincipalTeacherPresenceData>[];
          return ListView(
            padding: const EdgeInsets.all(14),
            children: sessions.isEmpty
                ? [
                    _Card(
                      child: Text(uiText(context, 'teacherNoAttendance')),
                    ),
                  ]
                : sessions
                    .map((session) => _Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.fact_check_outlined,
                              color: CustomTheme.blue,
                            ),
                            title: Text(
                              '${_teacherPresenceDate(session.date)}'
                              '${session.recordedAt.isEmpty ? '' : ' • ${_teacherPresenceTime(session.recordedAt)}'}'
                              ' • ${session.subject}',
                            ),
                            subtitle: Text(
                              '${session.studentName} (${session.studentCode})\n'
                              '${session.className} • ${uiText(context, 'schoolYear')} '
                              '${session.academicYear}',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              uiText(context, session.presenceLabelKey),
                              style: TextStyle(
                                color: session.presenceStatus.toLowerCase() ==
                                            'p' ||
                                        session.presenceStatus.toLowerCase() ==
                                            'present'
                                    ? Colors.green.shade700
                                    : session.presenceStatus.toLowerCase() ==
                                                'r' ||
                                            session.presenceStatus
                                                    .toLowerCase() ==
                                                'late'
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
          );
        },
      );

  Future<List<PrincipalTeacherPresenceData>> _loadTeacherPresenceHistory() {
    print('TEACHER DETAIL LOADER: PrincipalTeacherCallsPage');
    return PrincipalService.getTeacherPresenceHistory(
      user,
      teacherCode: teacherCode,
      classCode: classCode,
    );
  }

  String _teacherPresenceDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String _teacherPresenceTime(String recordedAt) {
    final parsed = DateTime.tryParse(recordedAt);
    return parsed == null ? recordedAt : DateFormat('HH:mm').format(parsed);
  }
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
        title: uiText(context, 'classSelectionTitle'),
        screen: PrincipalConvocationClassesPage(
          user: user,
          onSelectClass: (classContext, schoolClass) {
            PrincipalSectionRequest(
              title: uiText(context, 'conveneStudents'),
              screen: ChooseStudents(
                classe: schoolClass,
                user: user,
                embedded: true,
                onCreateStudents: (createContext, selectedStudents) {
                  Navigator.of(createContext).push(
                    MaterialPageRoute(
                      builder: (_) => CreateConvocation(
                        user: user,
                        students: selectedStudents,
                        initialStudentCodes: selectedStudents
                            .map((student) => student.CodeEleve)
                            .toList(),
                        codeClasse: schoolClass.CodeClasse,
                        appBarTitle:
                            localizedMenuTitle(createContext, 'Convocation'),
                        useClassCourses: true,
                      ),
                    ),
                  );
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
            _HeaderCard(
              title: uiText(context, 'recentConvocations'),
              subtitle: uiText(context, 'convocationSentToStudents'),
              icon: Icons.mark_email_unread_outlined,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SectionTitle(uiText(context, 'convocationsSent')),
                ),
                IconButton(
                  tooltip: uiText(context, 'createConvocationTooltip'),
                  icon: const Icon(Icons.add),
                  onPressed: () => openClassPicker(context),
                ),
              ],
            ),
            if (convocations.isEmpty)
              _Card(child: Text(uiText(context, 'noConvocationSent')))
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
  Widget build(BuildContext context) =>
      FutureBuilder<List<PrincipalClassSummary>>(
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
                      CodeEtablissement: widget.user.CodeEtablissement,
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
          _SectionTitle(uiText(context, 'recentCall')),
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
          _SectionTitle(uiText(context, 'studentListNav')),
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

  const PrincipalAttendancePage({Key? key, required this.user})
      : super(key: key);

  @override
  State<PrincipalAttendancePage> createState() =>
      _PrincipalAttendancePageState();
}

class _PrincipalAttendancePageState extends State<PrincipalAttendancePage> {
  static const _allClassesFilter = '__all_classes__';
  static const _allSubjectsFilter = '__all_subjects__';
  static const _allTeachersFilter = '__all_teachers__';
  static const _allStatusesFilter = '__all_statuses__';

  String classFilter = _allClassesFilter;
  String subjectFilter = _allSubjectsFilter;
  String teacherFilter = _allTeachersFilter;
  String statusFilter = _allStatusesFilter;
  String? dateFilter;
  String? apiDateFilter;
  late Future<List<PrincipalAttendanceData>> _attendanceFuture;

  String? _dropdownValueFor(
    List<DropdownMenuItem<String>> items,
    String selectedValue,
  ) {
    final matchingItems =
        items.where((item) => item.value == selectedValue).length;
    return matchingItems == 1 ? selectedValue : null;
  }

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
                  Text(uiText(context, 'principalAttendanceLoadError')),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _attendanceFuture =
                          PrincipalService.getPrincipalAttendance(
                        widget.user,
                        date: apiDateFilter,
                      );
                    }),
                    child: Text(uiText(context, 'retry')),
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
        final classOptions = <String>{
          _allClassesFilter,
          ...allSessions.map((session) => session.className),
        }.toList();
        final classItems = classOptions
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item == _allClassesFilter
                      ? uiText(context, 'allClasses')
                      : item),
                ))
            .toList();
        final classDropdownValue = _dropdownValueFor(classItems, classFilter);
        final validClassFilter = classDropdownValue ?? _allClassesFilter;
        final classSessions = validClassFilter == _allClassesFilter
            ? allSessions
            : allSessions
                .where((session) => session.className == validClassFilter)
                .toList();
        final subjectOptions = <String>{
          _allSubjectsFilter,
          ...classSessions.map((session) => session.subject),
        }.toList();
        final subjectItems = subjectOptions
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item == _allSubjectsFilter
                      ? uiText(context, 'allSubjects')
                      : item),
                ))
            .toList();
        final subjectDropdownValue =
            _dropdownValueFor(subjectItems, subjectFilter);
        final validSubjectFilter = subjectDropdownValue ?? _allSubjectsFilter;
        final subjectSessions = validSubjectFilter == _allSubjectsFilter
            ? classSessions
            : classSessions
                .where((session) => session.subject == validSubjectFilter)
                .toList();
        final teacherOptions = <String>{
          _allTeachersFilter,
          ...subjectSessions.map((session) => session.teacher),
        }.toList();
        final teacherItems = teacherOptions
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item == _allTeachersFilter
                      ? uiText(context, 'allTeachers')
                      : item),
                ))
            .toList();
        final teacherDropdownValue =
            _dropdownValueFor(teacherItems, teacherFilter);
        final validTeacherFilter = teacherDropdownValue ?? _allTeachersFilter;
        const statusOptions = <String>[
          _allStatusesFilter,
          'P',
          'A',
          'R',
        ];
        final statusItems = statusOptions
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item == _allStatusesFilter
                      ? uiText(context, 'allStatuses')
                      : item == 'P'
                          ? uiText(context, 'presentStatusLabel')
                          : item == 'A'
                              ? uiText(context, 'absentStatusLabel')
                              : uiText(context, 'lateStatusLabel')),
                ))
            .toList();
        final statusDropdownValue =
            _dropdownValueFor(statusItems, statusFilter);
        final validStatusFilter = statusDropdownValue ?? _allStatusesFilter;
        final sessions = subjectSessions.where((session) {
          final hasStatus = validStatusFilter == _allStatusesFilter ||
              session.records.any(
                (record) => record.status.toUpperCase() == validStatusFilter,
              );
          return (validTeacherFilter == _allTeachersFilter ||
                  session.teacher == validTeacherFilter) &&
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

        if (classFilter != validClassFilter ||
            subjectFilter != validSubjectFilter ||
            teacherFilter != validTeacherFilter ||
            statusFilter != validStatusFilter) {
          final previousClassFilter = classFilter;
          final previousSubjectFilter = subjectFilter;
          final previousTeacherFilter = teacherFilter;
          final previousStatusFilter = statusFilter;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              if (classFilter == previousClassFilter) {
                classFilter = validClassFilter;
              }
              if (subjectFilter == previousSubjectFilter) {
                subjectFilter = validSubjectFilter;
              }
              if (teacherFilter == previousTeacherFilter) {
                teacherFilter = validTeacherFilter;
              }
              if (statusFilter == previousStatusFilter) {
                statusFilter = validStatusFilter;
              }
            });
          });
        }

        return ListView(padding: const EdgeInsets.all(14), children: [
          _HeaderCard(
              title: uiText(context, 'presence'),
              subtitle: uiText(context, 'followAllClasses'),
              icon: Icons.fact_check_outlined),
          if (overallAttendance != null) ...[
            const SizedBox(height: 10),
            _Card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(uiText(context, 'overallAttendance')),
                trailing: Text(overallAttendance),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _Card(
              child: Column(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.calendar_today, color: CustomTheme.blue),
              title: Text(dateFilter ?? uiText(context, 'allDates')),
              subtitle: Text(uiText(context, 'date')),
              trailing: dateFilter == null
                  ? const Icon(Icons.arrow_forward_ios, size: 16)
                  : IconButton(
                      tooltip: uiText(context, 'resetDate'),
                      icon: const Icon(Icons.clear),
                      onPressed: _clearDate,
                    ),
              onTap: _selectDate,
            ),
            DropdownButtonFormField<String>(
                key: ValueKey<String>(
                    'attendance-class-$classFilter-${Object.hashAll(classOptions)}'),
                value: classDropdownValue,
                decoration: InputDecoration(
                  labelText: uiText(context, 'className'),
                ),
                items: classItems,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    classFilter = value;
                    subjectFilter = _allSubjectsFilter;
                    teacherFilter = _allTeachersFilter;
                  });
                }),
            DropdownButtonFormField<String>(
                key: ValueKey<String>(
                    'attendance-subject-$subjectFilter-${Object.hashAll(subjectOptions)}'),
                value: subjectDropdownValue,
                decoration: InputDecoration(
                  labelText: uiText(context, 'subject'),
                ),
                items: subjectItems,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    subjectFilter = value;
                    teacherFilter = _allTeachersFilter;
                  });
                }),
            DropdownButtonFormField<String>(
                key: ValueKey<String>(
                    'attendance-teacher-$teacherFilter-${Object.hashAll(teacherOptions)}'),
                value: teacherDropdownValue,
                decoration: InputDecoration(
                  labelText: uiText(context, 'teacherName'),
                ),
                items: teacherItems,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => teacherFilter = value);
                }),
            DropdownButtonFormField<String>(
                key: ValueKey<String>(
                    'attendance-status-$statusFilter-${Object.hashAll(statusOptions)}'),
                value: statusDropdownValue,
                decoration: InputDecoration(
                  labelText: uiText(context, 'status'),
                ),
                items: statusItems,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => statusFilter = value);
                })
          ])),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            _Card(child: Text(uiText(context, 'sessionFilterEmpty')))
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
          title: Text(uiText(context, 'studentDetailTitle')),
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
          _StatItem(uiText(context, 'presence'),
              '${(student.attendance * 100).round()}%', Icons.percent),
          _StatItem(
              uiText(context, 'present'), '${student.present}', Icons.check),
          _StatItem(
              uiText(context, 'absences'), '${student.absent}', Icons.close),
          _StatItem(
              uiText(context, 'lateLabel'), '${student.late}', Icons.schedule)
        ]),
        const SizedBox(height: 12),
        _SectionTitle(uiText(context, 'attendanceHistory')),
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
          title: Text(uiText(context, 'attendanceDetailTitle')),
          backgroundColor: CustomTheme.blue,
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Detail(uiText(context, 'date'), session.date),
                  _Detail(uiText(context, 'time'), session.time),
                  _Detail(
                      uiText(context, 'className'), session.schoolClass.name),
                  _Detail(uiText(context, 'subject'), session.subject),
                  _Detail(uiText(context, 'teacherName'), session.teacher),
                  _Detail(uiText(context, 'students'), '${session.total}'),
                  _Detail(uiText(context, 'present'), '${session.present}'),
                  _Detail(
                      uiText(context, 'absenceListTitle'), '${session.absent}'),
                  _Detail(uiText(context, 'lateLabel'), '${session.late}'),
                  _Detail(
                    uiText(context, 'presence'),
                    session.attendance == null
                        ? uiText(context, 'noDataAvailable')
                        : '${(session.attendance! * 100).round()}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionTitle(uiText(context, 'studentListNav')),
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
  final User user;

  const PrincipalReportsPage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PrincipalTeacherClassesPage(
      user: user,
      onSelectTeacher: (schoolClass, teacher) {
        PrincipalSectionRequest(
          title: teacher.fullName,
          screen: PrincipalTeacherCallsPage(
            user: user,
            teacherName: teacher.fullName,
            teacherCode: teacher.code,
            classCode: schoolClass.codeClasse,
          ),
        ).dispatch(context);
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
      Navigator.pop(context, status);
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
    final studentName =
        alert.studentName.isNotEmpty ? alert.studentName : alert.studentCode;

    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
          title: Text(uiText(context, 'reportDetail')),
          backgroundColor: CustomTheme.blue),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        if (alert.eventType == 'investigation') ...[
          _InvestigationAlertCard(
            alert: alert,
            onTap: null,
            showChevron: false,
          ),
          const SizedBox(height: 14),
        ],
        _Card(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Detail(uiText(context, 'studentName'), studentName),
          _Detail(
            uiText(context, 'className'),
            alert.className.isNotEmpty ? alert.className : alert.codeClasse,
          ),
          if (alert.codeMatiere.isNotEmpty)
            _Detail(uiText(context, 'subject'), alert.codeMatiere),
          if (alert.codeEnseignement.isNotEmpty)
            _Detail(uiText(context, 'courseCode'), alert.codeEnseignement),
          _Detail(uiText(context, 'absenceDateLabel'), alert.dateAbsence),
          _Detail(uiText(context, 'parentStatus'), alert.parentStatusLabel),
          _Detail(uiText(context, 'teacherStatus'), alert.teacherStatusLabel),
          _Detail(uiText(context, 'status'), alert.displayStatus),
          _Detail(
            uiText(context, 'note'),
            alert.notes.isNotEmpty ? alert.notes : uiText(context, 'noNote'),
          ),
        ])),
        const SizedBox(height: 14),
        CustomButton(
            text: uiText(context, 'validateTeacherAttendance'),
            loading: _submitting,
            onPress: () => _submitStatus('validated')),
        const SizedBox(height: 8),
        OutlinedButton(
            onPressed: _submitting ? null : () => _submitStatus('rejected'),
            child: Text(uiText(context, 'rejectTeacherAttendance'))),
      ]),
    );
  }
}

class _InvestigationAlertCard extends StatelessWidget {
  final InvestigationAlertData alert;
  final VoidCallback? onTap;
  final bool showChevron;

  const _InvestigationAlertCard({
    required this.alert,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final studentName =
        alert.studentName.isNotEmpty ? alert.studentName : alert.studentCode;
    final className =
        alert.className.isNotEmpty ? alert.className : alert.codeClasse;
    final subjectDetails = [
      if (alert.codeMatiere.isNotEmpty)
        uiText(
          context,
          'subjectWithCode',
          parameters: <String, String>{'code': alert.codeMatiere},
        ),
      if (alert.codeEnseignement.isNotEmpty)
        uiText(
          context,
          'courseWithCode',
          parameters: <String, String>{'code': alert.codeEnseignement},
        ),
    ].join(' • ');
    final explanation = alert.notes.isNotEmpty
        ? alert.notes
        : uiText(context, 'parentReportedButMarkedPresent');
    final isPending = alert.status.toLowerCase() == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.red.shade50,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.red.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red.shade800,
                size: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uiText(context, 'investigationAlert'),
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (studentName.isNotEmpty) studentName,
                        if (className.isNotEmpty)
                          uiText(
                            context,
                            'classWithColon',
                            parameters: <String, String>{
                              'className': className
                            },
                          ),
                        if (subjectDetails.isNotEmpty) subjectDetails,
                        uiText(
                          context,
                          'dateWithColon',
                          parameters: <String, String>{
                            'date': alert.dateAbsence
                          },
                        ),
                        explanation,
                      ].join('\n'),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            isPending
                                ? uiText(context, 'toProcess')
                                : alert.displayStatus,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (showChevron)
                            Icon(
                              Icons.chevron_right,
                              color: Colors.red.shade800,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardRecentAlerts extends StatefulWidget {
  final User user;
  final VoidCallback onViewAll;

  const _DashboardRecentAlerts({
    required this.user,
    required this.onViewAll,
  });

  @override
  State<_DashboardRecentAlerts> createState() => _DashboardRecentAlertsState();
}

class _DashboardRecentAlertsState extends State<_DashboardRecentAlerts> {
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
          return _Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(color: CustomTheme.blue),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _Card(
            child: Column(
              children: [
                Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
                TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(uiText(context, 'retry')),
                ),
              ],
            ),
          );
        }

        final events = (snapshot.data ?? const <InvestigationAlertData>[])
            .where((event) => event.eventType == 'investigation')
            .toList();
        if (events.isEmpty) {
          return _Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.notifications_none, color: CustomTheme.blue),
                  title: Text(uiText(context, 'noRecentInvestigationAlert')),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(uiText(context, 'refresh')),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ...events.take(3).map(
                  (event) => _InvestigationAlertCard(
                    alert: event,
                    onTap: () async {
                      final result = await Navigator.of(context).push<String>(
                        MaterialPageRoute<String>(
                          builder: (_) => ParentReportDetailPage(
                            user: widget.user,
                            alert: event,
                            onUpdated: _reload,
                          ),
                        ),
                      );
                      if (!mounted || result == null) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result == 'validated'
                                ? uiText(context, 'investigationValidated')
                                : uiText(context, 'investigationUpdated'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(uiText(context, 'refresh')),
                ),
                TextButton.icon(
                  onPressed: widget.onViewAll,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    'Voir les alertes d’investigation',
                    textAlign: TextAlign.end,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DashboardRecentJustifications extends StatefulWidget {
  final VoidCallback onViewAll;

  const _DashboardRecentJustifications({required this.onViewAll});

  @override
  State<_DashboardRecentJustifications> createState() =>
      _DashboardRecentJustificationsState();
}

class _DashboardRecentJustificationsState
    extends State<_DashboardRecentJustifications> {
  late Future<DashboardJustificationPageData> _future;

  @override
  void initState() {
    super.initState();
    _future = PrincipalService.getDashboardJustifications();
  }

  void _reload() {
    setState(() {
      _future = PrincipalService.getDashboardJustifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardJustificationPageData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(color: CustomTheme.blue),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _Card(
            child: Column(
              children: [
                Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                ),
                TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(uiText(context, 'retry')),
                ),
              ],
            ),
          );
        }

        final justifications = snapshot.data?.justifications ??
            const <DashboardJustificationData>[];
        return Column(
          children: [
            if (justifications.isEmpty)
              _Card(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.event_note_outlined, color: CustomTheme.blue),
                  title: Text(uiText(context, 'noRecentJustification')),
                ),
              )
            else
              ...justifications.take(3).map(
                    (item) => _DashboardJustificationTile(
                      item: item,
                      onTap: () async {
                        final validated =
                            await _openDashboardJustificationDetail(
                          context,
                          item,
                        );
                        if (validated == true && mounted) _reload();
                      },
                    ),
                  ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onViewAll,
                icon: const Icon(Icons.arrow_forward),
                label: Text(uiText(context, 'viewMore')),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DashboardJustificationsPage extends StatefulWidget {
  const DashboardJustificationsPage({Key? key}) : super(key: key);

  @override
  State<DashboardJustificationsPage> createState() =>
      _DashboardJustificationsPageState();
}

class _DashboardJustificationsPageState
    extends State<DashboardJustificationsPage> {
  static const _pageSize = 20;

  late Future<DashboardJustificationPageData> _future;
  bool _loadingMore = false;
  Object? _loadMoreError;

  @override
  void initState() {
    super.initState();
    _future = PrincipalService.getDashboardJustifications(
      perPage: _pageSize,
    );
  }

  void _reload() {
    setState(() {
      _loadMoreError = null;
      _future = PrincipalService.getDashboardJustifications(
        perPage: _pageSize,
      );
    });
  }

  Future<void> _loadMore(DashboardJustificationPageData currentPage) async {
    if (_loadingMore || currentPage.currentPage >= currentPage.lastPage) return;

    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final nextPage = await PrincipalService.getDashboardJustifications(
        page: currentPage.currentPage + 1,
        perPage: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _future = Future.value(
          DashboardJustificationPageData(
            justifications: [
              ...currentPage.justifications,
              ...nextPage.justifications,
            ],
            currentPage: nextPage.currentPage,
            lastPage: nextPage.lastPage,
          ),
        );
      });
    } on Exception catch (error) {
      if (mounted) setState(() => _loadMoreError = error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardJustificationPageData>(
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
                  const Text(
                    'Impossible de charger les justifications pour le moment.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _reload,
                    child: Text(uiText(context, 'retry')),
                  ),
                ],
              ),
            ),
          );
        }

        final page = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _HeaderCard(
              title: uiText(context, 'recentJustifications'),
              subtitle: uiText(context, 'justificationsForReview'),
              icon: Icons.event_note_outlined,
            ),
            const SizedBox(height: 12),
            if (page.justifications.isEmpty)
              _Card(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.event_note_outlined, color: CustomTheme.blue),
                  title: Text(uiText(context, 'noRecentJustification')),
                ),
              )
            else
              ...page.justifications.map(
                (item) => _DashboardJustificationTile(
                  item: item,
                  onTap: () async {
                    final validated = await _openDashboardJustificationDetail(
                      context,
                      item,
                    );
                    if (validated == true && mounted) _reload();
                  },
                ),
              ),
            if (page.currentPage < page.lastPage) ...[
              if (_loadMoreError != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    uiText(context, 'requestFailedTryAgain'),
                    textAlign: TextAlign.center,
                  ),
                ),
              Center(
                child: TextButton.icon(
                  onPressed: _loadingMore ? null : () => _loadMore(page),
                  icon: _loadingMore
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: Text(
                    _loadMoreError == null
                        ? uiText(context, 'viewMore')
                        : uiText(context, 'retry'),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DashboardJustificationTile extends StatelessWidget {
  final DashboardJustificationData item;
  final VoidCallback onTap;

  const _DashboardJustificationTile({
    required this.item,
    required this.onTap,
  });

  String _displayDate(String value, BuildContext context) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (match == null) {
      return value.isEmpty ? uiText(context, 'dateNotProvided') : value;
    }
    return '${match.group(3)}/${match.group(2)}/${match.group(1)}';
  }

  String _displayStatus(String value, BuildContext context) {
    switch (value.toLowerCase()) {
      case 'pending':
      case 'en attente':
        return uiText(context, 'pendingStatus');
      case 'validated':
      case 'validée':
        return uiText(context, 'validatedAbsenceStatus');
      case 'rejected':
        return uiText(context, 'rejectedStatus');
      default:
        return value.isEmpty ? uiText(context, 'notProvided') : value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = item.studentName.isEmpty
        ? uiText(context, 'studentName')
        : item.studentName;
    final className = item.className.isNotEmpty
        ? item.className
        : (item.classCode.isEmpty
            ? uiText(context, 'classNotProvided')
            : item.classCode);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.event_note_outlined, color: CustomTheme.blue),
        title: Text(
          studentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$className • ${item.reason.isEmpty ? uiText(context, 'reasonNotProvided') : item.reason}'
          '\n${_displayDate(item.absenceDate, context)}',
        ),
        isThreeLine: true,
        trailing: Text(
          _displayStatus(item.status, context),
          style: const TextStyle(
            color: CustomTheme.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

Future<bool?> _openDashboardJustificationDetail(
  BuildContext context,
  DashboardJustificationData item,
) {
  return Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      builder: (_) => _DashboardJustificationDetailPage(
        justificationId: item.id,
      ),
    ),
  );
}

class _DashboardJustificationDetailPage extends StatefulWidget {
  final int justificationId;

  const _DashboardJustificationDetailPage({required this.justificationId});

  @override
  State<_DashboardJustificationDetailPage> createState() =>
      _DashboardJustificationDetailPageState();
}

class _DashboardJustificationDetailPageState
    extends State<_DashboardJustificationDetailPage> {
  late Future<DashboardJustificationData> _future;
  bool _validating = false;
  bool _wasValidated = false;

  @override
  void initState() {
    super.initState();
    _future = PrincipalService.getDashboardJustificationDetail(
      widget.justificationId,
    );
  }

  Future<void> _validate() async {
    setState(() => _validating = true);
    try {
      final updated = await PrincipalService.validateDashboardJustification(
        widget.justificationId,
      );
      if (!mounted) return;
      setState(() {
        _future = Future.value(updated);
        _validating = false;
        _wasValidated = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiText(context, 'absenceValidatedMessage'))),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _validating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !['http', 'https'].contains(uri.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiText(context, 'documentUnavailable'))),
      );
      return;
    }
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiText(context, 'documentOpenError'))),
      );
    }
  }

  String _workflowLabel(String status, BuildContext context) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
      case 'en attente':
        return uiText(context, 'pendingStatus');
      case 'validated':
      case 'validée':
        return uiText(context, 'validatedAbsenceStatus');
      case 'approved':
        return uiText(context, 'approvedStatus');
      case 'rejected':
        return uiText(context, 'rejectedStatus');
      default:
        return status.isEmpty ? uiText(context, 'notProvided') : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_wasValidated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(uiText(context, 'justificationDetail')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_wasValidated),
          ),
        ),
        body: FutureBuilder<DashboardJustificationData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final item = snapshot.data!;
            final pending = ['pending', 'en attente']
                .contains(item.status.trim().toLowerCase());
            final studentName =
                item.studentName.isEmpty ? item.studentCode : item.studentName;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(
                  title: studentName.isEmpty
                      ? uiText(context, 'studentName')
                      : studentName,
                  subtitle: uiText(context, 'parentReportedAbsent'),
                  icon: Icons.event_note_outlined,
                ),
                const SizedBox(height: 12),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Detail(uiText(context, 'studentCode'), item.studentCode),
                      _Detail(
                        uiText(context, 'className'),
                        item.className.isEmpty
                            ? item.classCode
                            : '${item.className} (${item.classCode})',
                      ),
                      _Detail(
                        uiText(context, 'institution'),
                        item.schoolName.isEmpty
                            ? item.schoolCode
                            : item.schoolName,
                      ),
                      _Detail(uiText(context, 'absenceDateLabel'),
                          item.absenceDate),
                      _Detail(
                        uiText(context, 'reason'),
                        item.reason.isEmpty
                            ? uiText(context, 'notProvided')
                            : item.reason,
                      ),
                      _Detail(
                        uiText(context, 'description'),
                        item.explanation.isEmpty
                            ? uiText(context, 'notProvided')
                            : item.explanation,
                      ),
                      if (item.parentName.isNotEmpty)
                        _Detail(uiText(context, 'parent'), item.parentName),
                      if (item.parentCode.isNotEmpty)
                        _Detail(uiText(context, 'parent'), item.parentCode),
                      if (item.parentContacts.isNotEmpty)
                        _Detail(uiText(context, 'parent'), item.parentContacts),
                      _Detail(
                        uiText(context, 'status'),
                        _workflowLabel(item.status, context),
                      ),
                      _Detail(
                        uiText(context, 'submissionDate'),
                        item.createdAt.isEmpty
                            ? uiText(context, 'notProvided')
                            : item.createdAt,
                      ),
                      if (item.documentUrl.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _openDocument(item.documentUrl),
                            icon: const Icon(Icons.attach_file),
                            label:
                                Text(uiText(context, 'openAttachedDocument')),
                          ),
                        ),
                    ],
                  ),
                ),
                if (pending) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _validating ? null : _validate,
                      icon: _validating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: Text(
                        _validating
                            ? uiText(context, 'validationInProgress')
                            : uiText(context, 'validate'),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> _showAttendanceEventDetails(
  BuildContext context,
  InvestigationAlertData event,
) async {
  final studentName =
      event.studentName.isNotEmpty ? event.studentName : event.studentCode;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(event.teacherStatusLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Detail(uiText(context, 'studentName'), studentName),
          _Detail(uiText(context, 'className'),
              event.className.isNotEmpty ? event.className : event.codeClasse),
          _Detail(uiText(context, 'date'), event.dateAbsence),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiText(context, 'close')),
        ),
      ],
    ),
  );
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
                  Text(uiText(context, 'requestFailedTryAgain')),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _reload,
                    child: Text(uiText(context, 'retry')),
                  ),
                ],
              ),
            ),
          );
        }

        final alerts = (snapshot.data ?? const <InvestigationAlertData>[])
            .where((alert) => alert.eventType == 'investigation')
            .toList();

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _HeaderCard(
                title: uiText(context, 'investigationAlerts'),
                subtitle: uiText(context, 'reviewAttendanceAlerts'),
                icon: Icons.info_outline),
            const SizedBox(height: 12),
            if (alerts.isEmpty)
              _Card(
                child: Text(uiText(context, 'noAlertsToProcess')),
              )
            else
              ...alerts.map(
                (alert) => _InvestigationAlertCard(
                  alert: alert,
                  onTap: () async {
                    final result = await Navigator.of(context).push<String>(
                      MaterialPageRoute<String>(
                        builder: (_) => ParentReportDetailPage(
                          user: widget.user,
                          alert: alert,
                          onUpdated: _reload,
                        ),
                      ),
                    );
                    if (!mounted || result == null) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result == 'validated'
                              ? uiText(context, 'investigationValidated')
                              : uiText(context, 'investigationUpdated'),
                        ),
                      ),
                    );
                  },
                ),
              ),
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
                  Text(uiText(context, 'teacherCallsLoadError')),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() => _future =
                        PrincipalService.getPrincipalAttendance(widget.user)),
                    child: Text(uiText(context, 'retry')),
                  ),
                ],
              ),
            ),
          );
        }

        final allSessions = snapshot.data ?? const <PrincipalAttendanceData>[];
        final allClasses = <String>{
          'Toutes les classes',
          ...allSessions.map((item) => item.className)
        }.toList();
        final allTeachers = <String>{
          'Tous les enseignants',
          ...allSessions.map((item) => item.teacher)
        }.toList();

        if (!allClasses.contains(classFilter)) {
          classFilter = 'Toutes les classes';
        }
        if (!allTeachers.contains(teacherFilter)) {
          teacherFilter = 'Tous les enseignants';
        }

        final calls = allSessions.where((session) {
          final matchesClass = classFilter == 'Toutes les classes' ||
              session.className == classFilter;
          final matchesTeacher = teacherFilter == 'Tous les enseignants' ||
              session.teacher
                  .toLowerCase()
                  .contains(teacherFilter.toLowerCase());
          return matchesClass && matchesTeacher;
        }).toList();

        return ListView(padding: const EdgeInsets.all(14), children: [
          _HeaderCard(
              title: uiText(context, 'teacherCallsTitle'),
              subtitle: uiText(context, 'teacherAttendanceTracking'),
              icon: Icons.assignment_outlined),
          const SizedBox(height: 12),
          _Card(
              child: Column(children: [
            DropdownButtonFormField<String>(
                value: classFilter,
                decoration: InputDecoration(
                  labelText: uiText(context, 'classFilter'),
                ),
                items: allClasses
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item == 'Toutes les classes'
                              ? uiText(context, 'allClasses')
                              : item),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => classFilter = value ?? classFilter)),
            DropdownButtonFormField<String>(
                value: teacherFilter,
                decoration: InputDecoration(
                  labelText: uiText(context, 'teacherFilter'),
                ),
                items: allTeachers
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item == 'Tous les enseignants'
                              ? uiText(context, 'allTeachers')
                              : item),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => teacherFilter = value ?? teacherFilter)),
          ])),
          const SizedBox(height: 10),
          if (calls.isEmpty)
            _Card(child: Text(uiText(context, 'noSessionMatchesFilters')))
          else
            ...calls.map((session) => _Card(
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrincipalLiveAttendanceSessionPage(
                            session: session),
                      ),
                    ),
                    title: Text('${session.className} • ${session.subject}'),
                    subtitle: Text(uiText(
                      context,
                      'sessionSummary',
                      parameters: <String, String>{
                        'date': session.date,
                        'time': session.time,
                        'teacher': session.teacher,
                        'present': '${session.present}',
                        'absent': '${session.absent}',
                        'late': '${session.late}',
                      },
                    )),
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
            title:
                '${uiText(context, 'principal')} — ${uiText(context, 'encadreur')}',
            subtitle: uiText(context, 'allClasses'),
            icon: Icons.person_outline),
        const SizedBox(height: 12),
        _Card(
            child: Column(children: [
          ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(uiText(context, 'temporaryLocalAccess')),
              subtitle: Text(uiText(context, 'simulatedData'))),
          ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(uiText(context, 'teacherVerification')),
              subtitle: Text(uiText(context, 'prepareFutureClassCall')),
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
              title: Text(uiText(context, 'changePassword')),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ChangePassword(user: user, localOnly: true)))),
          ListTile(
              leading: const Icon(Icons.logout),
              title: Text(uiText(context, 'logout')),
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
          title: Text(uiText(context, 'teacherVerification')),
          backgroundColor: CustomTheme.blue),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: _Card(
            child: Column(children: [
          const Icon(Icons.badge_outlined, size: 54, color: CustomTheme.blue),
          Text(uiText(context, 'teacherCodePrompt')),
          TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: uiText(context, 'teacherCodeExample'),
              )),
          const SizedBox(height: 16),
          CustomButton(
              text: uiText(context, 'continueButton'),
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
          title: Text(uiText(context, 'cameraVerification')),
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
                Text('M. Kouame',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(verified
                    ? uiText(context, 'identityVerified')
                    : uiText(context, 'simulatedCameraVerification')),
                const SizedBox(height: 18),
                CustomButton(
                    text: verified
                        ? uiText(context, 'startAttendanceCall')
                        : uiText(context, 'verifyIdentity'),
                    onPress: () => setState(() => verified = true)),
                if (verified)
                  TextButton(
                      onPressed: () => setState(() => verified = false),
                      child: Text(uiText(context, 'verificationFailedRetry'))),
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
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      MapEntry(
          uiText(context, 'enrollmentCount'), '${classOverview.studentCount}'),
      MapEntry(uiText(context, 'boysCount'), '${classOverview.boys}'),
      MapEntry(uiText(context, 'girls'), '${classOverview.girls}'),
      MapEntry(
        uiText(context, 'teacherPrincipal'),
        teacherName ?? uiText(context, 'notProvided'),
      ),
      MapEntry(
          uiText(context, 'subjectsCount'), '${classOverview.subjectCount}'),
      MapEntry(uiText(context, 'todaySessionsLabel'),
          '${classOverview.sessionsToday}'),
      MapEntry(uiText(context, 'attendanceToday'), attendanceRate),
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
                              style:
                                  row.key == uiText(context, 'attendanceToday')
                                      ? greyTextStyle?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _attendancePercentageColor(
                                              row.value, context),
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

  Color _attendancePercentageColor(String value, BuildContext context) {
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
        ? uiText(context, 'noDataAvailable')
        : '${(totalPresent / totalStudents * 100).round()}%';

    final rows = <MapEntry<String, String>>[
      MapEntry(
          uiText(context, 'enrollmentCount'), '${schoolClass.students.length}'),
      MapEntry(uiText(context, 'boysCount'), '${schoolClass.boys}'),
      MapEntry(uiText(context, 'girls'), '${schoolClass.girls}'),
      MapEntry(
          uiText(context, 'teacherPrincipal'), uiText(context, 'notProvided')),
      MapEntry(uiText(context, 'subjectsCount'),
          '${classSessions.map((session) => session.subject).toSet().length}'),
      MapEntry(uiText(context, 'todaySessionsLabel'), '${daySessions.length}'),
      MapEntry(uiText(context, 'attendanceRateLabel'), attendanceRate),
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
                              style: row.key ==
                                      uiText(context, 'attendanceRateLabel')
                                  ? greyTextStyle?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _attendancePercentageColor(
                                          row.value, context),
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

  Color _attendancePercentageColor(String value, BuildContext context) {
    if (value == uiText(context, 'noDataAvailable')) {
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
            uiText(
              context,
              'sessionSummary',
              parameters: <String, String>{
                'date': session.date,
                'time': session.time,
                'teacher': session.teacher,
                'present': '${session.present}',
                'absent': '${session.absent}',
                'late': '${session.late}',
              },
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          trailing: Text(
            session.attendancePercentage == null
                ? uiText(context, 'noDataAvailable')
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
        leading: const Icon(Icons.fact_check_outlined, color: CustomTheme.blue),
        title: Text(
          '${session.className} • ${session.subject}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          uiText(
            context,
            'sessionSummary',
            parameters: <String, String>{
              'date': session.date,
              'time': session.time,
              'teacher': session.teacher,
              'present': '${session.present}',
              'absent': '${session.absent}',
              'late': '${session.late}',
            },
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Text(
          attendancePercentage == null ? '—' : '$attendancePercentage%',
          style: attendancePercentage == null
              ? null
              : TextStyle(
                  color:
                      attendancePercentage < 50 ? Colors.red : CustomTheme.blue,
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

  String _statusLabel(String status, BuildContext context) {
    switch (status) {
      case 'P':
        return uiText(context, 'presentStatusLabel');
      case 'A':
        return uiText(context, 'absentStatusLabel');
      case 'R':
        return uiText(context, 'lateStatusLabel');
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
        title: Text(uiText(context, 'attendanceDetailTitle')),
        backgroundColor: CustomTheme.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Detail(uiText(context, 'date'), session.date),
                _Detail(uiText(context, 'time'), session.time),
                _Detail(uiText(context, 'className'), session.className),
                _Detail(uiText(context, 'subject'),
                    subjectLabel ?? session.subject),
                _Detail(uiText(context, 'teacherName'), session.teacher),
                _Detail(uiText(context, 'teacherPresenceLabel'),
                    session.teacherPresenceLabel),
                _Detail(
                  preferApiAttendancePercentage
                      ? uiText(context, 'totalStudents')
                      : uiText(context, 'studentsCountLabel'),
                  '${session.studentCount}',
                ),
                _Detail(uiText(context, 'present'), '${session.present}'),
                _Detail(uiText(context, 'absences'), '${session.absent}'),
                _Detail(uiText(context, 'lateLabel'), '${session.late}'),
                _Detail(
                  uiText(context, 'presence'),
                  attendancePercentage == null ? '—' : '$attendancePercentage%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionTitle(uiText(context, 'studentListNav')),
          ...session.records.map((record) => _Card(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(record.studentName.isEmpty
                      ? record.codeEleve
                      : record.studentName),
                  subtitle: Text(record.codeEleve),
                  trailing: Text(showRawStatuses
                      ? record.status
                      : _statusLabel(record.status, context)),
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
            uiText(
              context,
              'sessionSummary',
              parameters: <String, String>{
                'date': session.date,
                'time': session.time,
                'teacher': session.teacher,
                'present': '${session.present}',
                'absent': '${session.absent}',
                'late': '${session.late}',
              },
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          trailing: Text(
            session.attendance == null
                ? uiText(context, 'noDataAvailable')
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
  _Card({required this.child});
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
