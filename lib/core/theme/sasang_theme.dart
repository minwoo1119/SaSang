import 'package:flutter/material.dart';

abstract final class SasangColors {
  static const background = Color(0xFFFAFAFA);
  static const pageBackground = Color(0xFFF7F7F8);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE9E9ED);
  static const ink = Color(0xFF18181B);
  static const secondary = Color(0xFF71717A);
  static const accent = Color(0xFF007AFF);
  static const divider = Color(0x12000000);
}

abstract final class SasangRadii {
  static const radiusPill = 999.0;
  static const radiusSheet = 30.0;
  static const radiusSelectionCard = 24.0;
  static const radiusActionButton = 24.0;
  static const radiusContentCard = 22.0;

  static const pill = BorderRadius.all(Radius.circular(radiusPill));
  static const sheetTop = BorderRadius.vertical(
    top: Radius.circular(radiusSheet),
  );
  static const selectionCard = BorderRadius.all(
    Radius.circular(radiusSelectionCard),
  );
  static const actionButton = BorderRadius.all(
    Radius.circular(radiusActionButton),
  );
  static const contentCard = BorderRadius.all(
    Radius.circular(radiusContentCard),
  );
}

abstract final class SasangSpacing {
  static const xSmall = 4.0;
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const xLarge = 24.0;
  static const xxLarge = 32.0;
}

abstract final class SasangTypography {
  static const sheetTitle = TextStyle(
    color: SasangColors.ink,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -.5,
  );
  static const sheetDescription = TextStyle(
    color: SasangColors.secondary,
    fontSize: 14,
    height: 1.45,
    letterSpacing: -.15,
  );
  static const optionTitle = TextStyle(
    color: SasangColors.ink,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: -.3,
  );
  static const optionDescription = TextStyle(
    color: SasangColors.secondary,
    fontSize: 13,
    height: 1.4,
    letterSpacing: -.1,
  );
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
