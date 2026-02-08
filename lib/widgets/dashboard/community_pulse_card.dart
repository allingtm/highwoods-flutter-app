import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../models/dashboard/dashboard_models.dart';
import '../../theme/app_color_palette.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Community pulse card showing active users, post trends, and sparkline.
class CommunityPulseCard extends StatelessWidget {
  const CommunityPulseCard({super.key, required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return AppCard(
      margin: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: text stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active today indicator
                    Row(
                      children: [
                        _PulsingDot(color: colors.success),
                        SizedBox(width: tokens.spacingSm),
                        Text(
                          '${stats.activeUsersToday} active today',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.success,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.spacingSm),
                    Text(
                      '${stats.totalPostsWeek} posts this week',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: tokens.spacingXs),
                    _TrendIndicator(
                      change: stats.weekOverWeekChange,
                      successColor: colors.success,
                      errorColor: colors.error,
                      mutedColor: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacingMd),
          // 7-day activity sparkline
          SizedBox(
            height: 60,
            child: _ActivitySparkline(
              data: stats.postsByDay,
              lineColor: colorScheme.primary,
              fillColor: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Pulsing Dot
// ============================================================

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.4 + (_controller.value * 0.6);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// ============================================================
// Trend Indicator
// ============================================================

class _TrendIndicator extends StatelessWidget {
  final double change;
  final Color successColor;
  final Color errorColor;
  final Color mutedColor;

  const _TrendIndicator({
    required this.change,
    required this.successColor,
    required this.errorColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    if (change == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_flat, size: 16, color: mutedColor),
          const SizedBox(width: 4),
          Text(
            'Same as last week',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: mutedColor,
                ),
          ),
        ],
      );
    }

    final isUp = change > 0;
    final color = isUp ? successColor : errorColor;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;
    final sign = isUp ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$sign${change.round()}% vs last week',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ============================================================
// Activity Sparkline (Syncfusion Spline Area)
// ============================================================

class _ActivitySparkline extends StatelessWidget {
  final List<DayCount> data;
  final Color lineColor;
  final Color fillColor;

  const _ActivitySparkline({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      primaryXAxis: const CategoryAxis(isVisible: false),
      primaryYAxis: const NumericAxis(isVisible: false),
      series: <SplineAreaSeries<DayCount, String>>[
        SplineAreaSeries<DayCount, String>(
          dataSource: data,
          xValueMapper: (d, _) => d.dayLabel,
          yValueMapper: (d, _) => d.count,
          color: fillColor,
          borderColor: lineColor,
          borderWidth: 2,
          splineType: SplineType.cardinal,
          animationDuration: 600,
        ),
      ],
    );
  }
}
