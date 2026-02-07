import 'package:flutter/material.dart';

import '../../models/dashboard/dashboard_models.dart';
import '../../models/post_category.dart';
import '../../theme/app_color_palette.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Grid of stat cards showing community activity counts.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.stats, this.onCategoryTap});

  final DashboardStats stats;
  final void Function(PostCategory category)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = context.colors;
    final colorScheme = Theme.of(context).colorScheme;

    final cards = <_StatCardData>[
      if (stats.activeAlerts > 0 || stats.highPriorityAlerts > 0)
        _StatCardData(
          icon: Icons.warning_amber_rounded,
          count: stats.activeAlerts,
          subtitle: stats.highPriorityAlerts > 0
              ? '${stats.highPriorityAlerts} high priority'
              : 'Active alerts',
          accentColor: colors.error,
          category: PostCategory.safety,
        ),
      _StatCardData(
        icon: Icons.event,
        count: stats.eventsThisWeek,
        subtitle: stats.eventsAttendees > 0
            ? '${stats.eventsAttendees} attending'
            : 'Events this week',
        accentColor: colorScheme.primary,
        category: PostCategory.social,
      ),
      _StatCardData(
        icon: Icons.storefront_outlined,
        count: stats.marketplaceActive,
        subtitle: 'Marketplace listings',
        accentColor: colors.warning,
        category: PostCategory.marketplace,
      ),
      _StatCardData(
        icon: Icons.pets,
        count: stats.lostFoundActive,
        subtitle: stats.lostFoundResolved > 0
            ? '${stats.lostFoundResolved} resolved this week'
            : 'Lost & found',
        accentColor: colors.secondary,
        category: PostCategory.lostFound,
      ),
      _StatCardData(
        icon: Icons.work_outline,
        count: stats.jobsActive,
        subtitle: 'Jobs & services',
        accentColor: colors.success,
        category: PostCategory.jobs,
      ),
      if (stats.helpRequests > 0)
        _StatCardData(
          icon: Icons.volunteer_activism,
          count: stats.helpRequests,
          subtitle: 'Help needed',
          accentColor: colorScheme.tertiary,
          category: PostCategory.recommendations,
        ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      child: Wrap(
        spacing: tokens.spacingMd,
        runSpacing: tokens.spacingMd,
        children: cards.map((data) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - tokens.spacingLg * 2 - tokens.spacingMd) / 2,
            child: _StatCard(
              data: data,
              onTap: onCategoryTap != null
                  ? () => onCategoryTap!(data.category)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// Stat Card Data
// ============================================================

class _StatCardData {
  final IconData icon;
  final int count;
  final String subtitle;
  final Color accentColor;
  final PostCategory category;

  const _StatCardData({
    required this.icon,
    required this.count,
    required this.subtitle,
    required this.accentColor,
    required this.category,
  });
}

// ============================================================
// Stat Card Widget
// ============================================================

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  final VoidCallback? onTap;

  const _StatCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.icon,
            size: tokens.iconSm,
            color: data.accentColor,
          ),
          SizedBox(height: tokens.spacingMd),
          Text(
            '${data.count}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: tokens.spacingXs),
          Text(
            data.subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
