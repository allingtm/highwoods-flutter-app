import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Floating pill indicator showing new posts are available
class NewPostsPill extends StatelessWidget {
  const NewPostsPill({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Positioned(
      top: tokens.spacingLg,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(tokens.radiusXl),
          elevation: 4,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(tokens.radiusXl),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacingLg,
                vertical: tokens.spacingMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  SizedBox(width: tokens.spacingSm),
                  Text(
                    count == 1 ? '1 new post' : '$count new posts',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
