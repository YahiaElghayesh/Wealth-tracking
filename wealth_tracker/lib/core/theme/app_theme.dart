import 'package:flutter/material.dart';

ThemeData buildAppTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D6B),
      brightness: brightness,
    ),
  );
}
