import 'package:flutter/material.dart';

/// Color palette as a ThemeExtension for reactive theming with smooth transitions.
///
/// Access via `context.colors` extension for reactive color access.
class AppColorPalette extends ThemeExtension<AppColorPalette> {
  // Primary Colors
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  // Secondary Colors
  final Color secondary;
  final Color secondaryLight;
  final Color secondaryDark;

  // Semantic Colors
  final Color success;
  final Color successLight;
  final Color successDark;

  final Color error;
  final Color errorLight;
  final Color errorDark;

  final Color warning;
  final Color warningLight;
  final Color warningDark;

  // Neutral Colors
  final Color background;
  final Color surface;
  final Color surfaceVariant;

  // Text Colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;

  // Border Colors
  final Color border;
  final Color borderLight;

  // Input Colors
  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusBorder;

  // Mode
  final Brightness brightness;

  const AppColorPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryLight,
    required this.secondaryDark,
    required this.success,
    required this.successLight,
    required this.successDark,
    required this.error,
    required this.errorLight,
    required this.errorDark,
    required this.warning,
    required this.warningLight,
    required this.warningDark,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.border,
    required this.borderLight,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusBorder,
    required this.brightness,
  });

  @override
  AppColorPalette copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? secondary,
    Color? secondaryLight,
    Color? secondaryDark,
    Color? success,
    Color? successLight,
    Color? successDark,
    Color? error,
    Color? errorLight,
    Color? errorDark,
    Color? warning,
    Color? warningLight,
    Color? warningDark,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? border,
    Color? borderLight,
    Color? inputBackground,
    Color? inputBorder,
    Color? inputFocusBorder,
    Brightness? brightness,
  }) {
    return AppColorPalette(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      secondaryDark: secondaryDark ?? this.secondaryDark,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      successDark: successDark ?? this.successDark,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      errorDark: errorDark ?? this.errorDark,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      warningDark: warningDark ?? this.warningDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      inputFocusBorder: inputFocusBorder ?? this.inputFocusBorder,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  AppColorPalette lerp(ThemeExtension<AppColorPalette>? other, double t) {
    if (other is! AppColorPalette) return this;

    return AppColorPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t)!,
      secondaryDark: Color.lerp(secondaryDark, other.secondaryDark, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      successDark: Color.lerp(successDark, other.successDark, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      warningDark: Color.lerp(warningDark, other.warningDark, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputFocusBorder: Color.lerp(inputFocusBorder, other.inputFocusBorder, t)!,
      // Brightness switches at the halfway point
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

/// Extension for easy access to color palette via BuildContext.
/// Usage: `final colors = context.colors;`
extension AppColorsExtension on BuildContext {
  AppColorPalette get colors {
    return Theme.of(this).extension<AppColorPalette>() ?? _lightPaletteFallback;
  }
}

// Fallback palette (light theme) to prevent crashes if extension not registered
const _lightPaletteFallback = AppColorPalette(
  primary: Color(0xFF4A7C59),
  primaryLight: Color(0xFFE8F5E9),
  primaryDark: Color(0xFF2E5235),
  secondary: Color(0xFF2196F3),
  secondaryLight: Color(0xFFBBDEFB),
  secondaryDark: Color(0xFF1565C0),
  success: Color(0xFF4CAF50),
  successLight: Color(0xFFC8E6C9),
  successDark: Color(0xFF2E7D32),
  error: Color(0xFFF44336),
  errorLight: Color(0xFFFFCDD2),
  errorDark: Color(0xFFC62828),
  warning: Color(0xFFFF9800),
  warningLight: Color(0xFFFFE0B2),
  warningDark: Color(0xFFEF6C00),
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFF8F9FA),
  surfaceVariant: Color(0xFFF1F3F4),
  textPrimary: Color(0xFF1A1C1E),
  textSecondary: Color(0xFF585E64),
  textMuted: Color(0xFF9AA0A6),
  textDisabled: Color(0xFFBDBDBD),
  border: Color(0xFFE0E2E5),
  borderLight: Color(0xFFECEEF1),
  inputBackground: Color(0xFFFFFFFF),
  inputBorder: Color(0xFFE0E2E5),
  inputFocusBorder: Color(0xFF4A7C59),
  brightness: Brightness.light,
);
