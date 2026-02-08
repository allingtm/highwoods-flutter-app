import 'package:flutter/material.dart';

import '../../models/dashboard/dashboard_models.dart';
import '../../theme/app_color_palette.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Card displaying the latest AI-generated community insight.
class AiInsightsCard extends StatelessWidget {
  const AiInsightsCard({super.key, required this.insight});

  final AiInsight insight;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = context.colors;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      margin: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: tokens.iconSm,
                color: colorScheme.primary,
              ),
              SizedBox(width: tokens.spacingSm),
              Text(
                'AI Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (insight.title != null) ...[
            SizedBox(height: tokens.spacingMd),
            Text(
              '${insight.emoji ?? ''} ${insight.title!}'.trim(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          SizedBox(height: tokens.spacingMd),
          Text(
            insight.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  height: 1.5,
                ),
          ),
          SizedBox(height: tokens.spacingSm),
          Text(
            _timeAgo(insight.generatedAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }
}
