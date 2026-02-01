import 'package:flutter/material.dart';
import '../../models/post_category.dart';
import '../../models/feed/feed_models.dart';
import '../../theme/app_theme.dart';
import 'post_actions_row.dart';

/// Base post card widget that renders appropriate variant based on post category
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onReactionTap,
    required this.onCommentTap,
    required this.onSaveTap,
    required this.onShareTap,
    this.onAuthorTap,
  });

  final Post post;
  final VoidCallback onTap;
  final VoidCallback onReactionTap;
  final VoidCallback onCommentTap;
  final VoidCallback onSaveTap;
  final VoidCallback onShareTap;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: tokens.spacingLg,
        vertical: tokens.spacingSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if present)
            if (post.primaryImageUrl != null)
              AspectRatio(
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

            Padding(
              padding: EdgeInsets.all(tokens.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Author info + category badge + time
                  _PostHeader(
                    post: post,
                    onAuthorTap: onAuthorTap,
                  ),
                  SizedBox(height: tokens.spacingMd),

                  // Title or content as main text
                  if (post.title != null && post.title!.isNotEmpty) ...[
                    Text(
                      post.title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Category-specific content
                    _buildCategoryContent(context),
                    // Content preview (if any)
                    if (post.content != null && post.content!.isNotEmpty) ...[
                      SizedBox(height: tokens.spacingSm),
                      Text(
                        post.contentPreview,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ] else if (post.content != null && post.content!.isNotEmpty) ...[
                    // No title - show content as main text
                    Text(
                      post.content!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Category-specific content
                    _buildCategoryContent(context),
                  ] else ...[
                    // Fallback - just show category content
                    _buildCategoryContent(context),
                  ],

                  SizedBox(height: tokens.spacingMd),

                  // Actions row
                  PostActionsRow(
                    post: post,
                    onReactionTap: onReactionTap,
                    onCommentTap: onCommentTap,
                    onSaveTap: onSaveTap,
                    onShareTap: onShareTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContent(BuildContext context) {
    switch (post.category) {
      case PostCategory.marketplace:
        return _MarketplaceContent(post: post);
      case PostCategory.social:
        if (post.eventDetails != null) {
          return _EventContent(post: post);
        }
        return const SizedBox.shrink();
      case PostCategory.safety:
        return _AlertContent(post: post);
      case PostCategory.lostFound:
        return _LostFoundContent(post: post);
      case PostCategory.jobs:
        return _JobContent(post: post);
      case PostCategory.recommendations:
        return _RecommendationContent(post: post);
    }
  }
}

/// Post header with author info, category badge, and time
class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    this.onAuthorTap,
  });

  final Post post;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Row(
      children: [
        // Author avatar
        GestureDetector(
          onTap: onAuthorTap,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: post.authorAvatarUrl != null
                ? NetworkImage(post.authorAvatarUrl!)
                : null,
            child: post.authorAvatarUrl == null
                ? Text(
                    _getInitials(post.authorUsername),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
        ),
        SizedBox(width: tokens.spacingMd),

        // Author name and time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: onAuthorTap,
                      child: Text(
                        post.authorUsername != null
                            ? '@${post.authorUsername}'
                            : 'Anonymous',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (post.authorIsVerified) ...[
                    SizedBox(width: tokens.spacingXs),
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
              Text(
                post.timeAgo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Category/Type badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingSm,
            vertical: tokens.spacingXs,
          ),
          decoration: BoxDecoration(
            color: post.category.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(tokens.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                post.category.icon,
                size: 12,
                color: post.category.color,
              ),
              SizedBox(width: tokens.spacingXs),
              Text(
                post.postType.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: post.category.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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

/// Marketplace-specific content (price, condition)
class _MarketplaceContent extends StatelessWidget {
  const _MarketplaceContent({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final details = post.marketplaceDetails;
    if (details == null) return const SizedBox.shrink();

    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(top: tokens.spacingSm),
      child: Row(
        children: [
          // Price
          Text(
            details.priceDisplay,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (details.conditionDisplay.isNotEmpty) ...[
            SizedBox(width: tokens.spacingMd),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacingSm,
                vertical: tokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radiusSm),
              ),
              child: Text(
                details.conditionDisplay,
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Event-specific content (date, time, venue, attendees)
class _EventContent extends StatelessWidget {
  const _EventContent({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final details = post.eventDetails;
    if (details == null) return const SizedBox.shrink();

    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(top: tokens.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and time row
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: tokens.spacingXs),
              Text(
                _formatDate(details.eventDate),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (details.timeDisplay.isNotEmpty) ...[
                SizedBox(width: tokens.spacingMd),
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: tokens.spacingXs),
                Text(
                  details.timeDisplay,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
          if (details.venueName != null) ...[
            SizedBox(height: tokens.spacingXs),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: tokens.spacingXs),
                Expanded(
                  child: Text(
                    details.venueName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: tokens.spacingXs),
          Text(
            details.attendeesDisplay,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Alert-specific content (priority badge, verified status)
class _AlertContent extends StatelessWidget {
  const _AlertContent({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final details = post.alertDetails;
    if (details == null) return const SizedBox.shrink();

    final tokens = context.tokens;
    final theme = Theme.of(context);

    final priorityColor = _getPriorityColor(details.priority, theme);

    return Padding(
      padding: EdgeInsets.only(top: tokens.spacingSm),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacingSm,
              vertical: tokens.spacingXs,
            ),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(tokens.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.priority_high_rounded,
                  size: 12,
                  color: priorityColor,
                ),
                SizedBox(width: tokens.spacingXs),
                Text(
                  details.priority.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: priorityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (details.isVerified) ...[
            SizedBox(width: tokens.spacingSm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacingSm,
                vertical: tokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(tokens.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 12,
                    color: Colors.green,
                  ),
                  SizedBox(width: tokens.spacingXs),
                  Text(
                    'Verified',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(AlertPriority priority, ThemeData theme) {
    switch (priority) {
      case AlertPriority.critical:
        return theme.colorScheme.error;
      case AlertPriority.high:
        return Colors.orange;
      case AlertPriority.medium:
        return Colors.amber;
      case AlertPriority.low:
        return theme.colorScheme.primary;
    }
  }
}

/// Lost & Found specific content (pet info, reward)
class _LostFoundContent extends StatelessWidget {
  const _LostFoundContent({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final details = post.lostFoundDetails;
    if (details == null) return const SizedBox.shrink();

    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(top: tokens.spacingSm),
      child: Wrap(
        spacing: tokens.spacingSm,
        runSpacing: tokens.spacingXs,
        children: [
          if (details.isPet && details.petDescription.isNotEmpty)
            _InfoChip(
              icon: Icons.pets_rounded,
              label: details.petDescription,
            ),
          if (details.dateLostFound != null)
            _InfoChip(
              icon: Icons.calendar_today_rounded,
              label: _formatDate(details.dateLostFound!),
            ),
          if (details.rewardDisplay.isNotEmpty)
            _InfoChip(
              icon: Icons.card_giftcard_rounded,
              label: details.rewardDisplay,
              color: Colors.green,
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }
}

/// Job-specific content (job type, salary, remote)
class _JobContent extends StatelessWidget {
  const _JobContent({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final details = post.jobDetails;
    if (details == null) return const SizedBox.shrink();

    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(top: tokens.spacingSm),
      child: Wrap(
        spacing: tokens.spacingSm,
        runSpacing: tokens.spacingXs,
        children: [
          _InfoChip(
            icon: Icons.work_outline_rounded,
            label: details.jobTypeDisplay,
          ),
          _InfoChip(
            icon: Icons.payments_outlined,
            label: details.payDisplay,
          ),
          if (details.experienceLevel != ExperienceLevel.any)
            _InfoChip(
              icon: Icons.trending_up_rounded,
              label: details.experienceLevel.displayName,
            ),
        ],
      ),
    );
  }
}

/// Recommendation-specific content (rating, price range)
class _RecommendationContent extends StatelessWidget {
  const _RecommendationContent({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final details = post.recommendationDetails;
    if (details == null) return const SizedBox.shrink();

    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(top: tokens.spacingSm),
      child: Wrap(
        spacing: tokens.spacingSm,
        runSpacing: tokens.spacingXs,
        children: [
          if (details.businessName != null)
            _InfoChip(
              icon: Icons.storefront_rounded,
              label: details.businessName!,
            ),
          if (details.rating != null)
            _InfoChip(
              icon: Icons.star_rounded,
              label: details.ratingDisplay,
              color: Colors.amber,
            ),
          if (details.priceRangeDisplay.isNotEmpty)
            _InfoChip(
              icon: Icons.payments_outlined,
              label: details.priceRangeDisplay,
            ),
        ],
      ),
    );
  }
}

/// Reusable info chip for displaying metadata
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingSm,
        vertical: tokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: effectiveColor),
          SizedBox(width: tokens.spacingXs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
