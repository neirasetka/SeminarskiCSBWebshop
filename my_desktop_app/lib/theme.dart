import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6),
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.light,
    visualDensity: VisualDensity.comfortable,
  );
}

ThemeData buildDarkTheme() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF60A5FA),
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.dark,
    visualDensity: VisualDensity.comfortable,
  );
}

