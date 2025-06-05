import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue.shade600,
    brightness: Brightness.light,
    primaryContainer: Colors.grey.shade300,
    secondaryContainer: Colors.white,
  ),
  dividerColor: Colors.grey.shade400,
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
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
