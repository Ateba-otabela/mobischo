import 'package:flutter/material.dart';
import 'package:mobischo/components/screens/parent/ParentConvocation.dart';
import 'package:mobischo/models/devoir.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/services/devoir_service.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

enum _SortDirection { newest, oldest }

class DevoirsMessagesScreen extends StatefulWidget {
  final User user;
  final VoidCallback? onBack;
  final int initialTab;

  const DevoirsMessagesScreen({
    Key? key,
    required this.user,
    this.onBack,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<DevoirsMessagesScreen> createState() => _DevoirsMessagesScreenState();
}

class _DevoirsMessagesScreenState extends State<DevoirsMessagesScreen> {
  int selectedTab = 0;
  Student? selectedStudent;
  late Future<List<Devoir>> assignmentsFuture;
  _SortDirection _homeworkSort = _SortDirection.newest;
  _SortDirection _messagesSort = _SortDirection.newest;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab.clamp(0, 1);
    assignmentsFuture = DevoirServices.getParentDevoirs(widget.user.code);
  }

  void _selectStudent(Student? student) {
    setState(() {
      selectedStudent = student;
      assignmentsFuture = DevoirServices.getParentDevoirs(
        widget.user.code,
        codeEleve: student?.CodeEleve,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = Container(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: uiText(context, 'homeDashboardTooltip'),
                icon: const Icon(Icons.arrow_back_ios),
                color: CustomTheme.blue,
                onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
              ),
            ),
            _Tabs(
              selectedTab: selectedTab,
              onChanged: (tab) => setState(() => selectedTab = tab),
            ),
            _ChildFilter(
              user: widget.user,
              selectedStudent: selectedStudent,
              onSelected: _selectStudent,
            ),
            Expanded(
              child: selectedTab == 0
                  ? _HomeworkAssignments(
                      future: assignmentsFuture,
                      sortDirection: _homeworkSort,
                      sortLabel: uiText(context, 'sortHomework'),
                      onSortChanged: (sortDirection) {
                        setState(() => _homeworkSort = sortDirection);
                      },
                    )
                  : convocationList(
                      widget: ParentConvocationList(user: widget.user),
                      isLoaded: false,
                      interstitialAd: null,
                      sortKey: _messagesSort.name,
                      sortLabel: uiText(context, 'sortMessages'),
                      onSortChanged: (sortKey) {
                        setState(() {
                          _messagesSort = sortKey == 'oldest'
                              ? _SortDirection.oldest
                              : _SortDirection.newest;
                        });
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    if (widget.onBack == null) {
      return body;
    }

    return WillPopScope(
      onWillPop: () async {
        widget.onBack!.call();
        return false;
      },
      child: body,
    );
  }
}

class _Tabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _Tabs({required this.selectedTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: uiText(context, 'homeworkTab'),
              active: selectedTab == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Tab(
              label: uiText(context, 'messages'),
              active: selectedTab == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? CustomTheme.blue : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : CustomTheme.dark,
                fontSize: 14,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildFilter extends StatelessWidget {
  final User user;
  final Student? selectedStudent;
  final ValueChanged<Student?> onSelected;

  const _ChildFilter({
    required this.user,
    required this.selectedStudent,
    required this.onSelected,
  });

  Future<void> _showSelector(BuildContext context) async {
    final navigator = Navigator.of(context);
    final students = await StudentServices.getParentStudents(user.code);
    if (!navigator.mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: navigator.context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(uiText(context, 'allMyChildren')),
              leading:
                  const Icon(Icons.groups_outlined, color: CustomTheme.blue),
              onTap: () {
                onSelected(null);
                Navigator.pop(context);
              },
            ),
            ...students.map(
              (student) => ListTile(
                title: Text(getStudentDisplayName(student)),
                leading:
                    const Icon(Icons.person_outline, color: CustomTheme.blue),
                onTap: () {
                  onSelected(student);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSelector(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedStudent == null
                        ? uiText(context, 'allMyChildren')
                        : getStudentDisplayName(selectedStudent!),
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    uiText(context, 'sortByChildren'),
                    style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF616161)),
          ],
        ),
      ),
    );
  }
}

class _HomeworkEmptyState extends StatelessWidget {
  const _HomeworkEmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationSize =
            (constraints.maxWidth * 0.46).clamp(140.0, 180.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 18),
              child: Column(
                children: [
                  _HomeworkIllustration(size: illustrationSize),
                  const SizedBox(height: 24),
                  Text(
                    uiText(context, 'noHomeworkAvailable'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF424242),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      uiText(context, 'homeworkWillAppear'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.tune, size: 18),
                    label: Text(uiText(context, 'sortHomework')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomTheme.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      minimumSize: const Size(0, 40),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeworkAssignments extends StatelessWidget {
  final Future<List<Devoir>> future;
  final _SortDirection sortDirection;
  final ValueChanged<_SortDirection> onSortChanged;
  final String sortLabel;

  const _HomeworkAssignments({
    required this.future,
    required this.sortDirection,
    required this.onSortChanged,
    required this.sortLabel,
  });

  List<Devoir> _sortedAssignments(List<Devoir> assignments) {
    final sorted = List<Devoir>.from(assignments);
    sorted.sort((a, b) {
      final aDate = _parseDate(a.dateDuDevoir);
      final bDate = _parseDate(b.dateDuDevoir);
      final comparison = aDate.compareTo(bDate);
      return sortDirection == _SortDirection.newest ? -comparison : comparison;
    });
    return sorted;
  }

  DateTime _parseDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final dateTime = DateTime.tryParse(normalized);
    if (dateTime != null) {
      return dateTime;
    }

    final parts = normalized.split(RegExp(r'[/\-]'));
    if (parts.length == 3) {
      final first = parts[0];
      final second = parts[1];
      final third = parts[2];
      try {
        if (first.length == 4) {
          return DateTime.parse(
              '$first-${second.padLeft(2, '0')}-${third.padLeft(2, '0')}');
        }
        if (third.length == 4) {
          return DateTime.parse('$third-${second.padLeft(2, '0')}-$first');
        }
      } catch (_) {}
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Devoir>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = _sortedAssignments(snapshot.data ?? <Devoir>[]);
        if (assignments.isEmpty) {
          return const _HomeworkEmptyState();
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                itemCount: assignments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _AssignmentCard(
                  assignment: assignments[index],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _SortButton(
                label: sortLabel,
                sortDirection: sortDirection,
                onSortChanged: onSortChanged,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Devoir assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.titre,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (assignment.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                assignment.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (assignment.dateDuDevoir.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                uiText(
                  context,
                  'dueDate',
                  parameters: <String, String>{'date': assignment.dateDuDevoir},
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (assignment.CodeMatiere.isNotEmpty ||
                assignment.CodeClasse.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                uiText(
                  context,
                  'subjectAndClass',
                  parameters: <String, String>{
                    'subject': assignment.CodeMatiere,
                    'className': assignment.CodeClasse,
                  },
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final _SortDirection sortDirection;
  final ValueChanged<_SortDirection> onSortChanged;

  const _SortButton({
    required this.label,
    required this.sortDirection,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortDirection>(
      onSelected: onSortChanged,
      offset: const Offset(0, -140),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _SortDirection.newest,
          child: Text(uiText(context, 'newestFirst')),
        ),
        PopupMenuItem(
          value: _SortDirection.oldest,
          child: Text(uiText(context, 'oldestFirst')),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        height: 40,
        decoration: BoxDecoration(
          color: CustomTheme.blue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkIllustration extends StatelessWidget {
  final double size;

  const _HomeworkIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.76,
            height: size * 0.48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Icon(Icons.desktop_windows_outlined,
                size: size * 0.32, color: const Color(0xFF2E7D32)),
          ),
          Positioned(
            bottom: size * 0.05,
            child: Icon(Icons.school_outlined,
                size: size * 0.42, color: const Color(0xFF616161)),
          ),
          Positioned(
            top: size * 0.03,
            right: size * 0.02,
            child: Icon(Icons.chat_bubble_outline,
                size: size * 0.2, color: const Color(0xFF2E7D32)),
          ),
          Positioned(
            bottom: size * 0.02,
            left: size * 0.03,
            child: Icon(Icons.local_florist_outlined,
                size: size * 0.22, color: const Color(0xFF66BB6A)),
          ),
        ],
      ),
    );
  }
}
