import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_category.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/activity_timeline.dart';
import '../widgets/dashboard/ai_insights_card.dart';
import '../widgets/dashboard/badge_shelf.dart';
import '../widgets/dashboard/community_pulse_card.dart';
import '../widgets/dashboard/neighbourhood_goal_card.dart';
import '../widgets/dashboard/personal_stats_card.dart';
import '../widgets/dashboard/personal_wrapped_card.dart';
import '../widgets/dashboard/stat_grid.dart';
import '../widgets/dashboard/trending_chart.dart';

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

    // Fire-and-forget: update streak + check badges on every dashboard load
    ref.watch(dailyActivityProvider);

    return Scaffold(
      appBar: AppBar(
        leading: onMenuTap != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuTap,
                tooltip: 'Open menu',
              )
            : null,
        title: const Text('Stats'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(userDashboardStatsProvider);
          ref.invalidate(categoryBreakdownProvider);
          ref.invalidate(activityTimelineProvider);
          ref.invalidate(latestInsightProvider);
          ref.invalidate(userBadgesProvider);
          ref.invalidate(personalWrappedProvider);
          ref.invalidate(activeGoalsProvider);
          ref.invalidate(dailyActivityProvider);
          ref.invalidate(badgeProgressProvider);
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
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingMd)),

              // Badge shelf
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    final badgesAsync = ref.watch(userBadgesProvider);
                    return badgesAsync.when(
                      data: (badges) => BadgeShelf(earnedBadges: badges),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
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

              // Section header: Trending
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'Trending'),
              ),
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingMd)),

              // Trending chart
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    final breakdownAsync = ref.watch(categoryBreakdownProvider);
                    return breakdownAsync.when(
                      data: (data) => TrendingChart(data: data),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingMd)),

              // Activity timeline
              const SliverToBoxAdapter(
                child: ActivityTimeline(),
              ),
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingMd)),

              // AI Insights
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    final insightAsync = ref.watch(latestInsightProvider);
                    return insightAsync.when(
                      data: (insight) => insight != null
                          ? Padding(
                              padding: EdgeInsets.only(bottom: tokens.spacingXl),
                              child: AiInsightsCard(insight: insight),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),

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
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingMd)),

              // Personal wrapped (monthly summary)
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    final wrappedAsync = ref.watch(personalWrappedProvider);
                    return wrappedAsync.when(
                      data: (wrapped) => PersonalWrappedCard(wrapped: wrapped),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: tokens.spacingXl)),

              // Neighbourhood goals
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    final goalsAsync = ref.watch(activeGoalsProvider);
                    return goalsAsync.when(
                      data: (goals) => goals.isEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              children: [
                                for (final goal in goals) ...[
                                  NeighbourhoodGoalCard(goal: goal),
                                  SizedBox(height: tokens.spacingMd),
                                ],
                              ],
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
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
