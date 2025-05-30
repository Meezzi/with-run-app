import 'package:flutter/material.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> scaffoldMessage({
  required BuildContext context,
  required String text,
  TextStyle? style,
}) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        textAlign: TextAlign.center,
        style: style ?? TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
