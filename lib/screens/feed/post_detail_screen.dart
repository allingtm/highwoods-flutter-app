import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/feed/feed_models.dart';
import '../../providers/feed_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feed/feed_widgets.dart';

/// Full post detail screen with comments
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmitting = false;
  PostComment? _replyingToComment;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    // Primary: Get post from shared cache (single source of truth)
    final cachedPost = ref.watch(cachedPostProvider(widget.postId));

    // Fallback: Fetch from DB if not in cache (e.g., deep link)
    final detailAsync = ref.watch(postDetailProvider(widget.postId));

    // Use cached version if available, otherwise use detail provider
    final postAsync = cachedPost != null
        ? AsyncValue.data(cachedPost)
        : detailAsync;

    // When detail loads from DB, cache it for future use
    ref.listen(postDetailProvider(widget.postId), (prev, next) {
      next.whenData((post) {
        if (post != null) {
          ref.read(postCacheProvider.notifier).cachePost(post);
        }
      });
    });

    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showPostOptions(context),
          ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: tokens.iconXl,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: tokens.spacingLg),
                  Text(
                    'Post not found',
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: tokens.spacingXl),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(postDetailProvider(widget.postId));
                      ref.invalidate(postCommentsProvider(widget.postId));
                    },
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(tokens.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post content
                        _PostContent(
                          post: post,
                          onAuthorTap: () => context.push('/user/${post.userId}'),
                        ),

                        SizedBox(height: tokens.spacingXl),

                        // Actions row
                        PostActionsRow(
                          post: post,
                          onReactionTap: () => showReactionPicker(context: context, ref: ref, post: post),
                          onCommentTap: () => _commentFocusNode.requestFocus(),
                          onSaveTap: () => handleSavePost(context: context, ref: ref, post: post),
                          showMessageButton: shouldShowMessageButton(
                            post: post,
                            currentUserId: currentUser?.id,
                          ),
                          onMessageTap: () => handleMessageAuthor(context: context, ref: ref, post: post),
                        ),

                        Divider(height: tokens.spacing2xl),

                        // Comments section
                        Text(
                          'Comments',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: tokens.spacingMd),

                        commentsAsync.when(
                          data: (comments) {
                            return ThreadedCommentList(
                              comments: comments,
                              currentUserId: currentUser?.id,
                              isAuthenticated: isAuthenticated,
                              onReplyTap: _handleReply,
                              onDeleteTap: _handleDeleteComment,
                              onAuthorTap: (comment) => context.push('/user/${comment.userId}'),
                            );
                          },
                          loading: () => Padding(
                            padding: EdgeInsets.symmetric(vertical: tokens.spacingXl),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, _) => Padding(
                            padding: EdgeInsets.symmetric(vertical: tokens.spacingXl),
                            child: Center(
                              child: Text(
                                'Failed to load comments',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: tokens.spacing4xl),
                      ],
                    ),
                  ),
                ),
              ),
              ),

              // Comment input
              if (isAuthenticated)
                _CommentInput(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  isSubmitting: _isSubmitting,
                  replyingTo: _replyingToComment,
                  onSubmit: () => _submitComment(post),
                  onCancelReply: _cancelReply,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: tokens.iconXl,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: tokens.spacingLg),
              Text(
                'Failed to load post',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: tokens.spacingXl),
              FilledButton.icon(
                onPressed: () => ref.invalidate(postDetailProvider(widget.postId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleReply(PostComment comment) {
    setState(() {
      _replyingToComment = comment;
    });
    _commentController.text = '@${comment.authorName ?? 'user'} ';
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
    _commentController.clear();
  }

  void _handleDeleteComment(PostComment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(feedActionsProvider.notifier).deleteComment(
                commentId: comment.id,
                postId: widget.postId,
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment(Post post) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(feedActionsProvider.notifier).addComment(
        postId: post.id,
        content: content,
        parentId: _replyingToComment?.id,
      );
      _commentController.clear();
      _commentFocusNode.unfocus();
      setState(() => _replyingToComment = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showPostOptions(BuildContext context) {
    final theme = Theme.of(context);
    final postAsync = ref.read(postDetailProvider(widget.postId));
    final currentUser = ref.read(currentUserProvider);

    postAsync.whenData((post) {
      if (post == null) return;

      final isOwner = currentUser?.id == post.userId;

      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit post'),
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push('/post/${post.id}/edit');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  title: Text('Delete post', style: TextStyle(color: theme.colorScheme.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePost(post);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Report post'),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog(post);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  void _confirmDeletePost(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(feedActionsProvider.notifier).deletePost(post.id);
              if (mounted) {
                this.context.pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(Post post) {
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(
        onSubmit: (reason, details) async {
          await ref.read(feedActionsProvider.notifier).reportPost(
            postId: post.id,
            reason: reason,
            details: details,
          );
          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(content: Text('Report submitted. Thank you!')),
            );
          }
        },
      ),
    );
  }
}

/// Post content widget
class _PostContent extends StatelessWidget {
  const _PostContent({
    required this.post,
    this.onAuthorTap,
  });

  final Post post;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author header
        Row(
          children: [
            GestureDetector(
              onTap: onAuthorTap,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: post.authorAvatarUrl != null
                    ? NetworkImage(post.authorAvatarUrl!)
                    : null,
                child: post.authorAvatarUrl == null
                    ? Text(
                        _getInitials(post.authorUsername),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(width: tokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onAuthorTap,
                    child: Row(
                      children: [
                        Text(
                          post.authorUsername != null
                              ? '@${post.authorUsername}'
                              : 'Anonymous',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (post.authorIsVerified) ...[
                          SizedBox(width: tokens.spacingXs),
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${post.timeAgo} • ${post.postType.displayName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: tokens.spacingLg),

        // Title (only show if present)
        if (post.title != null && post.title!.isNotEmpty) ...[
          Text(
            post.title!,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // Images
        if (post.hasImages) ...[
          SizedBox(height: tokens.spacingMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                post.primaryImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Content
        if (post.content != null && post.content!.isNotEmpty) ...[
          SizedBox(height: tokens.spacingMd),
          Text(
            post.content!,
            style: theme.textTheme.bodyLarge,
          ),
        ],

        // Category-specific details
        if (post.eventDetails != null) ...[
          SizedBox(height: tokens.spacingLg),
          _EventDetailsCard(details: post.eventDetails!),
        ],
        if (post.marketplaceDetails != null) ...[
          SizedBox(height: tokens.spacingLg),
          _MarketplaceDetailsCard(details: post.marketplaceDetails!),
        ],
        if (post.lostFoundDetails != null) ...[
          SizedBox(height: tokens.spacingLg),
          _LostFoundDetailsCard(details: post.lostFoundDetails!),
        ],
        if (post.jobDetails != null) ...[
          SizedBox(height: tokens.spacingLg),
          _JobDetailsCard(details: post.jobDetails!),
        ],
        if (post.recommendationDetails != null) ...[
          SizedBox(height: tokens.spacingLg),
          _RecommendationDetailsCard(details: post.recommendationDetails!),
        ],
        if (post.alertDetails != null) ...[
          SizedBox(height: tokens.spacingLg),
          _AlertDetailsCard(details: post.alertDetails!),
        ],
      ],
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
}

/// Comment input widget
class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.onSubmit,
    this.replyingTo,
    this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final PostComment? replyingTo;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Replying to indicator
            if (replyingTo != null)
              Container(
                padding: EdgeInsets.only(
                  left: tokens.spacingMd,
                  right: tokens.spacingXs,
                  top: tokens.spacingXs,
                  bottom: tokens.spacingSm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: tokens.spacingXs),
                    Expanded(
                      child: Text(
                        'Replying to ${replyingTo!.authorName ?? 'user'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onCancelReply,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: replyingTo != null
                          ? 'Write a reply...'
                          : 'Write a comment...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusXl),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tokens.spacingLg,
                        vertical: tokens.spacingMd,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
                SizedBox(width: tokens.spacingSm),
                IconButton.filled(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Report dialog
class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.onSubmit});

  final void Function(String reason, String? details) onSubmit;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _selectedReason;
  final _detailsController = TextEditingController();

  static const _reasons = [
    'Spam or misleading',
    'Harassment or hate speech',
    'Violence or dangerous content',
    'Adult content',
    'False information',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AlertDialog(
      title: const Text('Report Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this post?'),
            SizedBox(height: tokens.spacingMd),
            ...List.generate(_reasons.length, (index) {
              final reason = _reasons[index];
              return ListTile(
                title: Text(reason),
                leading: Radio<String>(
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) => setState(() => _selectedReason = value),
                ),
                onTap: () => setState(() => _selectedReason = reason),
                contentPadding: EdgeInsets.zero,
              );
            }),
            SizedBox(height: tokens.spacingMd),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Additional details (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onSubmit(
                    _selectedReason!,
                    _detailsController.text.isNotEmpty
                        ? _detailsController.text
                        : null,
                  );
                },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

/// Event details card widget
class _EventDetailsCard extends StatelessWidget {
  const _EventDetailsCard({required this.details});

  final EventDetails details;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spacingMd),
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatDate(details.eventDate),
          ),
          if (details.timeDisplay.isNotEmpty) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: details.timeDisplay,
            ),
          ],
          if (details.venueName != null) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'Venue',
              value: details.venueName!,
            ),
          ],
          if (details.address != null) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.map_rounded,
              label: 'Address',
              value: details.address!,
            ),
          ],
          SizedBox(height: tokens.spacingSm),
          _DetailRow(
            icon: Icons.people_rounded,
            label: 'Attendees',
            value: details.attendeesDisplay,
          ),
          if (details.rsvpRequired) ...[
            SizedBox(height: tokens.spacingSm),
            Row(
              children: [
                Icon(
                  details.isFull
                      ? Icons.event_busy_rounded
                      : details.isRsvpOpen
                          ? Icons.event_available_rounded
                          : Icons.event_rounded,
                  size: 18,
                  color: details.isFull
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                SizedBox(width: tokens.spacingSm),
                Text(
                  details.isFull
                      ? 'Event Full'
                      : details.isRsvpOpen
                          ? 'RSVP Open'
                          : 'RSVP Closed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: details.isFull
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Marketplace details card widget
class _MarketplaceDetailsCard extends StatelessWidget {
  const _MarketplaceDetailsCard({required this.details});

  final MarketplaceDetails details;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spacingMd),
          _DetailRow(
            icon: Icons.sell_rounded,
            label: 'Price',
            value: details.priceDisplay,
            valueColor: Colors.green.shade700,
          ),
          if (details.conditionDisplay.isNotEmpty) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.star_rounded,
              label: 'Condition',
              value: details.conditionDisplay,
            ),
          ],
          SizedBox(height: tokens.spacingMd),
          Wrap(
            spacing: tokens.spacingSm,
            runSpacing: tokens.spacingSm,
            children: [
              if (details.pickupAvailable)
                _Chip(
                  icon: Icons.store_rounded,
                  label: 'Pickup available',
                ),
              if (details.deliveryAvailable)
                _Chip(
                  icon: Icons.local_shipping_rounded,
                  label: 'Delivery available',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lost & found details card widget
class _LostFoundDetailsCard extends StatelessWidget {
  const _LostFoundDetailsCard({required this.details});

  final LostFoundDetails details;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  details.isPet ? 'Pet Details' : 'Item Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (details.rewardOffered)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spacingSm,
                    vertical: tokens.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(tokens.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 14,
                        color: Colors.amber.shade800,
                      ),
                      SizedBox(width: tokens.spacingXs),
                      Text(
                        details.rewardDisplay,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.spacingMd),
          if (details.isPet) ...[
            if (details.petName != null)
              _DetailRow(
                icon: Icons.pets_rounded,
                label: 'Name',
                value: details.petName!,
              ),
            if (details.petDescription.isNotEmpty) ...[
              SizedBox(height: tokens.spacingSm),
              _DetailRow(
                icon: Icons.description_rounded,
                label: 'Description',
                value: details.petDescription,
              ),
            ],
          ] else if (details.itemDescription != null) ...[
            _DetailRow(
              icon: Icons.inventory_2_rounded,
              label: 'Item',
              value: details.itemDescription!,
            ),
          ],
          if (details.dateLostFound != null) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: _formatDate(details.dateLostFound!),
            ),
          ],
          if (details.lastSeenLocation != null) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'Last seen',
              value: details.lastSeenLocation!,
            ),
          ],
          if (details.contactPhone != null) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.phone_rounded,
              label: 'Contact',
              value: details.contactPhone!,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Job details card widget
class _JobDetailsCard extends StatelessWidget {
  const _JobDetailsCard({required this.details});

  final JobDetails details;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spacingMd),
          _DetailRow(
            icon: Icons.work_rounded,
            label: 'Type',
            value: details.jobTypeDisplay,
          ),
          SizedBox(height: tokens.spacingSm),
          _DetailRow(
            icon: Icons.payments_rounded,
            label: 'Pay',
            value: details.payDisplay,
            valueColor: Colors.green.shade700,
          ),
          SizedBox(height: tokens.spacingSm),
          _DetailRow(
            icon: Icons.trending_up_rounded,
            label: 'Experience',
            value: details.experienceLevel.displayName,
          ),
          if (details.hoursPerWeek != null) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: 'Hours',
              value: '${details.hoursPerWeek} hrs/week',
            ),
          ],
          if (details.skillsRequired != null && details.skillsRequired!.isNotEmpty) ...[
            SizedBox(height: tokens.spacingMd),
            Text(
              'Skills required',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spacingXs),
            Wrap(
              spacing: tokens.spacingXs,
              runSpacing: tokens.spacingXs,
              children: details.skillsRequired!
                  .map((skill) => _Chip(label: skill))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Recommendation details card widget
class _RecommendationDetailsCard extends StatelessWidget {
  const _RecommendationDetailsCard({required this.details});

  final RecommendationDetails details;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendation',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spacingMd),
          if (details.businessName != null)
            _DetailRow(
              icon: Icons.business_rounded,
              label: 'Business',
              value: details.businessName!,
            ),
          if (details.businessCategory != null) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.category_rounded,
              label: 'Category',
              value: details.businessCategory!,
            ),
          ],
          if (details.ratingDisplay.isNotEmpty) ...[
            SizedBox(height: tokens.spacingSm),
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Colors.amber.shade700,
                ),
                SizedBox(width: tokens.spacingSm),
                Text(
                  details.ratingDisplay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.amber.shade700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
          if (details.priceRangeDisplay.isNotEmpty) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.payments_rounded,
              label: 'Price range',
              value: details.priceRangeDisplay,
            ),
          ],
          if (details.location != null) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: details.location!,
            ),
          ],
          if (details.contactInfo != null) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.phone_rounded,
              label: 'Contact',
              value: details.contactInfo!,
            ),
          ],
          if (details.website != null) ...[
            SizedBox(height: tokens.spacingSm),
            _DetailRow(
              icon: Icons.language_rounded,
              label: 'Website',
              value: details.website!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Alert details card widget
class _AlertDetailsCard extends StatelessWidget {
  const _AlertDetailsCard({required this.details});

  final AlertDetails details;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    Color priorityColor;
    switch (details.priority) {
      case AlertPriority.low:
        priorityColor = Colors.blue;
      case AlertPriority.medium:
        priorityColor = Colors.orange;
      case AlertPriority.high:
        priorityColor = Colors.deepOrange;
      case AlertPriority.critical:
        priorityColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                size: 20,
                color: priorityColor,
              ),
              SizedBox(width: tokens.spacingSm),
              Expanded(
                child: Text(
                  'Alert Information',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacingSm,
                  vertical: tokens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(tokens.radiusSm),
                ),
                child: Text(
                  details.priority.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: priorityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacingMd),
          if (details.isVerified) ...[
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: tokens.spacingSm),
                Text(
                  'Verified by management',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (details.isStickyActive) ...[
            SizedBox(height: tokens.spacingSm),
            Row(
              children: [
                Icon(
                  Icons.push_pin_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: tokens.spacingSm),
                Text(
                  'Pinned to top of feed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable detail row widget
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: tokens.spacingSm),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable chip widget
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingSm,
        vertical: tokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            SizedBox(width: tokens.spacingXs),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
