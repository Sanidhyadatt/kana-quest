import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme =
        ColorScheme.light(
          primary: const Color(0xFF7B5455),
          onPrimary: const Color(0xFFFFFFFF),
          primaryContainer: const Color(0xFFF4C2C2),
          secondary: const Color(0xFF5B5B7E),
          tertiary: const Color(0xFF486456),
          surface: const Color(0xFFFBF9F5),
          onSurface: const Color(0xFF1B1C1A),
          error: const Color(0xFFBA1A1A),
        ).copyWith(
          outline: const Color(0xFF827473),
          outlineVariant: const Color(0xFFD4C2C2),
          surfaceContainer: const Color(0xFFEFEEEA),
          surfaceContainerHigh: const Color(0xFFEAE8E4),
          surfaceContainerHighest: const Color(0xFFE4E2DE),
          surfaceContainerLow: const Color(0xFFF5F3EF),
          surfaceContainerLowest: const Color(0xFFFFFFFF),
          surfaceBright: const Color(0xFFFBF9F5),
          surfaceDim: const Color(0xFFDBDAD6),
          inverseSurface: const Color(0xFF30312E),
          onInverseSurface: const Color(0xFFF2F0ED),
          inversePrimary: const Color(0xFFECBABA),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFBF9F5),
      fontFamily: 'Plus Jakarta Sans',
    );
  }
}
