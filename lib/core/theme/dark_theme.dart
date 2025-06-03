import 'package:flutter/material.dart';

final darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue.shade600,
    brightness: Brightness.dark,
    primaryContainer: Colors.grey.shade900,
    secondaryContainer: Colors.grey.shade700,
  ),
  dividerColor: Colors.grey.shade100,
  bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.grey.shade900),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    ),
  ),
);
