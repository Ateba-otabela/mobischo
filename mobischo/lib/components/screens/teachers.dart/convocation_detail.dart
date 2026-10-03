// ignore_for_file: unnecessary_import, implementation_imports, sort_child_properties_last, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/models/convocation.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/courses.dart';
// ignore: unused_import
import 'package:mobischo/services/services.dart';
import 'package:mobischo/services/students_services.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/l10n/ui_text.dart';

class ConvocationDetail extends StatefulWidget {
  final Convocation convocation;
  final User user;
  final bool embedded;
  const ConvocationDetail(
      {Key? key,
      required this.convocation,
      required this.user,
      this.embedded = false})
      : super(key: key);

  @override
  State<ConvocationDetail> createState() => _ConvocationDetailState();
}

class _ConvocationDetailState extends State<ConvocationDetail> {
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

  @override
  Widget build(BuildContext context) {
    final detailBody = ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.security, color: CustomTheme.blue),
          title: Text(widget.convocation.CodeEnseignement),
          subtitle: Text(uiText(context, 'codeTeaching')),
        ),
        ListTile(
          leading: const Icon(Icons.security, color: CustomTheme.blue),
          title: FutureBuilder<String>(
            future:
                CourseServices.getMainCourse(widget.convocation.CodeMatiere),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.data == null) {
                return Text(uiText(context, 'loadingEllipsis'));
              }
              return Text(snapshot.data ?? '');
            },
          ),
          subtitle: Text(uiText(context, 'subject')),
        ),
        ListTile(
          leading: const Icon(Icons.security, color: CustomTheme.blue),
          title: Text(widget.convocation.motif),
          subtitle: Text(uiText(context, 'reason')),
        ),
        ListTile(
          leading: const Icon(Icons.security, color: CustomTheme.blue),
          title: Text(widget.convocation.dateConvocation),
          subtitle: Text(uiText(context, 'convocationDateLabel')),
        ),
        ListTile(
          leading: const Icon(Icons.security, color: CustomTheme.blue),
          title: Text(widget.convocation.created_at),
          subtitle: Text(uiText(context, 'sentDate')),
        ),
        ListTile(
          leading: const Icon(Icons.security, color: CustomTheme.blue),
          title: Text(
            widget.convocation.teacherName ??
                (widget.convocation.teacherCode != null &&
                        widget.convocation.teacherCode!.isNotEmpty
                    ? widget.convocation.teacherCode!
                    : uiText(context, 'notProvided')),
          ),
          subtitle: Text(uiText(context, 'teacher')),
        ),
      ],
    );

    if (widget.embedded) {
      return detailBody;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: FutureBuilder<String>(
            future:
                StudentServices.getMainStudent(widget.convocation.CodeEleve),
            builder: (
              BuildContext context,
              AsyncSnapshot<String> snapshot,
            ) {
              if (snapshot.data == null) {
                return Text(uiText(context, 'loadingEllipsis'));
              } else {
                return Text(
                  snapshot.data ?? "",
                  style: const TextStyle(fontSize: 13),
                );
              }
            }),
      ),
      body: Column(
        children: [
          Expanded(
            child: detailBody,
          ),
        ],
      ),
    );
  }
}
