import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../models/dashboard/dashboard_models.dart';
import '../../theme/app_color_palette.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Card showing a neighbourhood goal with progress bar.
class NeighbourhoodGoalCard extends StatelessWidget {
  const NeighbourhoodGoalCard({super.key, required this.goal});

  final NeighbourhoodGoal goal;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = context.colors;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      margin: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _goalIcon(goal.goalType),
                size: 18,
                color: colorScheme.primary,
              ),
              SizedBox(width: tokens.spacingSm),
              Expanded(
                child: Text(
                  goal.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (goal.isComplete)
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: colors.success,
                ),
            ],
          ),
          if (goal.description != null) ...[
            SizedBox(height: tokens.spacingSm),
            Text(
              goal.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
          SizedBox(height: tokens.spacingLg),
          SizedBox(
            height: 40,
            child: SfLinearGauge(
              minimum: 0,
              maximum: goal.targetCount.toDouble(),
              showTicks: false,
              showLabels: false,
              axisTrackStyle: LinearAxisTrackStyle(
                thickness: 8,
                edgeStyle: LinearEdgeStyle.bothCurve,
                color: colors.surfaceVariant,
              ),
              barPointers: [
                LinearBarPointer(
                  value: goal.currentCount.toDouble(),
                  thickness: 8,
                  edgeStyle: LinearEdgeStyle.bothCurve,
                  color: goal.isComplete ? colors.success : colorScheme.primary,
                  animationDuration: 800,
                ),
              ],
              markerPointers: [
                LinearShapePointer(
                  value: goal.currentCount.toDouble(),
                  shapeType: LinearShapePointerType.circle,
                  color: goal.isComplete ? colors.success : colorScheme.primary,
                  width: 14,
                  height: 14,
                  elevation: 2,
                  elevationColor: colorScheme.shadow.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spacingXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _daysRemaining(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                    ),
              ),
              Text(
                '${goal.currentCount} / ${goal.targetCount}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _daysRemaining() {
    final remaining = goal.endsAt.difference(DateTime.now()).inDays;
    if (goal.isComplete) return 'Goal reached!';
    if (remaining <= 0) return 'Ends today';
    if (remaining == 1) return '1 day left';
    return '$remaining days left';
  }

  IconData _goalIcon(String type) {
    switch (type) {
      case 'posts':
        return Icons.edit_note;
      case 'events_attendance':
        return Icons.event;
      case 'marketplace_listings':
        return Icons.storefront;
      default:
        return Icons.flag;
    }
  }
}
