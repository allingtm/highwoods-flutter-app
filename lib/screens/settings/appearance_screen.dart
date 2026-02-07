import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';
import '../../theme/app_color_palette.dart';
import '../../theme/app_palettes.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colors = context.colors;
    final colorScheme = Theme.of(context).colorScheme;
    final currentThemeVariant = ref.watch(themeVariantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacingLg),
        children: [
          _buildThemeSelector(context, ref, currentThemeVariant, tokens, colors),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeVariant currentVariant,
    AppThemeTokens tokens,
    AppColorPalette colors,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: tokens.spacingSm),
                Text(
                  'Theme',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spacingMd),
            Wrap(
              spacing: tokens.spacingSm,
              runSpacing: tokens.spacingSm,
              children: ThemeVariant.values.map((variant) {
                final isSelected = variant == currentVariant;
                final previewColors = AppPalettes.getPreviewColors(variant);
                final bgColor = previewColors[0];
                final primaryColor = previewColors[1];

                return GestureDetector(
                  onTap: () {
                    ref.read(themeVariantProvider.notifier).setThemeVariant(variant);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colors.primary : colors.border,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: _getCheckColor(primaryColor),
                                    size: 14,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(height: tokens.spacingXs),
                      SizedBox(
                        width: 56,
                        child: Text(
                          variant.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? colors.primary : colors.textMuted,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCheckColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF1A1C1E) : Colors.white;
  }
}
