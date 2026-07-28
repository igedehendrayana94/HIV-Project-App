import 'package:flutter/material.dart';

// Matches the web app's teal branding (globals.css / loading.tsx spinner).
final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488)),
  useMaterial3: true,
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
);
