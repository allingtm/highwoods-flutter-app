import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../models/dashboard/dashboard_models.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_color_palette.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Multi-series spline area chart showing community activity over time.
class ActivityTimeline extends ConsumerWidget {
  const ActivityTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colors = context.colors;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDays = ref.watch(activityTimelineDaysProvider);
    final timelineAsync = ref.watch(activityTimelineProvider);

    return AppCard(
      margin: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Community Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _DayToggle(
                selectedDays: selectedDays,
                onChanged: (days) {
                  ref.read(activityTimelineDaysProvider.notifier).state = days;
                },
              ),
            ],
          ),
          SizedBox(height: tokens.spacingLg),
          SizedBox(
            height: 200,
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Failed to load activity',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                ),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Text(
                      'No activity yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                    ),
                  );
                }

                return SfCartesianChart(
                  margin: EdgeInsets.zero,
                  plotAreaBorderWidth: 0,
                  primaryXAxis: DateTimeAxis(
                    intervalType: selectedDays <= 7
                        ? DateTimeIntervalType.days
                        : DateTimeIntervalType.auto,
                    labelStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    majorGridLines: const MajorGridLines(width: 0),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    isVisible: false,
                    majorGridLines: MajorGridLines(
                      dashArray: const <double>[4, 4],
                      color: colors.borderLight,
                    ),
                  ),
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    textStyle: Theme.of(context).textTheme.labelSmall,
                  ),
                  trackballBehavior: TrackballBehavior(
                    enable: true,
                    activationMode: ActivationMode.singleTap,
                    tooltipSettings: const InteractiveTooltip(
                      format: 'point.y',
                    ),
                  ),
                  series: <CartesianSeries>[
                    SplineAreaSeries<ActivityDay, DateTime>(
                      name: 'Posts',
                      dataSource: data,
                      xValueMapper: (d, _) => d.date,
                      yValueMapper: (d, _) => d.posts,
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      borderColor: colorScheme.primary,
                      borderWidth: 2,
                      splineType: SplineType.cardinal,
                      animationDuration: 600,
                    ),
                    SplineAreaSeries<ActivityDay, DateTime>(
                      name: 'Comments',
                      dataSource: data,
                      xValueMapper: (d, _) => d.date,
                      yValueMapper: (d, _) => d.comments,
                      color: colors.secondary.withValues(alpha: 0.15),
                      borderColor: colors.secondary,
                      borderWidth: 2,
                      splineType: SplineType.cardinal,
                      animationDuration: 600,
                    ),
                    SplineAreaSeries<ActivityDay, DateTime>(
                      name: 'Reactions',
                      dataSource: data,
                      xValueMapper: (d, _) => d.date,
                      yValueMapper: (d, _) => d.reactions,
                      color: colors.warning.withValues(alpha: 0.15),
                      borderColor: colors.warning,
                      borderWidth: 2,
                      splineType: SplineType.cardinal,
                      animationDuration: 600,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Day Toggle
// ============================================================

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.selectedDays,
    required this.onChanged,
  });

  final int selectedDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in const [7, 30, 90])
          Padding(
            padding: EdgeInsets.only(left: tokens.spacingXs),
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacingSm,
                  vertical: tokens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: selectedDays == option
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(tokens.radiusSm),
                ),
                child: Text(
                  '${option}d',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: selectedDays == option
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selectedDays == option
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
