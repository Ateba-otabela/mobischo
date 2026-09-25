// ignore_for_file: must_be_immutable, avoid_unnecessary_containers

import 'package:flutter/material.dart';
import 'package:mobischo/utils/custom_theme.dart';

class CustomInput extends StatefulWidget {
  CustomInput(
      {Key? key,
      required this.controller,
      required this.hintText,
      required this.labelText,
      required this.isPassword,
      required this.prefixIcon,
      required this.surfixIcon,
      required this.readOnly,
      required this.borderColor,
      required this.helperText,
      this.enablePasswordToggle = false})
      : super(key: key);

  TextEditingController controller = TextEditingController();
  final String hintText;
  final String labelText;
  final IconData prefixIcon;
  final IconData surfixIcon;
  final bool isPassword;
  final bool readOnly;
  final Color borderColor;
  final String helperText;
  final bool enablePasswordToggle;

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextFormField(
        obscureText: widget.isPassword ? _obscureText : false,
        readOnly: widget.readOnly ? true : false,
        controller: widget.controller,
        decoration: InputDecoration(
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: CustomTheme.blue, width: 1.0)),
            enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: CustomTheme.grey, width: 1.0)),
            border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1.0)),
            hintText: widget.hintText,

            // labelStyle: TextStyle(color: CustomTheme.blue),

            labelText: widget.labelText,
            helperText: widget.helperText,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: widget.enablePasswordToggle
                ? IconButton(
                    icon: Icon(_obscureText
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : Icon(widget.surfixIcon)),
      ),
    );
  }
}
