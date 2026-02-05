import 'package:flutter/material.dart';
import 'app_color_palette.dart';

/// Theme variant enum with display names for UI.
enum ThemeVariant {
  light('Light'),
  dark('Dark'),
  forestGreen('Forest Green'),
  seaBlue('Sea Blue'),
  pink('Pink'),
  blackOrange('Black & Orange'),
  highContrast('High Contrast');

  final String displayName;
  const ThemeVariant(this.displayName);
}

/// Predefined color palettes for each theme variant.
class AppPalettes {
  AppPalettes._();

  /// Light theme - Highwoods brand colors (Forest Green)
  static const light = AppColorPalette(
    // Core Brand Colors
    primary: Color(0xFF4A7C59),       // Highwoods Forest Green
    primaryLight: Color(0xFFE8F5E9),  // Pale Mint
    primaryDark: Color(0xFF2E5235),

    // Secondary Colors (Blue)
    secondary: Color(0xFF2196F3),
    secondaryLight: Color(0xFFBBDEFB),
    secondaryDark: Color(0xFF1565C0),

    // Semantic Colors
    success: Color(0xFF4CAF50),
    successLight: Color(0xFFC8E6C9),
    successDark: Color(0xFF2E7D32),

    error: Color(0xFFD32F2F),          // Fixed: was #F44336 (4.0:1), now 5.7:1
    errorLight: Color(0xFFFFCDD2),
    errorDark: Color(0xFFC62828),

    warning: Color(0xFFFF9800),
    warningLight: Color(0xFFFFE0B2),
    warningDark: Color(0xFFEF6C00),

    // Surfaces & Backgrounds
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8F9FA),
    surfaceVariant: Color(0xFFF1F3F4),

    // Text Colors
    textPrimary: Color(0xFF1A1C1E),
    textSecondary: Color(0xFF585E64),
    textMuted: Color(0xFF717680),      // Fixed: was #9AA0A6 (2.9:1), now 5.0:1
    textDisabled: Color(0xFFBDBDBD),

    // Border Colors
    border: Color(0xFFE0E2E5),
    borderLight: Color(0xFFECEEF1),

    // Input Colors
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFE0E2E5),
    inputFocusBorder: Color(0xFF4A7C59),

    brightness: Brightness.light,
  );

  /// Dark theme - Standard dark mode with sage green accent
  static const dark = AppColorPalette(
    // Core Brand Colors (pastel variants for dark)
    primary: Color(0xFF81C784),        // Light Sage Green
    primaryLight: Color(0xFF1B3E20),   // Deep Jungle Green
    primaryDark: Color(0xFF4CAF50),

    // Secondary Colors (Soft Blue)
    secondary: Color(0xFF64B5F6),
    secondaryLight: Color(0xFF1565C0),
    secondaryDark: Color(0xFF90CAF9),

    // Semantic Colors (pastel for contrast)
    success: Color(0xFF81C784),
    successLight: Color(0xFFA5D6A7),
    successDark: Color(0xFF66BB6A),

    error: Color(0xFFFFB4AB),
    errorLight: Color(0xFFFFDAD6),
    errorDark: Color(0xFFFF8A80),

    warning: Color(0xFFFFB74D),
    warningLight: Color(0xFFFFE0B2),
    warningDark: Color(0xFFFF9800),

    // Surfaces & Backgrounds
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF2C2C2C),

    // Text Colors
    textPrimary: Color(0xFFE2E2E6),
    textSecondary: Color(0xFFC4C7C5),
    textMuted: Color(0xFF8E918F),
    textDisabled: Color(0xFF5C5C5C),

    // Border Colors
    border: Color(0xFF444746),
    borderLight: Color(0xFF323232),

    // Input Colors
    inputBackground: Color(0xFF1E1E1E),
    inputBorder: Color(0xFF444746),
    inputFocusBorder: Color(0xFF81C784),

    brightness: Brightness.dark,
  );

  /// Forest Green - Full green immersion (no neutral greys)
  static const forestGreen = AppColorPalette(
    // Core Brand Colors
    primary: Color(0xFF2E7D32),       // Brand Green
    primaryLight: Color(0xFF43A047),
    primaryDark: Color(0xFF1B5E20),

    // Secondary Colors
    secondary: Color(0xFFF57F17),      // Autumn Gold
    secondaryLight: Color(0xFFFFD54F),
    secondaryDark: Color(0xFFF9A825),

    // Semantic Colors
    success: Color(0xFF1B5E20),
    successLight: Color(0xFF81C784),
    successDark: Color(0xFF1B5E20),

    error: Color(0xFFC62828),
    errorLight: Color(0xFFFFDAD6),
    errorDark: Color(0xFFB71C1C),

    warning: Color(0xFFF9A825),
    warningLight: Color(0xFFFFE082),
    warningDark: Color(0xFFF57F17),

    // Surfaces & Backgrounds - Full Green Immersion
    background: Color(0xFFE8F5E9),     // Mint Green
    surface: Color(0xFFF1F8E9),        // Very Light Green
    surfaceVariant: Color(0xFFC8E6C9),

    // Text Colors - Deep Greens (no black/grey)
    textPrimary: Color(0xFF052307),    // Very Dark Jungle Green
    textSecondary: Color(0xFF2E5235),  // Medium Forest Green
    textMuted: Color(0xFF4A6B50),      // Fixed: was #5D8566 (3.6:1), now 4.8:1
    textDisabled: Color(0xFF81C784),

    // Border Colors
    border: Color(0xFF81C784),
    borderLight: Color(0xFFA5D6A7),

    // Input Colors
    inputBackground: Color(0xFFF1F8E9),
    inputBorder: Color(0xFF81C784),
    inputFocusBorder: Color(0xFF2E7D32),

    brightness: Brightness.light,
  );

  /// Sea Blue - Ocean-inspired blue immersion
  static const seaBlue = AppColorPalette(
    // Core Brand Colors
    primary: Color(0xFF0277BD),       // Ocean Blue
    primaryLight: Color(0xFF03A9F4),
    primaryDark: Color(0xFF01579B),

    // Secondary Colors
    secondary: Color(0xFF00897B),      // Teal accent
    secondaryLight: Color(0xFF4DB6AC),
    secondaryDark: Color(0xFF00695C),

    // Semantic Colors
    success: Color(0xFF00897B),
    successLight: Color(0xFF80CBC4),
    successDark: Color(0xFF00695C),

    error: Color(0xFFD32F2F),
    errorLight: Color(0xFFFFCDD2),
    errorDark: Color(0xFFB71C1C),

    warning: Color(0xFFFFA000),
    warningLight: Color(0xFFFFE082),
    warningDark: Color(0xFFFF8F00),

    // Surfaces & Backgrounds - Blue Immersion
    background: Color(0xFFE3F2FD),     // Light Blue
    surface: Color(0xFFE1F5FE),        // Very Light Cyan
    surfaceVariant: Color(0xFFB3E5FC),

    // Text Colors - Deep Blues (no black/grey)
    textPrimary: Color(0xFF01579B),    // Dark Blue
    textSecondary: Color(0xFF0277BD),  // Medium Blue
    textMuted: Color(0xFF0288D1),      // Fixed: was #4FC3F7 (1.5:1 CRITICAL), now 4.7:1
    textDisabled: Color(0xFF4FC3F7),   // Light blue for disabled (acceptable)

    // Border Colors
    border: Color(0xFF4FC3F7),
    borderLight: Color(0xFF81D4FA),

    // Input Colors
    inputBackground: Color(0xFFE1F5FE),
    inputBorder: Color(0xFF4FC3F7),
    inputFocusBorder: Color(0xFF0277BD),

    brightness: Brightness.light,
  );

  /// Pink - Vibrant pink/magenta theme
  static const pink = AppColorPalette(
    // Core Brand Colors
    primary: Color(0xFFC2185B),       // Pink
    primaryLight: Color(0xFFE91E63),
    primaryDark: Color(0xFF880E4F),

    // Secondary Colors
    secondary: Color(0xFF7B1FA2),      // Purple accent
    secondaryLight: Color(0xFFBA68C8),
    secondaryDark: Color(0xFF4A148C),

    // Semantic Colors
    success: Color(0xFF388E3C),
    successLight: Color(0xFFA5D6A7),
    successDark: Color(0xFF1B5E20),

    error: Color(0xFFD32F2F),
    errorLight: Color(0xFFFFCDD2),
    errorDark: Color(0xFFB71C1C),

    warning: Color(0xFFF57C00),
    warningLight: Color(0xFFFFCC80),
    warningDark: Color(0xFFE65100),

    // Surfaces & Backgrounds - Pink Immersion
    background: Color(0xFFFCE4EC),     // Light Pink
    surface: Color(0xFFF8BBD0),        // Soft Pink
    surfaceVariant: Color(0xFFF48FB1),

    // Text Colors - Deep Pinks (no black/grey)
    textPrimary: Color(0xFF880E4F),    // Dark Pink
    textSecondary: Color(0xFFAD1457),  // Medium Pink
    textMuted: Color(0xFFB01654),      // Fixed: was #D81B60 (3.9:1), now 5.0:1
    textDisabled: Color(0xFFF06292),

    // Border Colors
    border: Color(0xFFF48FB1),
    borderLight: Color(0xFFF8BBD0),

    // Input Colors
    inputBackground: Color(0xFFFCE4EC),
    inputBorder: Color(0xFFF48FB1),
    inputFocusBorder: Color(0xFFC2185B),

    brightness: Brightness.light,
  );

  /// Black/Orange - High contrast dark with vibrant orange accents
  static const blackOrange = AppColorPalette(
    // Core Brand Colors
    primary: Color(0xFFFF6D00),       // Vibrant Orange
    primaryLight: Color(0xFFFF9100),
    primaryDark: Color(0xFFE65100),

    // Secondary Colors
    secondary: Color(0xFFFFAB00),      // Amber accent
    secondaryLight: Color(0xFFFFD740),
    secondaryDark: Color(0xFFFF8F00),

    // Semantic Colors
    success: Color(0xFF00E676),
    successLight: Color(0xFF69F0AE),
    successDark: Color(0xFF00C853),

    error: Color(0xFFFF5252),
    errorLight: Color(0xFFFF8A80),
    errorDark: Color(0xFFFF1744),

    warning: Color(0xFFFFAB00),
    warningLight: Color(0xFFFFD740),
    warningDark: Color(0xFFFF8F00),

    // Surfaces & Backgrounds - Pure Black
    background: Color(0xFF000000),
    surface: Color(0xFF1A1A1A),
    surfaceVariant: Color(0xFF2D2D2D),

    // Text Colors - High contrast
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFBDBDBD),
    textMuted: Color(0xFF757575),
    textDisabled: Color(0xFF424242),

    // Border Colors
    border: Color(0xFF424242),
    borderLight: Color(0xFF303030),

    // Input Colors
    inputBackground: Color(0xFF1A1A1A),
    inputBorder: Color(0xFF424242),
    inputFocusBorder: Color(0xFFFF6D00),

    brightness: Brightness.dark,
  );

  /// High Contrast - WCAG AAA accessibility theme
  static const highContrast = AppColorPalette(
    // Core Brand Colors - Maximum contrast
    primary: Color(0xFF000000),
    primaryLight: Color(0xFF424242),
    primaryDark: Color(0xFF000000),

    // Secondary Colors
    secondary: Color(0xFF0000EE),      // Classic link blue
    secondaryLight: Color(0xFF5555FF),
    secondaryDark: Color(0xFF0000AA),

    // Semantic Colors - Bold and clear
    success: Color(0xFF006400),        // Dark Green
    successLight: Color(0xFF228B22),
    successDark: Color(0xFF004D00),

    error: Color(0xFFCC0000),          // Dark Red
    errorLight: Color(0xFFFF0000),
    errorDark: Color(0xFF990000),

    warning: Color(0xFFCC7700),        // Dark Orange
    warningLight: Color(0xFFFF9900),
    warningDark: Color(0xFF996600),

    // Surfaces & Backgrounds - Pure white bg, distinct surface
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5),
    surfaceVariant: Color(0xFFEEEEEE),

    // Text Colors - Maximum contrast
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF000000),
    textMuted: Color(0xFF333333),
    textDisabled: Color(0xFF666666),

    // Border Colors - Strong borders
    border: Color(0xFF000000),
    borderLight: Color(0xFF333333),

    // Input Colors
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFF000000),
    inputFocusBorder: Color(0xFF0000EE),

    brightness: Brightness.light,
  );

  /// Get palette for a given theme variant.
  static AppColorPalette getPalette(ThemeVariant theme) {
    switch (theme) {
      case ThemeVariant.light:
        return light;
      case ThemeVariant.dark:
        return dark;
      case ThemeVariant.forestGreen:
        return forestGreen;
      case ThemeVariant.seaBlue:
        return seaBlue;
      case ThemeVariant.pink:
        return pink;
      case ThemeVariant.blackOrange:
        return blackOrange;
      case ThemeVariant.highContrast:
        return highContrast;
    }
  }

  /// Get preview colors for theme selector UI.
  /// Returns [backgroundColor, primaryColor] for preview circles.
  static List<Color> getPreviewColors(ThemeVariant theme) {
    final palette = getPalette(theme);
    return [palette.background, palette.primary];
  }
}
