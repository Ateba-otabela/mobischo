import 'package:flutter/material.dart';
import 'package:mobischo/components/loader.dart';
import 'package:mobischo/utils/custom_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final void Function() onPress;
  final bool loading;

  const CustomButton(
      {Key? key,
      required this.text,
      this.loading = false,
      required this.onPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          color: CustomTheme.blue,
          boxShadow: CustomTheme.buttonShadow),
      child: MaterialButton(
          onPressed: loading ? null : onPress,
          child: loading
              ? const Loader()
              : Text(text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      // fontWeight: FontWeight.bold,
                      letterSpacing: 1))),
    );
  }
}
