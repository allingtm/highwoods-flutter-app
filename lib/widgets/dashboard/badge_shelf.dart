import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard/dashboard_models.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_color_palette.dart';
import '../../theme/app_theme.dart';

/// Horizontal scrollable row of earned and unearned badges.
class BadgeShelf extends ConsumerWidget {
  const BadgeShelf({super.key, required this.earnedBadges});

  final List<UserBadge> earnedBadges;

  static const _allBadgeTypes = [
    'first_post',
    'helper',
    'marketplace_maven',
    'event_organiser',
    'safety_watcher',
    'streak_regular',
    'streak_dedicated',
    'streak_legend',
    'booster',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colors = context.colors;
    final earnedSet = earnedBadges.map((b) => b.badgeType).toSet();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Badges',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showBadgeHelp(context, ref, earnedSet),
                icon: Icon(
                  Icons.help_outline,
                  size: 20,
                  color: colors.textMuted,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacingSm),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _allBadgeTypes.length,
              separatorBuilder: (_, __) => SizedBox(width: tokens.spacingMd),
              itemBuilder: (context, index) {
                final type = _allBadgeTypes[index];
                final earned = earnedSet.contains(type);
                return _BadgeItem(
                  badgeType: type,
                  earned: earned,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgeHelp(
    BuildContext context,
    WidgetRef ref,
    Set<String> earnedSet,
  ) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final progressAsync = ref.read(badgeProgressProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusXl),
        ),
      ),
      builder: (sheetContext) {
        final sheetColors = sheetContext.colors;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (sheetContext, scrollController) {
            final progress = progressAsync.valueOrNull;

            return Column(
              children: [
                SizedBox(height: tokens.spacingSm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: tokens.spacingLg),
                Text(
                  'How to Earn Badges',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: tokens.spacingLg),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacingLg,
                    ),
                    itemCount: _allBadgeTypes.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: sheetColors.borderLight,
                    ),
                    itemBuilder: (sheetContext, index) {
                      final type = _allBadgeTypes[index];
                      final earned = earnedSet.contains(type);
                      final data = _badgeDisplayData(type);
                      final description = _badgeDescriptions[type] ?? '';
                      final progressText = progress?.progressFor(type);
                      final iconColor = data.iconColor(sheetColors);
                      final bgColor = data.bgColor(sheetColors);

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: tokens.spacingMd,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: earned
                                    ? bgColor
                                    : sheetColors.surfaceVariant,
                              ),
                              child: Icon(
                                data.icon,
                                size: 22,
                                color: earned
                                    ? iconColor
                                    : sheetColors.textDisabled,
                              ),
                            ),
                            SizedBox(width: tokens.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.label,
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  SizedBox(height: tokens.spacingXs),
                                  Text(
                                    description,
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: sheetColors.textSecondary,
                                        ),
                                  ),
                                  if (progressText != null &&
                                      progressText.isNotEmpty) ...[
                                    SizedBox(height: tokens.spacingXs),
                                    Text(
                                      progressText,
                                      style: Theme.of(sheetContext)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: earned
                                                ? iconColor
                                                : sheetColors.textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (earned)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: tokens.spacingSm,
                                  vertical: tokens.spacingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(
                                    tokens.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  'Earned',
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: iconColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static const _badgeDescriptions = {
    'first_post': 'Create your first post.',
    'helper': 'Create 5 help requests or offers.',
    'marketplace_maven': 'List 10 items on the marketplace.',
    'event_organiser': 'Organise 3 community events.',
    'safety_watcher': 'Report 3 safety alerts.',
    'streak_regular': 'Maintain a 7-day activity streak.',
    'streak_dedicated': 'Maintain a 30-day activity streak.',
    'streak_legend': 'Maintain a 100-day activity streak.',
    'booster': 'Give 50 reactions to neighbours\' posts.',
  };

  // Each badge maps to a semantic color role from the theme palette.
  // Colors resolve at build time via context.colors, so they adapt
  // to all 7 theme variants automatically.
  static _BadgeDisplayData _badgeDisplayData(String type) {
    switch (type) {
      case 'first_post':
        return const _BadgeDisplayData(Icons.edit_note, 'First Post', _BadgeColorRole.success);
      case 'helper':
        return const _BadgeDisplayData(Icons.volunteer_activism, 'Helper', _BadgeColorRole.primary);
      case 'marketplace_maven':
        return const _BadgeDisplayData(Icons.storefront, 'Maven', _BadgeColorRole.warning);
      case 'event_organiser':
        return const _BadgeDisplayData(Icons.event, 'Organiser', _BadgeColorRole.secondary);
      case 'safety_watcher':
        return const _BadgeDisplayData(Icons.shield, 'Watcher', _BadgeColorRole.error);
      case 'streak_regular':
        return const _BadgeDisplayData(Icons.local_fire_department, 'Regular', _BadgeColorRole.warning);
      case 'streak_dedicated':
        return const _BadgeDisplayData(Icons.local_fire_department, 'Dedicated', _BadgeColorRole.primary);
      case 'streak_legend':
        return const _BadgeDisplayData(Icons.local_fire_department, 'Legend', _BadgeColorRole.error);
      case 'booster':
        return const _BadgeDisplayData(Icons.favorite, 'Booster', _BadgeColorRole.secondary);
      default:
        return const _BadgeDisplayData(Icons.star, 'Badge', _BadgeColorRole.primary);
    }
  }
}

// ============================================================
// Badge Color Role
// ============================================================

enum _BadgeColorRole { primary, secondary, success, error, warning }

// ============================================================
// Badge Display Data
// ============================================================

class _BadgeDisplayData {
  final IconData icon;
  final String label;
  final _BadgeColorRole colorRole;

  const _BadgeDisplayData(this.icon, this.label, this.colorRole);

  /// Foreground icon color — uses the dark variant for contrast.
  Color iconColor(AppColorPalette colors) {
    switch (colorRole) {
      case _BadgeColorRole.primary:
        return colors.primaryDark;
      case _BadgeColorRole.secondary:
        return colors.secondaryDark;
      case _BadgeColorRole.success:
        return colors.successDark;
      case _BadgeColorRole.error:
        return colors.errorDark;
      case _BadgeColorRole.warning:
        return colors.warningDark;
    }
  }

  /// Background tint color — uses the light variant for soft fill.
  Color bgColor(AppColorPalette colors) {
    switch (colorRole) {
      case _BadgeColorRole.primary:
        return colors.primaryLight;
      case _BadgeColorRole.secondary:
        return colors.secondaryLight;
      case _BadgeColorRole.success:
        return colors.successLight;
      case _BadgeColorRole.error:
        return colors.errorLight;
      case _BadgeColorRole.warning:
        return colors.warningLight;
    }
  }
}

// ============================================================
// Badge Item
// ============================================================

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.badgeType,
    required this.earned,
  });

  final String badgeType;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = context.colors;
    final data = BadgeShelf._badgeDisplayData(badgeType);
    final iconColor = data.iconColor(colors);
    final bgColor = data.bgColor(colors);

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned ? bgColor : colors.surfaceVariant,
              boxShadow: earned
                  ? [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              data.icon,
              size: 24,
              color: earned ? iconColor : colors.textDisabled,
            ),
          ),
          SizedBox(height: tokens.spacingXs),
          Text(
            data.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: earned ? colors.textPrimary : colors.textDisabled,
                  fontWeight: earned ? FontWeight.w600 : FontWeight.w400,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
