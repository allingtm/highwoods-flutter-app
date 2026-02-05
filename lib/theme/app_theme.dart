import 'package:flutter/material.dart';
import 'app_color_palette.dart';
import 'app_palettes.dart';
import 'app_theme_tokens.dart';

/// Factory class for creating ThemeData from color palettes.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF4A7C59);  // Highwoods brand green

  /// Create ThemeData from a color palette.
  /// This is the primary factory method used by the theme provider.
  static ThemeData fromPalette(AppColorPalette palette) {
    final isDark = palette.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,

      // Color Scheme
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: palette.primary,
        onPrimary: isDark ? Colors.black : Colors.white,
        primaryContainer: palette.primaryLight,
        onPrimaryContainer: isDark ? Colors.white : palette.primaryDark,
        secondary: palette.secondary,
        onSecondary: isDark ? Colors.black : Colors.white,
        secondaryContainer: palette.secondaryLight,
        onSecondaryContainer: isDark ? Colors.white : palette.secondaryDark,
        error: palette.error,
        onError: isDark ? Colors.black : Colors.white,
        errorContainer: palette.errorLight,
        onErrorContainer: palette.errorDark,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        surfaceContainerHighest: palette.surfaceVariant,
        outline: palette.border,
        outlineVariant: palette.borderLight,
      ),

      // Scaffold
      scaffoldBackgroundColor: palette.background,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
      ),

      // Card
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.borderLight),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.inputFocusBorder, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error),
        ),
        labelStyle: TextStyle(color: palette.textSecondary),
        hintStyle: TextStyle(color: palette.textMuted),
      ),

      // Extensions
      extensions: <ThemeExtension<dynamic>>[
        palette,
        AppThemeTokens.standard,
      ],
    );
  }

  /// Light theme (convenience method)
  static ThemeData light() => fromPalette(AppPalettes.light);

  /// Dark theme (convenience method)
  static ThemeData dark() => fromPalette(AppPalettes.dark);
}

/// Extension to easily access AppThemeTokens from BuildContext
extension AppThemeTokensExtension on BuildContext {
  AppThemeTokens get tokens =>
      Theme.of(this).extension<AppThemeTokens>() ?? const AppThemeTokens();
}
