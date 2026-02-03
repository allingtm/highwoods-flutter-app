import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_color_palette.dart';
import '../theme/app_palettes.dart';
import '../theme/app_theme.dart';

// ============================================================
// Theme Variant Provider
// ============================================================

const String _themeVariantKey = 'theme_variant';

/// Notifier for managing theme variant state with persistence
class ThemeVariantNotifier extends StateNotifier<ThemeVariant> {
  ThemeVariantNotifier() : super(ThemeVariant.light) {
    _loadThemeVariant();
  }

  /// Load saved theme variant from SharedPreferences
  Future<void> _loadThemeVariant() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVariant = prefs.getString(_themeVariantKey);
      if (savedVariant != null) {
        state = ThemeVariant.values.firstWhere(
          (v) => v.name == savedVariant,
          orElse: () => ThemeVariant.light,
        );
      }
    } catch (e) {
      // If loading fails, keep default (light)
      debugPrint('Failed to load theme variant: $e');
    }
  }

  /// Set theme variant and persist to SharedPreferences
  Future<void> setThemeVariant(ThemeVariant variant) async {
    state = variant;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeVariantKey, variant.name);
    } catch (e) {
      debugPrint('Failed to save theme variant: $e');
    }
  }
}

/// Provider for theme variant state
final themeVariantProvider = StateNotifierProvider<ThemeVariantNotifier, ThemeVariant>(
  (ref) => ThemeVariantNotifier(),
);

/// Provider for the current color palette based on selected theme variant
final currentPaletteProvider = Provider<AppColorPalette>((ref) {
  final variant = ref.watch(themeVariantProvider);
  return AppPalettes.getPalette(variant);
});

/// Provider for the complete ThemeData based on current palette
final themeDataProvider = Provider<ThemeData>((ref) {
  final palette = ref.watch(currentPaletteProvider);
  return AppTheme.fromPalette(palette);
});

/// Helper to get theme variant icon
IconData getThemeVariantIcon(ThemeVariant variant) {
  switch (variant) {
    case ThemeVariant.light:
      return Icons.light_mode;
    case ThemeVariant.dark:
      return Icons.dark_mode;
    case ThemeVariant.forestGreen:
      return Icons.forest;
    case ThemeVariant.seaBlue:
      return Icons.water;
    case ThemeVariant.pink:
      return Icons.favorite;
    case ThemeVariant.blackOrange:
      return Icons.contrast;
    case ThemeVariant.highContrast:
      return Icons.accessibility_new;
  }
}

// ============================================================
// Legacy Theme Mode Provider (kept for backward compatibility)
// ============================================================

const String _themeModeKey = 'theme_mode';

/// Notifier for managing theme mode state with persistence
/// @deprecated Use themeVariantProvider instead
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);
      if (savedMode != null) {
        state = _themeModeFromString(savedMode);
      }
    } catch (e) {
      // If loading fails, keep default (system)
      debugPrint('Failed to load theme mode: $e');
    }
  }

  /// Set theme mode and persist to SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeModeToString(mode));
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
    }
  }

  /// Convert ThemeMode to string for storage
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convert string to ThemeMode
  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

/// Provider for theme mode state
/// @deprecated Use themeVariantProvider instead
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Helper to get theme mode display name
/// @deprecated Use ThemeVariant.displayName instead
String getThemeModeDisplayName(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
    case ThemeMode.system:
      return 'System';
  }
}

/// Helper to get theme mode icon
/// @deprecated Use getThemeVariantIcon instead
IconData getThemeModeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return Icons.light_mode;
    case ThemeMode.dark:
      return Icons.dark_mode;
    case ThemeMode.system:
      return Icons.settings_brightness;
  }
}
