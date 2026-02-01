import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/post_category.dart';
import '../../models/feed/feed_models.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feed/feed_widgets.dart';

/// Screen displaying the user's saved posts with search, filtering,
/// and category organization
class SavedPostsScreen extends ConsumerStatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  ConsumerState<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends ConsumerState<SavedPostsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _searchQuery = '';
  PostCategory? _selectedCategory;
  bool _isGroupedView = true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Filter posts based on search query and selected category
  List<Post> _filterPosts(List<Post> posts) {
    var filtered = posts;

    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final titleMatch = p.title?.toLowerCase().contains(query) ?? false;
        final contentMatch = p.content?.toLowerCase().contains(query) ?? false;
        return titleMatch || contentMatch;
      }).toList();
    }

    return filtered;
  }

  /// Group posts by category, sorted by category order
  Map<PostCategory, List<Post>> _groupPostsByCategory(List<Post> posts) {
    final grouped = <PostCategory, List<Post>>{};
    for (final post in posts) {
      grouped.putIfAbsent(post.category, () => []).add(post);
    }
    // Sort by PostCategory enum order
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.index.compareTo(b.key.index)),
    );
  }

  void _handleUnsave(Post post) {
    ref.read(feedActionsProvider.notifier).toggleSave(post);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post removed from saved'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(feedActionsProvider.notifier).toggleSave(post);
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleShare(Post post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final savedPostsAsync = ref.watch(savedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Posts'),
        actions: [
          IconButton(
            icon: Icon(
              _isGroupedView ? Icons.view_list_rounded : Icons.view_module_rounded,
            ),
            tooltip: _isGroupedView ? 'Show flat list' : 'Show grouped by category',
            onPressed: () {
              setState(() {
                _isGroupedView = !_isGroupedView;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savedPostsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacingLg,
                  vertical: tokens.spacingSm,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search saved posts...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusXl),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: tokens.spacingMd,
                      vertical: tokens.spacingSm,
                    ),
                  ),
                ),
              ),
            ),

            // Filter pills
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spacingSm),
                child: FilterPills(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
              ),
            ),

            // Content
            savedPostsAsync.when(
              data: (posts) => _buildContent(posts),
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SkeletonPostCard(hasImage: index % 2 == 0),
                  childCount: 3,
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorState(
                  error: error.toString(),
                  onRetry: () => ref.invalidate(savedPostsProvider),
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
    );
  }

  Widget _buildContent(List<Post> allPosts) {
    final filteredPosts = _filterPosts(allPosts);
    final hasFilters = _searchQuery.isNotEmpty || _selectedCategory != null;

    if (filteredPosts.isEmpty) {
      return SliverFillRemaining(
        child: _EmptyState(hasFilters: hasFilters),
      );
    }

    // Use flat view when a specific category is selected
    if (_isGroupedView && _selectedCategory == null && _searchQuery.isEmpty) {
      return _buildGroupedView(filteredPosts);
    } else {
      return _buildFlatView(filteredPosts);
    }
  }

  Widget _buildGroupedView(List<Post> posts) {
    final grouped = _groupPostsByCategory(posts);

    // Build a flat list of headers and posts
    final items = <Widget>[];
    for (final entry in grouped.entries) {
      items.add(_buildCategorySectionHeader(entry.key, entry.value.length));
      for (final post in entry.value) {
        items.add(_buildPostCard(post));
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => items[index],
        childCount: items.length,
      ),
    );
  }

  Widget _buildFlatView(List<Post> posts) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildPostCard(posts[index]),
        childCount: posts.length,
      ),
    );
  }

  Widget _buildCategorySectionHeader(PostCategory category, int count) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spacingLg,
        tokens.spacingXl,
        tokens.spacingLg,
        tokens.spacingSm,
      ),
      child: Row(
        children: [
          Icon(
            category.icon,
            size: 20,
            color: category.color,
          ),
          SizedBox(width: tokens.spacingSm),
          Text(
            category.displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: category.color,
            ),
          ),
          SizedBox(width: tokens.spacingSm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacingSm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(tokens.radiusSm),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: category.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return PostCard(
      post: post,
      onTap: () => context.push('/post/${post.id}'),
      onReactionTap: () => context.push('/post/${post.id}'),
      onCommentTap: () => context.push('/post/${post.id}'),
      onSaveTap: () => _handleUnsave(post),
      onShareTap: () => _handleShare(post),
      onAuthorTap: () => context.push('/user/${post.userId}'),
    );
  }
}

/// Empty state when no saved posts are found
class _EmptyState extends StatelessWidget {
  const _EmptyState({this.hasFilters = false});

  final bool hasFilters;

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
              hasFilters ? Icons.search_off_rounded : Icons.bookmark_border_rounded,
              size: tokens.iconXl,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              hasFilters ? 'No saved posts match your filters' : 'No saved posts yet',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              hasFilters
                  ? 'Try adjusting your search or category filter'
                  : 'Posts you save will appear here for easy access',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFilters) ...[
              SizedBox(height: tokens.spacingXl),
              FilledButton.icon(
                onPressed: () => context.push('/feed'),
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Browse Posts'),
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
              'Failed to load saved posts',
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
