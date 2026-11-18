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

/// Semantic color aliases for new and incrementally migrated UI.
///
/// The legacy [SasangColors] API remains the source of the currently rendered
/// application colors. These aliases deliberately do not change existing
/// widgets. Small text should use [accentText] or [tertiaryTextAccessible]
/// instead of the decorative accent/tertiary colors so it reaches WCAG AA on
/// the light Sasang surfaces.
abstract final class SasangSemanticColors {
  static const canvas = SasangColors.background;
  static const canvasSubtle = SasangColors.pageBackground;
  static const surface = SasangColors.card;
  static const surfaceSubtle = Color(0xFFF4F4F5);

  static const textPrimary = SasangColors.ink;
  static const textSecondary = Color(0xFF52525B);
  static const textTertiary = Color(0xFF8E8E93);
  static const tertiaryTextAccessible = Color(0xFF636366);

  static const accent = SasangColors.accent;
  static const accentText = Color(0xFF0066CC);
  static const accentSoft = Color(0xFFEAF4FF);

  static const borderSubtle = SasangColors.border;
  static const borderFloating = Color(0x1A000000);
  static const divider = SasangColors.divider;
  static const destructive = Color(0xFFFF3B30);
  static const destructiveText = Color(0xFFD70015);
  static const disabledSurface = Color(0xFFE4E4E7);
  static const disabledContent = Color(0xFF8E8E93);
  static const errorSoft = Color(0x1AFF3B30);
  static const sheetScrim = Color(0x47000000);
  static const dialogScrim = Color(0x57000000);
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

/// Role-based radii for new components.
///
/// Search and compact map controls intentionally keep a pill silhouette and
/// must not use [control]. The 8dp photo-card radius is also preserved.
abstract final class SasangSemanticRadii {
  static const radiusMedia = 8.0;
  static const radiusCompact = 12.0;
  static const radiusControl = 16.0;
  static const radiusSettingsGroup = 20.0;
  static const radiusContentCard = SasangRadii.radiusContentCard;
  static const radiusSelectionCard = SasangRadii.radiusSelectionCard;
  static const radiusSheet = 28.0;
  static const radiusDialog = 28.0;
  static const radiusNavigation = 34.0;
  static const radiusPill = SasangRadii.radiusPill;

  static const media = BorderRadius.all(Radius.circular(radiusMedia));
  static const compact = BorderRadius.all(Radius.circular(radiusCompact));
  static const control = BorderRadius.all(Radius.circular(radiusControl));
  static const search = SasangRadii.pill;
  static const settingsGroup = BorderRadius.all(
    Radius.circular(radiusSettingsGroup),
  );
  static const contentCard = SasangRadii.contentCard;
  static const selectionCard = SasangRadii.selectionCard;
  static const sheet = BorderRadius.all(Radius.circular(radiusSheet));
  static const sheetTop = BorderRadius.vertical(
    top: Radius.circular(radiusSheet),
  );
  static const dialog = BorderRadius.all(Radius.circular(radiusDialog));
  static const navigation = BorderRadius.all(Radius.circular(radiusNavigation));
  static const pill = SasangRadii.pill;
}

abstract final class SasangSpacing {
  static const xSmall = 4.0;
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const xLarge = 24.0;
  static const xxLarge = 32.0;
}

/// Semantic spacing scale. The 2dp and 6dp values are intentional optical and
/// close-relationship exceptions; this is not an 8dp-only grid.
abstract final class SasangSemanticSpacing {
  static const optical = 2.0;
  static const xSmall = SasangSpacing.xSmall;
  static const close = 6.0;
  static const small = SasangSpacing.small;
  static const medium = SasangSpacing.medium;
  static const large = SasangSpacing.large;
  static const sheet = 20.0;
  static const xLarge = SasangSpacing.xLarge;
  static const xxLarge = SasangSpacing.xxLarge;
  static const xxxLarge = 40.0;

  static const mapOverlayInset = 16.0;
  static const pageInset = 20.0;
  static const documentInset = 24.0;
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

/// Role-based typography for new and incrementally migrated UI.
///
/// Legal copy stays at 16sp and is intentionally separate from ordinary body
/// copy. Weight 800 is reserved for display emphasis and is not the default
/// for every title.
abstract final class SasangSemanticTypography {
  static const display = TextStyle(
    color: SasangSemanticColors.textPrimary,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w800,
  );
  static const pageTitle = TextStyle(
    color: SasangSemanticColors.textPrimary,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
  );
  static const navigationTitle = TextStyle(
    color: SasangSemanticColors.textPrimary,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w700,
  );
  static const sheetTitle = TextStyle(
    color: SasangSemanticColors.textPrimary,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w800,
  );
  static const sectionTitle = TextStyle(
    color: SasangSemanticColors.textPrimary,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
  );
  static const groupLabel = TextStyle(
    color: SasangSemanticColors.textPrimary,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
  );
  static const optionTitle = TextStyle(
    color: SasangSemanticColors.textPrimary,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(
    color: SasangSemanticColors.textPrimary,
    fontSize: 15,
    height: 23 / 15,
    fontWeight: FontWeight.w400,
  );
  static const legalBody = TextStyle(
    color: SasangSemanticColors.textSecondary,
    fontSize: 16,
    height: 1.68,
    fontWeight: FontWeight.w400,
  );
  static const bodyStrong = TextStyle(
    color: SasangSemanticColors.textPrimary,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w700,
  );
  static const supporting = TextStyle(
    color: SasangSemanticColors.textSecondary,
    fontSize: 13,
    height: 19 / 13,
    fontWeight: FontWeight.w400,
  );
  static const caption = TextStyle(
    color: SasangSemanticColors.tertiaryTextAccessible,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
  );
  static const micro = TextStyle(
    color: SasangSemanticColors.textSecondary,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
  );
  static const button = TextStyle(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w700,
  );
  static const tabLabel = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
  );
}

abstract final class SasangBorders {
  static const hairlineWidth = 0.5;
  static const subtleWidth = 0.75;
  static const floatingWidth = 0.75;
  static const selectedWidth = 1.25;
  static const focusWidth = 2.0;

  static const subtle = BorderSide(
    color: SasangSemanticColors.borderSubtle,
    width: subtleWidth,
  );
  static const floating = BorderSide(
    color: SasangSemanticColors.borderFloating,
    width: floatingWidth,
  );
  static const selected = BorderSide(
    color: Color(0xB8007AFF),
    width: selectedWidth,
  );
  static const focus = BorderSide(
    color: SasangSemanticColors.accent,
    width: focusWidth,
  );
}

abstract final class SasangOverlayStyle {
  static const border = Color(0x1A000000);
  static const shadows = [
    BoxShadow(color: Color(0x1718181B), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A18181B), blurRadius: 3, offset: Offset(0, 1)),
  ];
}

/// Elevation roles. Existing widgets keep [SasangOverlayStyle.shadows] until
/// they are migrated in a separately approved visual-change phase.
abstract final class SasangElevation {
  static const none = <BoxShadow>[];
  static const low = [
    BoxShadow(color: Color(0x0F18181B), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const floating = SasangOverlayStyle.shadows;
  static const modal = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
  ];
  static const photo = [
    BoxShadow(color: Color(0x1418181B), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

abstract final class SasangMotion {
  static const instant = Duration(milliseconds: 100);
  static const standard = Duration(milliseconds: 180);
  static const modalEnter = Duration(milliseconds: 200);
  static const modalExit = Duration(milliseconds: 160);
  static const sheet = Duration(milliseconds: 280);
  static const page = Duration(milliseconds: 280);
  static const reduced = Duration(milliseconds: 100);

  static const standardCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;
  static const sheetCurve = Curves.easeOutCubic;
}

enum SasangComponentState {
  normal,
  pressed,
  selected,
  disabled,
  error,
  loading,
}

abstract final class SasangComponentStates {
  static const pressedContentOpacity = 0.72;
  static const pressedDestructiveOpacity = 0.64;
  static const disabledContentOpacity = 0.45;
  static const hoverOverlayOpacity = 0.04;
  static const minimumTargetSize = 44.0;

  static Color contentColor(SasangComponentState state) => switch (state) {
    SasangComponentState.disabled => SasangSemanticColors.disabledContent,
    SasangComponentState.error => SasangSemanticColors.destructiveText,
    SasangComponentState.selected => SasangSemanticColors.accent,
    _ => SasangSemanticColors.textPrimary,
  };

  static Color surfaceColor(SasangComponentState state) => switch (state) {
    SasangComponentState.disabled => SasangSemanticColors.disabledSurface,
    SasangComponentState.error => SasangSemanticColors.errorSoft,
    SasangComponentState.selected => SasangSemanticColors.accentSoft,
    _ => SasangSemanticColors.surface,
  };
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
