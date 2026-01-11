import 'package:flutter/material.dart';
import 'app_theme_tokens.dart';

class AppTheme {
  AppTheme._();

  static const _seedColor = Colors.blue;

  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      extensions: const [
        AppThemeTokens.standard,
      ],
    );
  }

  static ThemeData get dark {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      extensions: const [
        AppThemeTokens.standard,
      ],
    );
  }
}

/// Extension to easily access AppThemeTokens from BuildContext
extension AppThemeTokensExtension on BuildContext {
  AppThemeTokens get tokens =>
      Theme.of(this).extension<AppThemeTokens>() ?? const AppThemeTokens();
}
