import 'package:flutter/material.dart';
import '../../models/feed/post_comment.dart';
import '../../theme/app_theme.dart';
import 'comment_item.dart';

/// Displays comments in a threaded/nested structure
/// Groups replies under their parent comments
class ThreadedCommentList extends StatelessWidget {
  const ThreadedCommentList({
    super.key,
    required this.comments,
    required this.currentUserId,
    required this.isAuthenticated,
    required this.onReplyTap,
    required this.onDeleteTap,
    required this.onAuthorTap,
  });

  final List<PostComment> comments;
  final String? currentUserId;
  final bool isAuthenticated;
  final void Function(PostComment comment) onReplyTap;
  final void Function(PostComment comment) onDeleteTap;
  final void Function(PostComment comment) onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    if (comments.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacingXl),
        child: Center(
          child: Text(
            'No comments yet. Be the first!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Group comments: top-level (parentId == null) and replies (parentId != null)
    final topLevelComments = comments.where((c) => c.parentId == null).toList();
    final repliesMap = <String, List<PostComment>>{};

    for (final comment in comments) {
      if (comment.parentId != null) {
        repliesMap.putIfAbsent(comment.parentId!, () => []);
        repliesMap[comment.parentId!]!.add(comment);
      }
    }

    // Sort replies by creation time
    for (final replies in repliesMap.values) {
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topLevelComments.map((comment) {
        final replies = repliesMap[comment.id] ?? [];

        return _CommentThread(
          comment: comment,
          replies: replies,
          currentUserId: currentUserId,
          isAuthenticated: isAuthenticated,
          onReplyTap: onReplyTap,
          onDeleteTap: onDeleteTap,
          onAuthorTap: onAuthorTap,
        );
      }).toList(),
    );
  }
}

/// A single comment thread with its replies
class _CommentThread extends StatefulWidget {
  const _CommentThread({
    required this.comment,
    required this.replies,
    required this.currentUserId,
    required this.isAuthenticated,
    required this.onReplyTap,
    required this.onDeleteTap,
    required this.onAuthorTap,
  });

  final PostComment comment;
  final List<PostComment> replies;
  final String? currentUserId;
  final bool isAuthenticated;
  final void Function(PostComment comment) onReplyTap;
  final void Function(PostComment comment) onDeleteTap;
  final void Function(PostComment comment) onAuthorTap;

  @override
  State<_CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<_CommentThread> {
  static const int _initialReplyCount = 2;
  bool _showAllReplies = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final visibleReplies = _showAllReplies
        ? widget.replies
        : widget.replies.take(_initialReplyCount).toList();
    final hiddenReplyCount = widget.replies.length - _initialReplyCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent comment
        CommentItem(
          comment: widget.comment,
          isOwner: widget.currentUserId == widget.comment.userId,
          onReplyTap: widget.isAuthenticated
              ? () => widget.onReplyTap(widget.comment)
              : null,
          onDeleteTap: widget.currentUserId == widget.comment.userId
              ? () => widget.onDeleteTap(widget.comment)
              : null,
          onAuthorTap: () => widget.onAuthorTap(widget.comment),
        ),

        // Replies
        if (widget.replies.isNotEmpty) ...[
          // Reply indicator line
          Padding(
            padding: EdgeInsets.only(left: tokens.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...visibleReplies.map((reply) => CommentItem(
                      comment: reply,
                      isOwner: widget.currentUserId == reply.userId,
                      onReplyTap: widget.isAuthenticated
                          ? () => widget.onReplyTap(widget.comment) // Reply to parent
                          : null,
                      onDeleteTap: widget.currentUserId == reply.userId
                          ? () => widget.onDeleteTap(reply)
                          : null,
                      onAuthorTap: () => widget.onAuthorTap(reply),
                    )),

                // "View more replies" button
                if (!_showAllReplies && hiddenReplyCount > 0)
                  Padding(
                    padding: EdgeInsets.only(
                      left: tokens.spacing2xl,
                      bottom: tokens.spacingMd,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _showAllReplies = true),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: tokens.spacingXs),
                          Text(
                            'View $hiddenReplyCount more ${hiddenReplyCount == 1 ? 'reply' : 'replies'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
