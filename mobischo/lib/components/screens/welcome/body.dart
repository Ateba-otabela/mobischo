// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:mobischo/utils/custom_theme.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  List<Map<String, String>> splashData = [
    {'text': "MOBISCHO", 'image': "assets/images/icon.png"},
    {'text': "CONSULTEZ SANS STRESS", 'image': "assets/images/landing1.png"},
    {'text': "RESTEZ CONNECTÉ", 'image': "assets/images/landing2.png"},
    {'text': "CONNECTEZ VOUS", 'image': "assets/images/landing3.png"},
  ];
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: PageView.builder(
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemCount: splashData.length,
                itemBuilder: (context, index) => SplashContent(
                      text: splashData[index]['text'].toString(),
                      image: splashData[index]['image'].toString(),
                    )),
          ),
          const Spacer(),
          Expanded(
              child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) => BuildDot(index: index)))
            ],
          ))
        ],
      ),
    );
  }

  Container BuildDot({required int index}) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      height: 6,
      width: currentPage == index ? 20 : 6,
      decoration: BoxDecoration(
          color: currentPage == index ? CustomTheme.blue : Colors.grey,
          borderRadius: BorderRadius.circular(3)),
    );
  }
}

class SplashContent extends StatelessWidget {
  final String text, image;
  const SplashContent({Key? key, required this.text, required this.image})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
            // flex: 3,
            child: Column(
          children: [
            const Spacer(),
            Image(
              image: AssetImage(image),
              height: 200,
              width: 200,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                text,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Votre etablissement aux bouts des doits',
                  style: Theme.of(context).textTheme.bodySmall),
            )
          ],
        )),
      ],
    );
  }
}
