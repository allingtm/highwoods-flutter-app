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
      body: Padding(
        padding: EdgeInsets.all(tokens.spacingLg),
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
            SizedBox(height: tokens.spacingXs),
            Text(
              'Choose a theme for the app',
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: tokens.spacingLg),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: tokens.spacingMd,
                  mainAxisSpacing: tokens.spacingMd,
                  childAspectRatio: 0.78,
                ),
                itemCount: ThemeVariant.values.length,
                itemBuilder: (context, index) {
                  final variant = ThemeVariant.values[index];
                  final palette = AppPalettes.getPalette(variant);
                  final isSelected = variant == currentThemeVariant;
                  return _ThemePreviewCard(
                    variant: variant,
                    palette: palette,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(themeVariantProvider.notifier)
                          .setThemeVariant(variant);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.variant,
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeVariant variant;
  final AppColorPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final currentColors = context.colors;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${variant.displayName} theme${isSelected ? ", selected" : ""}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            border: Border.all(
              color: isSelected ? currentColors.primary : currentColors.border,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: currentColors.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMiniMockup(),
              ),
              _buildLabelBar(context, tokens, currentColors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMockup() {
    return Container(
      color: palette.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mini app bar
          Container(
            height: 28,
            color: palette.surface,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.menu, size: 12, color: palette.textPrimary),
                const SizedBox(width: 6),
                Text(
                  'Highwoods',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.notifications_none,
                  size: 12,
                  color: palette.primary,
                ),
              ],
            ),
          ),
          // Divider
          Container(height: 0.5, color: palette.border),
          // Body area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.borderLight, width: 0.5),
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + name row
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: palette.primaryLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 40,
                          height: 6,
                          decoration: BoxDecoration(
                            color: palette.textPrimary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Text placeholder lines
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: palette.textSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FractionallySizedBox(
                      widthFactor: 0.7,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: palette.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Action row: button + secondary accent
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Button',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                              color: palette.brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: palette.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelBar(
    BuildContext context,
    AppThemeTokens tokens,
    AppColorPalette currentColors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? currentColors.primary.withValues(alpha: 0.08)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            getThemeVariantIcon(variant),
            size: 14,
            color:
                isSelected ? currentColors.primary : currentColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              variant.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? currentColors.primary
                    : currentColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              size: 16,
              color: currentColors.primary,
            ),
        ],
      ),
    );
  }
}
