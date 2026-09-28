import 'package:flutter/material.dart';

abstract final class SasangColors {
  static const background = Color(0xFFFAFAFA);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF18181B);
  static const secondary = Color(0xFF71717A);
  static const accent = Color(0xFF007AFF);
  static const divider = Color(0x12000000);
}

abstract final class SasangOverlayStyle {
  static const border = Color(0x1A000000);
  static const shadows = [
    BoxShadow(color: Color(0x1718181B), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A18181B), blurRadius: 3, offset: Offset(0, 1)),
  ];
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
      useMaterial3: false,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: SasangColors.background,
        foregroundColor: SasangColors.ink,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerColor: SasangColors.divider,
      textTheme: base.textTheme.apply(
        bodyColor: SasangColors.ink,
        displayColor: SasangColors.ink,
      ),
    );
  }
}
