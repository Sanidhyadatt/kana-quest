import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
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

    const baseTextStyle = TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      package: null, // Ensure local font is used
      color: Color(0xFF1B1C1A),
      height: 1.5,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFBF9F5),
      fontFamily: 'Plus Jakarta Sans',
      textTheme: TextTheme(
        displayLarge: baseTextStyle.copyWith(fontSize: 57, fontWeight: FontWeight.w800, height: 1.1),
        displayMedium: baseTextStyle.copyWith(fontSize: 45, fontWeight: FontWeight.w800, height: 1.1),
        displaySmall: baseTextStyle.copyWith(fontSize: 36, fontWeight: FontWeight.w700, height: 1.1),
        headlineLarge: baseTextStyle.copyWith(fontSize: 32, fontWeight: FontWeight.w800),
        headlineMedium: baseTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
        headlineSmall: baseTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: baseTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
        bodyMedium: baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6),
        labelLarge: baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        labelMedium: baseTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        labelSmall: baseTextStyle.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
        color: Color(0xFFFFFFFF),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}
