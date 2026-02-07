import 'package:flutter/material.dart';
import '../../models/feed/feed_models.dart';
import '../../theme/app_color_palette.dart';
import '../../theme/app_theme.dart';

/// Sticky urgent alert banner displayed at the top of the feed
class UrgentBanner extends StatelessWidget {
  const UrgentBanner({
    super.key,
    required this.alerts,
    this.onTap,
    this.onDismiss,
  });

  final List<Post> alerts;
  final void Function(Post alert)? onTap;
  final void Function(Post alert)? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final tokens = context.tokens;
    final theme = Theme.of(context);
    final palette = context.colors;
    final alert = alerts.first;

    // Determine color based on priority
    final priority = alert.alertDetails?.priority;
    final Color backgroundColor;
    final Color foregroundColor;

    switch (priority) {
      case AlertPriority.critical:
        backgroundColor = theme.colorScheme.error;
        foregroundColor = theme.colorScheme.onError;
        break;
      case AlertPriority.high:
        backgroundColor = theme.colorScheme.errorContainer;
        foregroundColor = theme.colorScheme.onErrorContainer;
        break;
      case AlertPriority.medium:
        backgroundColor = palette.warningLight;
        foregroundColor = palette.warningDark;
        break;
      case AlertPriority.low:
      case null:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        foregroundColor = theme.colorScheme.onSurface;
        break;
    }

    return Material(
      color: backgroundColor,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: onTap != null ? () => onTap!(alert) : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacingLg,
              vertical: tokens.spacingMd,
            ),
            child: Row(
              children: [
                Icon(
                  _getAlertIcon(priority),
                  color: foregroundColor,
                  size: tokens.iconSm,
                ),
                SizedBox(width: tokens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        alert.title ?? alert.content ?? 'Alert',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (alert.title != null && alert.content != null && alert.content!.isNotEmpty)
                        Text(
                          alert.contentPreview,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: foregroundColor.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (alerts.length > 1) ...[
                  SizedBox(width: tokens.spacingSm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacingSm,
                      vertical: tokens.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: foregroundColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(tokens.radiusSm),
                    ),
                    child: Text(
                      '+${alerts.length - 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (onDismiss != null) ...[
                  SizedBox(width: tokens.spacingSm),
                  IconButton(
                    icon: Icon(Icons.close, color: foregroundColor),
                    iconSize: tokens.iconSm,
                    onPressed: () => onDismiss!(alert),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAlertIcon(AlertPriority? priority) {
    switch (priority) {
      case AlertPriority.critical:
        return Icons.warning_rounded;
      case AlertPriority.high:
        return Icons.error_outline_rounded;
      case AlertPriority.medium:
        return Icons.info_outline_rounded;
      case AlertPriority.low:
      case null:
        return Icons.notifications_outlined;
    }
  }
}
