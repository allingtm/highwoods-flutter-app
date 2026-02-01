import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/post_category.dart';
import '../../models/feed/feed_models.dart';
import '../../providers/feed_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feed/feed_widgets.dart';

/// Main feed screen displaying community posts
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, this.onMenuTap});

  /// Callback to open the side menu drawer
  final VoidCallback? onMenuTap;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  int _newPostsCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more posts when near the bottom
      final notifier = ref.read(feedPostsNotifierProvider.notifier);
      if (notifier.hasMore && !notifier.isLoadingMore) {
        notifier.loadMore();
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() {
      _newPostsCount = 0;
    });
  }

  void _onCategorySelected(PostCategory? category) {
    ref.read(selectedCategoryProvider.notifier).state = category;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final postsAsync = ref.watch(feedPostsNotifierProvider);
    final alertsAsync = ref.watch(activeAlertsProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(feedPostsNotifierProvider.notifier).refresh();
          ref.invalidate(activeAlertsProvider);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              snap: true,
              leading: widget.onMenuTap != null
                  ? IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: widget.onMenuTap,
                      tooltip: 'Open menu',
                    )
                  : null,
              title: const Text('Community'),
              actions: [
                if (isAuthenticated)
                  IconButton(
                    icon: const Icon(Icons.bookmark_outline_rounded),
                    onPressed: () => context.push('/saved'),
                    tooltip: 'Saved posts',
                  ),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => context.push('/search'),
                  tooltip: 'Search',
                ),
              ],
            ),

            // Urgent alerts banner
            alertsAsync.when(
              data: (alerts) {
                if (alerts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: UrgentBanner(
                    alerts: alerts,
                    onTap: (alert) => context.push('/post/${alert.id}'),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Filter pills
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spacingMd),
                child: FilterPills(
                  selectedCategory: selectedCategory,
                  onCategorySelected: _onCategorySelected,
                ),
              ),
            ),

            // Posts list
            postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(
                      category: selectedCategory,
                      onCreatePost: isAuthenticated
                          ? () => context.push(
                              '/create-post${selectedCategory != null ? '?category=${selectedCategory.dbValue}' : ''}')
                          : null,
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= posts.length) {
                        // Loading indicator at the bottom
                        return Padding(
                          padding: EdgeInsets.all(tokens.spacingXl),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final post = posts[index];
                      return PostCard(
                        post: post,
                        onTap: () => context.push('/post/${post.id}'),
                        onReactionTap: () => _handleReaction(post),
                        onCommentTap: () => context.push('/post/${post.id}#comments'),
                        onSaveTap: () => _handleSave(post),
                        onAuthorTap: () => context.push('/user/${post.userId}'),
                      );
                    },
                    childCount: posts.length + (ref.read(feedPostsNotifierProvider.notifier).hasMore ? 1 : 0),
                  ),
                );
              },
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SkeletonPostCard(hasImage: index % 2 == 0),
                  childCount: 3,
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorState(
                  error: error.toString(),
                  onRetry: () => ref.read(feedPostsNotifierProvider.notifier).refresh(),
                ),
              ),
            ),

            // Bottom padding
            SliverToBoxAdapter(
              child: SizedBox(height: tokens.spacing4xl),
            ),
          ],
        ),
      ),

      // New posts indicator (uses _scrollToTop when real-time updates are enabled)
      floatingActionButton: _newPostsCount > 0
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _scrollToTop,
              icon: const Icon(Icons.arrow_upward_rounded),
              label: Text('$_newPostsCount new'),
            )
          : (isAuthenticated
              ? FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: () => context.push(
                      '/create-post${selectedCategory != null ? '?category=${selectedCategory.dbValue}' : ''}'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Post'),
                )
              : null),
    );
  }

  void _handleReaction(Post post) {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      _showLoginPrompt();
      return;
    }

    // Show reaction picker
    showModalBottomSheet(
      context: context,
      builder: (context) => _ReactionPickerSheet(
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

  void _handleSave(Post post) {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      _showLoginPrompt();
      return;
    }

    ref.read(feedActionsProvider.notifier).toggleSave(post);
  }

  void _showLoginPrompt() {
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
}

/// Empty state when no posts are found
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.category,
    this.onCreatePost,
  });

  final PostCategory? category;
  final VoidCallback? onCreatePost;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category?.icon ?? Icons.forum_outlined,
              size: tokens.iconXl,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              category != null
                  ? 'No ${category!.displayName.toLowerCase()} posts yet'
                  : 'No posts yet',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              'Be the first to share something with the community!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onCreatePost != null) ...[
              SizedBox(height: tokens.spacingXl),
              FilledButton.icon(
                onPressed: onCreatePost,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Post'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with retry button
class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingXl),
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
              'Something went wrong',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: tokens.spacingXl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for selecting reactions
class _ReactionPickerSheet extends StatelessWidget {
  const _ReactionPickerSheet({
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
                _ReactionButton(
                  type: 'like',
                  icon: Icons.thumb_up_rounded,
                  label: 'Like',
                  color: Colors.blue,
                  isSelected: currentReaction == 'like',
                  onTap: () => onReactionSelected('like'),
                ),
                _ReactionButton(
                  type: 'love',
                  icon: Icons.favorite_rounded,
                  label: 'Love',
                  color: Colors.red,
                  isSelected: currentReaction == 'love',
                  onTap: () => onReactionSelected('love'),
                ),
                _ReactionButton(
                  type: 'helpful',
                  icon: Icons.lightbulb_rounded,
                  label: 'Helpful',
                  color: Colors.amber,
                  isSelected: currentReaction == 'helpful',
                  onTap: () => onReactionSelected('helpful'),
                ),
                _ReactionButton(
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

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
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
