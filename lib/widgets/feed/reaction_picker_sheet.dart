import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet widget for selecting reactions on posts
class ReactionPickerSheet extends StatelessWidget {
  const ReactionPickerSheet({
    super.key,
    required this.currentReaction,
    required this.onReactionSelected,
  });

  final String? currentReaction;
  final void Function(String) onReactionSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'React to this post',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spacingXl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ReactionButton(
                  type: 'like',
                  icon: Icons.thumb_up_rounded,
                  label: 'Like',
                  color: Colors.blue,
                  isSelected: currentReaction == 'like',
                  onTap: () => onReactionSelected('like'),
                ),
                ReactionButton(
                  type: 'love',
                  icon: Icons.favorite_rounded,
                  label: 'Love',
                  color: Colors.red,
                  isSelected: currentReaction == 'love',
                  onTap: () => onReactionSelected('love'),
                ),
                ReactionButton(
                  type: 'helpful',
                  icon: Icons.lightbulb_rounded,
                  label: 'Helpful',
                  color: Colors.amber,
                  isSelected: currentReaction == 'helpful',
                  onTap: () => onReactionSelected('helpful'),
                ),
                ReactionButton(
                  type: 'thanks',
                  icon: Icons.volunteer_activism_rounded,
                  label: 'Thanks',
                  color: Colors.purple,
                  isSelected: currentReaction == 'thanks',
                  onTap: () => onReactionSelected('thanks'),
                ),
              ],
            ),
            SizedBox(height: tokens.spacingLg),
          ],
        ),
      ),
    );
  }
}

/// Individual reaction button within the picker
class ReactionButton extends StatelessWidget {
  const ReactionButton({
    super.key,
    required this.type,
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String type;
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Container(
        padding: EdgeInsets.all(tokens.spacingMd),
        decoration: isSelected
            ? BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(tokens.radiusLg),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            SizedBox(height: tokens.spacingXs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
