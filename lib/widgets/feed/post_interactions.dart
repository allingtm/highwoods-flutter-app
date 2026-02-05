import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/feed/feed_models.dart';
import '../../models/post_category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import 'reaction_picker_sheet.dart';

/// Shows the reaction picker bottom sheet for a post.
/// Checks authentication first - if not authenticated, shows login prompt.
void showReactionPicker({
  required BuildContext context,
  required WidgetRef ref,
  required Post post,
}) {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  if (!isAuthenticated) {
    showLoginPrompt(context);
    return;
  }

  showModalBottomSheet(
    context: context,
    builder: (context) => ReactionPickerSheet(
      postId: post.id,
      currentReaction: post.userReaction,
      onReactionSelected: (reactionType) {
        Navigator.pop(context);
        ref.read(feedActionsProvider.notifier).toggleReaction(
          postId: post.id,
          reactionType: reactionType,
        );
      },
    ),
  );
}

/// Shows a login prompt bottom sheet for unauthenticated users.
void showLoginPrompt(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.all(context.tokens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.login_rounded,
              size: context.tokens.iconLg,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: context.tokens.spacingLg),
            Text(
              'Sign in to interact',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: context.tokens.spacingSm),
            Text(
              'Create an account or sign in to like, comment, and save posts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.tokens.spacingXl),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/login');
              },
              child: const Text('Sign in'),
            ),
            SizedBox(height: context.tokens.spacingMd),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/register');
              },
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Handles save/bookmark toggle with authentication check.
void handleSavePost({
  required BuildContext context,
  required WidgetRef ref,
  required Post post,
}) {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  if (!isAuthenticated) {
    showLoginPrompt(context);
    return;
  }

  ref.read(feedActionsProvider.notifier).toggleSave(post);
}

/// Handles messaging the post author with authentication check.
void handleMessageAuthor({
  required BuildContext context,
  required WidgetRef ref,
  required Post post,
}) {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  if (!isAuthenticated) {
    showLoginPrompt(context);
    return;
  }
  context.push('/connections/conversation/${post.userId}');
}

/// Determines if the message button should be shown for a post.
/// Returns true for high-priority categories where private messaging adds value,
/// and only if the current user is not the post author.
bool shouldShowMessageButton({
  required Post post,
  required String? currentUserId,
}) {
  // Don't show for own posts
  if (currentUserId != null && post.userId == currentUserId) {
    return false;
  }

  // Show for high-priority categories where messaging is valuable
  const messagingCategories = {
    PostCategory.marketplace,
    PostCategory.jobs,
    PostCategory.lostFound,
    PostCategory.social,
    PostCategory.recommendations,
  };

  return messagingCategories.contains(post.category);
}
