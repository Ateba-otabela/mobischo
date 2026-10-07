import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobischo/components/screens/teachers.dart/TeacherConvocationList.dart';
import 'package:mobischo/utils/custom_button.dart';
import 'package:mobischo/home.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/utils/custom_theme.dart';
import 'package:mobischo/l10n/ui_text.dart';

class ConvocationSuccess extends StatefulWidget {
  final User user;
  // final Course course;
  const ConvocationSuccess({Key? key, required this.user}) : super(key: key);

  @override
  State<ConvocationSuccess> createState() => _ConvocationSuccessState();
}

class _ConvocationSuccessState extends State<ConvocationSuccess> {
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
    return Scaffold(
        body: Center(
      child: Form(
          // key: _formKey,
          child: Wrap(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Image(
                image: AssetImage('assets/images/check.png'),
                height: 200,
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: CustomTheme.getCardDecoration(),
                  child: Column(
                    children: [
                      Text(
                        uiText(context, 'convocationRecordedSuccessfully'),
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        uiText(context, 'clickConsultToSeeConvocations'),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ActionButton(widget: widget, user: widget.user),
                      const SizedBox(
                        height: 20,
                      ),
                      Center(
                        child: InkWell(
                          onTap: () {
                            if (isLoaded == true) {
                              _interstitialAd!.show();
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Home(
                                        user: widget.user,
                                        selectedPage: 0,
                                      )),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                uiText(context, 'notInterested'),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                uiText(context, 'home'),
                                style: const TextStyle(color: CustomTheme.blue),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      )),
    ));
  }
}

class ActionButton extends StatelessWidget {
  final User user;
  const ActionButton({Key? key, required this.widget, required this.user})
      : super(key: key);

  final ConvocationSuccess widget;

  @override
  Widget build(BuildContext context) {
    if (widget.user.account_type == 'enseignant') {
      return CustomButton(
          text: uiText(context, 'consult'),
          onPress: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: ((context) =>
                        TeacherConvocationList(user: widget.user))));
          });
    } else {
      return CustomButton(
          text: uiText(context, 'consult'),
          onPress: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: ((context) => Home(
                          user: widget.user,
                          selectedPage: 2,
                        ))));
          });
    }
  }
}
