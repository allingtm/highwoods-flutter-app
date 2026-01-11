import 'package:flutter/material.dart';
import '../../models/feed/post_comment.dart';
import '../../theme/app_theme.dart';

/// Single comment item widget
class CommentItem extends StatelessWidget {
  const CommentItem({
    super.key,
    required this.comment,
    required this.isOwner,
    this.onReplyTap,
    this.onDeleteTap,
    this.onAuthorTap,
  });

  final PostComment comment;
  final bool isOwner;
  final VoidCallback? onReplyTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: comment.isReply ? tokens.spacing2xl : 0,
        bottom: tokens.spacingMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: onAuthorTap,
            child: CircleAvatar(
              radius: comment.isReply ? 14 : 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: comment.authorAvatarUrl != null
                  ? NetworkImage(comment.authorAvatarUrl!)
                  : null,
              child: comment.authorAvatarUrl == null
                  ? Text(
                      _getInitials(comment.authorName),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: comment.isReply ? 10 : 12,
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(width: tokens.spacingMd),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment bubble
                Container(
                  padding: EdgeInsets.all(tokens.spacingMd),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(tokens.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author name
                      GestureDetector(
                        onTap: onAuthorTap,
                        child: Text(
                          (comment.authorName?.isNotEmpty ?? false)
                              ? comment.authorName!
                              : 'Anonymous',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: tokens.spacingXs),
                      // Comment text
                      Text(
                        comment.content.trim(),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Actions row
                Padding(
                  padding: EdgeInsets.only(
                    left: tokens.spacingSm,
                    top: tokens.spacingXs,
                  ),
                  child: Row(
                    children: [
                      // Time ago
                      Text(
                        _timeAgo(comment.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (onReplyTap != null) ...[
                        SizedBox(width: tokens.spacingMd),
                        GestureDetector(
                          onTap: onReplyTap,
                          child: Text(
                            'Reply',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (isOwner && onDeleteTap != null) ...[
                        SizedBox(width: tokens.spacingMd),
                        GestureDetector(
                          onTap: onDeleteTap,
                          child: Text(
                            'Delete',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 365) {
      final years = diff.inDays ~/ 365;
      return '${years}y';
    } else if (diff.inDays > 30) {
      final months = diff.inDays ~/ 30;
      return '${months}mo';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}
