// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/students/student_sequence_notes_screen.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/models/student.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/utils/student_display_name.dart';

class MyChildrenNotes extends StatefulWidget {
  final User user;
  final Student? initialStudent;
  final VoidCallback? onBack;

  const MyChildrenNotes({
    Key? key,
    required this.user,
    this.initialStudent,
    this.onBack,
  }) : super(key: key);

  @override
  State<MyChildrenNotes> createState() => _MyChildrenNotesState();
}

class _MyChildrenNotesState extends State<MyChildrenNotes> {
  Student? _selectedStudent;
  Future<List<Student>>? _childrenFuture;
  InterstitialAd? _interstitialAd;
  var _interstitialLoadAttempts = 0;

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.initialStudent;
    if (_selectedStudent == null) {
      _childrenFuture = _loadChildren();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<List<Student>> _loadChildren() =>
      StudentServices.getParentStudentsForNotes(widget.user.code);

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-2496623977736610/2133664237',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
          _interstitialLoadAttempts++;
          if (mounted && _interstitialLoadAttempts < 3) {
            _loadInterstitialAd();
          }
        },
      ),
    );
  }

  String _genderLabel(String sex) {
    switch (sex.trim().toLowerCase()) {
      case '0':
      case 'm':
      case 'male':
        return uiText(context, 'genderMale');
      case '1':
      case 'f':
      case 'female':
        return uiText(context, 'genderFemale');
      default:
        return '';
    }
  }

  String _childName(Student child) {
    final name = getStudentDisplayName(child);
    return name == 'Student' ? uiText(context, 'notProvided') : name;
  }

  @override
  Widget build(BuildContext context) {
    final student = _selectedStudent;
    if (student != null) {
      return StudentSequenceNotesScreen(
        student: student,
        onBack: widget.onBack ?? () => setState(() => _selectedStudent = null),
      );
    }

    return FutureBuilder<List<Student>>(
      future: _childrenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(uiText(context, 'childrenLoadError')),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      setState(() => _childrenFuture = _loadChildren()),
                  child: Text(uiText(context, 'retry')),
                ),
              ],
            ),
          );
        }

        final children = snapshot.data ?? <Student>[];
        if (children.isEmpty) {
          return Center(child: Text(uiText(context, 'noChildLinked')));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                uiText(context, 'selectYourChild'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                itemCount: children.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final child = children[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundImage:
                            AssetImage('assets/images/avatar-s-19.jpg'),
                      ),
                      title: Text(
                        _childName(child),
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: _genderLabel(child.Sex).isEmpty
                          ? null
                          : Text(
                              _genderLabel(child.Sex),
                              style: const TextStyle(color: CustomTheme.blue),
                            ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _interstitialAd?.show();
                        setState(() => _selectedStudent = child);
                      },
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
