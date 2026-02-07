import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_category.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/community_pulse_card.dart';
import '../widgets/dashboard/dashboard_check_in.dart';
import '../widgets/dashboard/personal_stats_card.dart';
import '../widgets/dashboard/stat_grid.dart';

/// Community dashboard screen with check-in, pulse, stats, and personal data.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.onMenuTap, this.onCategoryTap});

  final VoidCallback? onMenuTap;
  final void Function(PostCategory category)? onCategoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    final dashboardStats = ref.watch(dashboardStatsProvider);
    final userStats = ref.watch(userDashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: onMenuTap != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuTap,
                tooltip: 'Open menu',
              )
            : null,
        title: const Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(userDashboardStatsProvider);
        },
        child: dashboardStats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            message: 'Failed to load dashboard',
            onRetry: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(userDashboardStatsProvider);
            },
          ),
          data: (stats) => CustomScrollView(
            slivers: [
              // Check-in card
              SliverToBoxAdapter(
                child: userStats.when(
                  data: (uStats) => DashboardCheckIn(
                    currentMood: uStats.todaysMood,
                    moodToday: stats.moodToday,
                  ),
                  loading: () => DashboardCheckIn(
                    currentMood: null,
                    moodToday: stats.moodToday,
                  ),
                  error: (_, __) => DashboardCheckIn(
                    currentMood: null,
                    moodToday: stats.moodToday,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingMd)),

              // Community pulse
              SliverToBoxAdapter(
                child: CommunityPulseCard(stats: stats),
              ),
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingXl)),

              // Section header: What's Happening
              SliverToBoxAdapter(
                child: _SectionHeader(title: "What's Happening"),
              ),
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingMd)),

              // Stat grid
              SliverToBoxAdapter(
                child: StatGrid(stats: stats, onCategoryTap: onCategoryTap),
              ),
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingXl)),

              // Section header: Your Dashboard
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Your Dashboard'),
              ),
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingMd)),

              // Personal stats
              SliverToBoxAdapter(
                child: userStats.when(
                  data: (uStats) => PersonalStatsCard(userStats: uStats),
                  loading: () => Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Bottom padding for nav bar
              SliverToBoxAdapter(
                child: SizedBox(
                  height: tokens.spacing4xl +
                      tokens.spacingXl +
                      MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Section Header
// ============================================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ============================================================
// Error View
// ============================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: tokens.iconXl,
              color: colorScheme.error,
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: tokens.spacingXl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
