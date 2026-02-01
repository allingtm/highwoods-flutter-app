import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/feed_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/feed/filter_pills.dart';

/// Search screen for finding posts
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Debounce search to avoid too many requests
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _focusNode.requestFocus();
  }

  void _handleReaction(dynamic post) {
    // Navigate to post detail for reaction
    context.push('/post/${post.id}');
  }

  void _handleSave(dynamic post) async {
    try {
      await ref.read(feedActionsProvider.notifier).toggleSave(post);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save post'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(searchCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search posts...',
            border: InputBorder.none,
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.hintText,
            ),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          style: AppTypography.bodyLarge,
          textInputAction: TextInputAction.search,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category filter
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacingLg,
              vertical: tokens.spacingSm,
            ),
            child: FilterPills(
              selectedCategory: selectedCategory,
              onCategorySelected: (category) {
                ref.read(searchCategoryProvider.notifier).state = category;
              },
            ),
          ),
          const Divider(height: 1),

          // Results
          Expanded(
            child: _buildResults(searchResults, query, tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    AsyncValue<List<dynamic>> searchResults,
    String query,
    dynamic tokens,
  ) {
    // Empty state - no query
    if (query.isEmpty) {
      return _EmptyState(
        icon: Icons.search,
        title: 'Search Posts',
        subtitle: 'Find posts by title, description, or keywords',
      );
    }

    // Query too short
    if (query.length < 2) {
      return _EmptyState(
        icon: Icons.keyboard,
        title: 'Keep typing...',
        subtitle: 'Enter at least 2 characters to search',
      );
    }

    return searchResults.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => _EmptyState(
        icon: Icons.error_outline,
        title: 'Search failed',
        subtitle: 'Please try again',
        action: TextButton(
          onPressed: () => ref.invalidate(searchResultsProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptyState(
            icon: Icons.search_off,
            title: 'No results found',
            subtitle: 'Try different keywords or remove filters',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: tokens.spacingSm),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostCard(
              post: post,
              onTap: () => context.push('/post/${post.id}'),
              onReactionTap: () => _handleReaction(post),
              onCommentTap: () => context.push('/post/${post.id}'),
              onSaveTap: () => _handleSave(post),
            );
          },
        );
      },
    );
  }
}

/// Empty state widget for search
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.hintText,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
