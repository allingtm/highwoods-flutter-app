import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../models/dashboard/dashboard_models.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Grouped column chart comparing category activity: this week vs last week.
class TrendingChart extends StatelessWidget {
  const TrendingChart({super.key, required this.data});

  final List<CategoryBreakdown> data;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    // Filter to categories with any activity
    final active = data.where((d) => d.currentCount > 0 || d.previousCount > 0).toList();

    if (active.isEmpty) return const SizedBox.shrink();

    return AppCard(
      margin: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending This Week',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: tokens.spacingLg),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                labelStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
              ),
              primaryYAxis: const NumericAxis(
                isVisible: false,
                majorGridLines: MajorGridLines(width: 0),
              ),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: Theme.of(context).textTheme.labelSmall,
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries>[
                ColumnSeries<CategoryBreakdown, String>(
                  name: 'This week',
                  dataSource: active,
                  xValueMapper: (d, _) => d.displayName,
                  yValueMapper: (d, _) => d.currentCount,
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(tokens.radiusSm),
                  ),
                  width: 0.4,
                  spacing: 0.15,
                  animationDuration: 800,
                ),
                ColumnSeries<CategoryBreakdown, String>(
                  name: 'Last week',
                  dataSource: active,
                  xValueMapper: (d, _) => d.displayName,
                  yValueMapper: (d, _) => d.previousCount,
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(tokens.radiusSm),
                  ),
                  width: 0.4,
                  spacing: 0.15,
                  animationDuration: 800,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
