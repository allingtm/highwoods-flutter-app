import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/post_category.dart';
import '../../providers/feed_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feed/feed_widgets.dart';

/// Main feed screen displaying community posts
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, this.onMenuTap, this.onScrollVisibilityChanged});

  /// Callback to open the side menu drawer
  final VoidCallback? onMenuTap;

  /// Callback when scroll direction changes (true = show controls, false = hide)
  final ValueChanged<bool>? onScrollVisibilityChanged;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  int _newPostsCount = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = ref.read(feedRealtimeProvider);
      manager.addListener(_onNewPostsChanged);
    });
  }

  @override
  void dispose() {
    ref.read(feedRealtimeProvider).removeListener(_onNewPostsChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onNewPostsChanged() {
    if (!mounted) return;
    setState(() {
      _newPostsCount = ref.read(feedRealtimeProvider).newPostsCount;
    });
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

    // Always show controls when at the top
    if (_scrollController.offset <= 0) {
      if (!_showControls) {
        setState(() => _showControls = true);
        widget.onScrollVisibilityChanged?.call(true);
      }
      return;
    }

    // Hide on scroll down, show on scroll up
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _showControls) {
      setState(() => _showControls = false);
      widget.onScrollVisibilityChanged?.call(false);
    } else if (direction == ScrollDirection.forward && !_showControls) {
      setState(() => _showControls = true);
      widget.onScrollVisibilityChanged?.call(true);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    ref.read(feedRealtimeProvider).resetNewPostsCount();
    ref.read(feedPostsNotifierProvider.notifier).refresh();
  }

  Widget _buildAnimatedFab(Widget fab) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 64;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        offset: _showControls ? Offset.zero : const Offset(1, 0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showControls ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !_showControls,
            child: fab,
          ),
        ),
      ),
    );
  }

  void _onCategorySelected(PostCategory? category) {
    ref.read(selectedCategoryProvider.notifier).state = category;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final feedSort = ref.watch(feedSortProvider);
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
              title: const Text('Highwoods'),
              actions: [
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

            // Sort toggle + Filter pills
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spacingMd),
                child: Column(
                  children: [
                    FilterPills(
                      selectedCategory: selectedCategory,
                      onCategorySelected: _onCategorySelected,
                    ),
                    SizedBox(height: tokens.spacingSm),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
                      child: _SortToggle(
                        sort: feedSort,
                        onChanged: (sort) => ref.read(feedSortProvider.notifier).setSort(sort),
                        isAuthenticated: isAuthenticated,
                      ),
                    ),
                  ],
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
                      isFollowingMode: feedSort == FeedSort.following,
                      isSavedMode: feedSort == FeedSort.saved,
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
                        onReactionTap: () => showReactionPicker(context: context, ref: ref, post: post),
                        onCommentTap: () => context.push('/post/${post.id}#comments'),
                        onSaveTap: () => handleSavePost(context: context, ref: ref, post: post),
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
          ? _buildAnimatedFab(FloatingActionButton.extended(
              heroTag: null,
              onPressed: _scrollToTop,
              icon: const Icon(Icons.arrow_upward_rounded),
              label: Text('$_newPostsCount new'),
            ))
          : (isAuthenticated
              ? _buildAnimatedFab(FloatingActionButton(
                  heroTag: null,
                  shape: const CircleBorder(),
                  onPressed: () => context.push(
                      '/create-post${selectedCategory != null ? '?category=${selectedCategory.dbValue}' : ''}'),
                  child: const Icon(Icons.add_rounded, size: 32),
                ))
              : null),
    );
  }
}

/// Empty state when no posts are found
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.category,
    this.onCreatePost,
    this.isFollowingMode = false,
    this.isSavedMode = false,
  });

  final PostCategory? category;
  final VoidCallback? onCreatePost;
  final bool isFollowingMode;
  final bool isSavedMode;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final String title;
    final String subtitle;
    final IconData icon;

    if (isSavedMode) {
      icon = Icons.bookmark_outline_rounded;
      title = 'No saved posts yet';
      subtitle = 'Bookmark posts to see them here.';
    } else if (isFollowingMode) {
      icon = Icons.people_outline_rounded;
      title = 'No posts from people you follow';
      subtitle = 'Follow people to see their posts here.';
    } else if (category != null) {
      icon = category!.icon;
      title = 'No ${category!.displayName.toLowerCase()} posts yet';
      subtitle = 'Be the first to share something with the community!';
    } else {
      icon = Icons.forum_outlined;
      title = 'No posts yet';
      subtitle = 'Be the first to share something with the community!';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: tokens.iconXl,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onCreatePost != null && !isFollowingMode && !isSavedMode) ...[
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

/// Sort toggle between New, Active, Following, and Saved
class _SortToggle extends StatelessWidget {
  const _SortToggle({
    required this.sort,
    required this.onChanged,
    this.isAuthenticated = false,
  });

  final FeedSort sort;
  final ValueChanged<FeedSort> onChanged;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SortChip(
            label: 'New',
            icon: Icons.schedule_rounded,
            isSelected: sort == FeedSort.newest,
            onTap: () => onChanged(FeedSort.newest),
          ),
          SizedBox(width: tokens.spacingSm),
          _SortChip(
            label: 'Active',
            icon: Icons.local_fire_department_rounded,
            isSelected: sort == FeedSort.active,
            onTap: () => onChanged(FeedSort.active),
          ),
          SizedBox(width: tokens.spacingSm),
          _SortChip(
            label: 'Following',
            icon: Icons.people_rounded,
            isSelected: sort == FeedSort.following,
            onTap: () => onChanged(FeedSort.following),
          ),
          if (isAuthenticated) ...[
            SizedBox(width: tokens.spacingSm),
            _SortChip(
              label: 'Saved',
              icon: Icons.bookmark_outline_rounded,
              isSelected: sort == FeedSort.saved,
              onTap: () => onChanged(FeedSort.saved),
            ),
          ],
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(tokens.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusXl),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingMd,
            vertical: tokens.spacingXs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radiusXl),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                : Border.all(color: theme.colorScheme.outlineVariant, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: tokens.spacingXs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
