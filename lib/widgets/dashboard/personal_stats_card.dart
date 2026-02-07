import 'package:flutter/material.dart';

import '../../models/dashboard/dashboard_models.dart';
import '../../theme/app_color_palette.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Personal stats card showing user activity and streak.
class PersonalStatsCard extends StatelessWidget {
  const PersonalStatsCard({super.key, required this.userStats});

  final UserDashboardStats userStats;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AppCard(
      margin: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with streak badge
          Row(
            children: [
              Text(
                'Your Dashboard',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (userStats.streak != null && userStats.streak!.currentStreak > 0)
                _StreakBadge(streak: userStats.streak!),
            ],
          ),
          SizedBox(height: tokens.spacingLg),

          // 3 mini stat columns
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Posts',
                  value: userStats.postsThisWeek,
                  previousValue: userStats.postsLastWeek,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Comments',
                  value: userStats.commentsThisWeek,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Reactions',
                  value: userStats.reactionsReceivedWeek,
                ),
              ),
            ],
          ),

          SizedBox(height: tokens.spacingLg),

          // Warm streak message
          _StreakMessage(
            streak: userStats.streak,
            totalMissedYesterday: userStats.totalUsersMissedYesterday,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Streak Badge
// ============================================================

class _StreakBadge extends StatelessWidget {
  final UserStreak streak;

  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingSm,
        vertical: tokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 14,
            color: colors.warning,
          ),
          SizedBox(width: tokens.spacingXs),
          Text(
            '${streak.currentStreak} day${streak.currentStreak == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Mini Stat Column
// ============================================================

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final int? previousValue;

  const _MiniStat({
    required this.label,
    required this.value,
    this.previousValue,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = context.colors;

    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: tokens.spacingXs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        if (previousValue != null && previousValue! > 0) ...[
          SizedBox(height: tokens.spacingXs),
          _MiniTrend(current: value, previous: previousValue!),
        ],
      ],
    );
  }
}

class _MiniTrend extends StatelessWidget {
  final int current;
  final int previous;

  const _MiniTrend({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final diff = current - previous;
    if (diff == 0) return const SizedBox.shrink();

    final isUp = diff > 0;
    final color = isUp ? colors.success : colors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 10,
          color: color,
        ),
        Text(
          '${diff.abs()}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ============================================================
// Streak Message
// ============================================================

class _StreakMessage extends StatelessWidget {
  final UserStreak? streak;
  final int totalMissedYesterday;

  const _StreakMessage({
    required this.streak,
    required this.totalMissedYesterday,
  });

  String get _message {
    if (streak == null || streak!.currentStreak == 0) {
      if (totalMissedYesterday > 0) {
        return 'Welcome back! $totalMissedYesterday residents took yesterday off too.';
      }
      return 'Check in today to start your streak!';
    }

    final days = streak!.currentStreak;
    if (days == 1) return 'Day 1 — every streak starts here.';
    if (days < 7) return '$days days and counting. Consistency is key!';
    if (days < 30) return "$days day streak! You're a Highwoods regular now.";
    if (days < 100) return "$days days strong — that's real dedication!";
    return "$days day streak! You're a Highwoods legend.";
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Text(
      _message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
    );
  }
}
