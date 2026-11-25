import 'package:flutter/material.dart';

const kBackground = Color(0xFF0B0B12);
const kSurface = Color(0xFF151521);
const kAccents = <Color>[
  Color(0xFF7C5CFF),
  Color(0xFF00D1B2),
  Color(0xFFFF5C8A),
  Color(0xFFFFB020),
  Color(0xFF3DA5FF),
];

ThemeData buildTheme(Color accent) {
  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.dark,
  ).copyWith(surface: kBackground, primary: accent);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF10101A),
      indicatorColor: accent.withAlpha(70),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    sliderTheme: const SliderThemeData(trackHeight: 4),
  );
}
