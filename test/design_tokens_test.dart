import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sasang/core/theme/sasang_theme.dart';

void main() {
  test('legacy tokens remain source-compatible semantic aliases', () {
    expect(SasangSemanticColors.canvas, SasangColors.background);
    expect(SasangSemanticColors.canvasSubtle, SasangColors.pageBackground);
    expect(SasangSemanticColors.surface, SasangColors.card);
    expect(SasangSemanticColors.textPrimary, SasangColors.ink);
    expect(SasangSemanticColors.accent, SasangColors.accent);
    expect(SasangSemanticColors.borderSubtle, SasangColors.border);

    expect(SasangSemanticSpacing.xSmall, SasangSpacing.xSmall);
    expect(SasangSemanticSpacing.small, SasangSpacing.small);
    expect(SasangSemanticSpacing.medium, SasangSpacing.medium);
    expect(SasangSemanticSpacing.large, SasangSpacing.large);
    expect(SasangSemanticSpacing.xLarge, SasangSpacing.xLarge);
    expect(SasangSemanticSpacing.xxLarge, SasangSpacing.xxLarge);

    expect(SasangSemanticRadii.contentCard, SasangRadii.contentCard);
    expect(SasangSemanticRadii.selectionCard, SasangRadii.selectionCard);
    expect(SasangSemanticRadii.pill, SasangRadii.pill);
    expect(SasangSemanticRadii.search, SasangRadii.pill);
    expect(SasangElevation.floating, SasangOverlayStyle.shadows);
  });

  test('small-text semantic colors meet WCAG AA on light surfaces', () {
    for (final background in [
      SasangSemanticColors.surface,
      SasangSemanticColors.canvas,
      SasangSemanticColors.canvasSubtle,
    ]) {
      expect(
        _contrastRatio(SasangSemanticColors.accentText, background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(SasangSemanticColors.tertiaryTextAccessible, background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(SasangSemanticColors.textSecondary, background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(SasangSemanticColors.destructiveText, background),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('typography keeps legal copy and title emphasis role-specific', () {
    expect(SasangSemanticTypography.legalBody.fontSize, 16);
    expect(SasangSemanticTypography.legalBody.height, 1.68);
    expect(SasangSemanticTypography.pageTitle.fontWeight, FontWeight.w700);
    expect(SasangSemanticTypography.display.fontWeight, FontWeight.w800);
    expect(SasangSemanticTypography.optionTitle.fontWeight, FontWeight.w700);
  });

  test('component state tokens expose stable semantic values', () {
    expect(SasangComponentStates.minimumTargetSize, 44);
    expect(
      SasangComponentStates.contentColor(SasangComponentState.disabled),
      SasangSemanticColors.disabledContent,
    );
    expect(
      SasangComponentStates.surfaceColor(SasangComponentState.selected),
      SasangSemanticColors.accentSoft,
    );
    expect(
      SasangComponentStates.surfaceColor(SasangComponentState.error),
      SasangSemanticColors.errorSoft,
    );
    expect(
      SasangComponentStates.contentColor(SasangComponentState.error),
      SasangSemanticColors.destructiveText,
    );
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
