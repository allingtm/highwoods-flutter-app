import 'package:flutter/material.dart';
import '../../models/feed/feed_models.dart';
import '../../theme/app_theme.dart';

/// Action buttons row for post cards (reactions, comments, save)
class PostActionsRow extends StatelessWidget {
  const PostActionsRow({
    super.key,
    required this.post,
    required this.onReactionTap,
    required this.onCommentTap,
    required this.onSaveTap,
    required this.onShareTap,
    this.compact = false,
  });

  final Post post;
  final VoidCallback onReactionTap;
  final VoidCallback onCommentTap;
  final VoidCallback onSaveTap;
  final VoidCallback onShareTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Row(
      children: [
        // Reaction button
        _ActionButton(
          icon: post.hasUserReacted
              ? _getReactionIcon(post.userReaction)
              : Icons.thumb_up_outlined,
          label: post.reactionCount > 0 ? '${post.reactionCount}' : null,
          isActive: post.hasUserReacted,
          activeColor: _getReactionColor(post.userReaction, theme),
          onTap: onReactionTap,
          compact: compact,
        ),
        SizedBox(width: tokens.spacingMd),
        // Comment button
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: post.commentCount > 0 ? '${post.commentCount}' : null,
          onTap: onCommentTap,
          compact: compact,
        ),
        const Spacer(),
        // Save button
        _ActionButton(
          icon: post.isSaved
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          isActive: post.isSaved,
          activeColor: theme.colorScheme.primary,
          onTap: onSaveTap,
          compact: compact,
        ),
        SizedBox(width: tokens.spacingSm),
        // Share button
        _ActionButton(
          icon: Icons.share_outlined,
          onTap: onShareTap,
          compact: compact,
        ),
      ],
    );
  }

  IconData _getReactionIcon(String? reactionType) {
    switch (reactionType) {
      case 'love':
        return Icons.favorite_rounded;
      case 'helpful':
        return Icons.lightbulb_rounded;
      case 'thanks':
        return Icons.volunteer_activism_rounded;
      case 'like':
      default:
        return Icons.thumb_up_rounded;
    }
  }

  Color _getReactionColor(String? reactionType, ThemeData theme) {
    switch (reactionType) {
      case 'love':
        return Colors.red;
      case 'helpful':
        return Colors.amber;
      case 'thanks':
        return Colors.purple;
      case 'like':
      default:
        return theme.colorScheme.primary;
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.label,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String? label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final color = isActive
        ? (activeColor ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacingSm,
          vertical: tokens.spacingXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 18 : 20,
              color: color,
            ),
            if (label != null) ...[
              SizedBox(width: tokens.spacingXs),
              Text(
                label!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reaction picker popup
class ReactionPicker extends StatelessWidget {
  const ReactionPicker({
    super.key,
    required this.currentReaction,
    required this.onReactionSelected,
  });

  final String? currentReaction;
  final void Function(String reactionType) onReactionSelected;

  static const reactions = [
    ('like', Icons.thumb_up_rounded, 'Like', Colors.blue),
    ('love', Icons.favorite_rounded, 'Love', Colors.red),
    ('helpful', Icons.lightbulb_rounded, 'Helpful', Colors.amber),
    ('thanks', Icons.volunteer_activism_rounded, 'Thanks', Colors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(tokens.spacingSm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((reaction) {
          final (type, icon, label, color) = reaction;
          final isSelected = currentReaction == type;

          return Tooltip(
            message: label,
            child: InkWell(
              onTap: () => onReactionSelected(type),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Container(
                padding: EdgeInsets.all(tokens.spacingSm),
                decoration: isSelected
                    ? BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(tokens.radiusMd),
                      )
                    : null,
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
