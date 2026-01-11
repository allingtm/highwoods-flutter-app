import 'package:flutter/material.dart';

class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    this.spacingXs = 4,
    this.spacingSm = 8,
    this.spacingMd = 12,
    this.spacingLg = 16,
    this.spacingXl = 24,
    this.spacing2xl = 32,
    this.spacing3xl = 40,
    this.spacing4xl = 60,
    this.radiusSm = 4,
    this.radiusMd = 8,
    this.radiusLg = 12,
    this.radiusXl = 16,
    this.iconSm = 20,
    this.iconMd = 35,
    this.iconLg = 48,
    this.iconXl = 80,
    this.icon2xl = 100,
  });

  // Spacing scale
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;
  final double spacing2xl;
  final double spacing3xl;
  final double spacing4xl;

  // Border radius scale
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;

  // Icon sizes
  final double iconSm;
  final double iconMd;
  final double iconLg;
  final double iconXl;
  final double icon2xl;

  @override
  AppThemeTokens copyWith({
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? spacing2xl,
    double? spacing3xl,
    double? spacing4xl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? iconSm,
    double? iconMd,
    double? iconLg,
    double? iconXl,
    double? icon2xl,
  }) {
    return AppThemeTokens(
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      spacing2xl: spacing2xl ?? this.spacing2xl,
      spacing3xl: spacing3xl ?? this.spacing3xl,
      spacing4xl: spacing4xl ?? this.spacing4xl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      iconSm: iconSm ?? this.iconSm,
      iconMd: iconMd ?? this.iconMd,
      iconLg: iconLg ?? this.iconLg,
      iconXl: iconXl ?? this.iconXl,
      icon2xl: icon2xl ?? this.icon2xl,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) {
      return this;
    }
    return AppThemeTokens(
      spacingXs: lerpDouble(spacingXs, other.spacingXs, t) ?? spacingXs,
      spacingSm: lerpDouble(spacingSm, other.spacingSm, t) ?? spacingSm,
      spacingMd: lerpDouble(spacingMd, other.spacingMd, t) ?? spacingMd,
      spacingLg: lerpDouble(spacingLg, other.spacingLg, t) ?? spacingLg,
      spacingXl: lerpDouble(spacingXl, other.spacingXl, t) ?? spacingXl,
      spacing2xl: lerpDouble(spacing2xl, other.spacing2xl, t) ?? spacing2xl,
      spacing3xl: lerpDouble(spacing3xl, other.spacing3xl, t) ?? spacing3xl,
      spacing4xl: lerpDouble(spacing4xl, other.spacing4xl, t) ?? spacing4xl,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t) ?? radiusSm,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t) ?? radiusMd,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t) ?? radiusLg,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t) ?? radiusXl,
      iconSm: lerpDouble(iconSm, other.iconSm, t) ?? iconSm,
      iconMd: lerpDouble(iconMd, other.iconMd, t) ?? iconMd,
      iconLg: lerpDouble(iconLg, other.iconLg, t) ?? iconLg,
      iconXl: lerpDouble(iconXl, other.iconXl, t) ?? iconXl,
      icon2xl: lerpDouble(icon2xl, other.icon2xl, t) ?? icon2xl,
    );
  }

  static double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  static const standard = AppThemeTokens();
}
