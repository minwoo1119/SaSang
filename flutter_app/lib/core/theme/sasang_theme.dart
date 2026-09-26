import 'package:flutter/material.dart';

abstract final class SasangColors {
  static const background = Color(0xFFFAFAFA);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF18181B);
  static const secondary = Color(0xFF71717A);
  static const accent = Color(0xFF007AFF);
  static const divider = Color(0x12000000);
}

abstract final class SasangTheme {
  static ThemeData get light {
    final base = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SasangColors.accent,
        primary: SasangColors.accent,
        surface: SasangColors.card,
      ),
      scaffoldBackgroundColor: SasangColors.background,
      useMaterial3: true,
      fontFamilyFallback: const ['Apple SD Gothic Neo', 'Noto Sans KR'],
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: SasangColors.background,
        foregroundColor: SasangColors.ink,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: SasangColors.divider,
      textTheme: base.textTheme.apply(
        bodyColor: SasangColors.ink,
        displayColor: SasangColors.ink,
      ),
    );
  }
}
