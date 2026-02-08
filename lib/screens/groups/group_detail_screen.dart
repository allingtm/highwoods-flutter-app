import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/group/group.dart';
import '../../providers/feed_provider.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feed/feed_widgets.dart';
import '../../widgets/groups/group_join_button.dart';
import '../../widgets/groups/group_visibility_badge.dart';
import '../../widgets/groups/group_terms_sheet.dart';
import '../../widgets/groups/pinned_posts_banner.dart';

/// Group detail screen with header and group feed
class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isJoinLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Subscribe to group realtime updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final realtimeManager = ref.read(groupsRealtimeProvider);
      realtimeManager.subscribeToGroup(widget.groupId);
      realtimeManager.setOnCurrentUserRemoved((groupId) {
        if (groupId == widget.groupId && mounted) {
          _showRemovedDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    final realtimeManager = ref.read(groupsRealtimeProvider);
    realtimeManager.setOnCurrentUserRemoved(null);
    realtimeManager.unsubscribeFromGroup(widget.groupId);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showRemovedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Removed from group'),
        content: const Text(
            'You have been removed from this group by an admin.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home?tab=1');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(groupFeedProvider(widget.groupId).notifier);
      if (notifier.hasMore && !notifier.isLoadingMore) {
        notifier.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final feedAsync = ref.watch(groupFeedProvider(widget.groupId));

    return groupAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              SizedBox(height: tokens.spacingMd),
              Text('Failed to load group', style: textTheme.bodyLarge),
              SizedBox(height: tokens.spacingSm),
              FilledButton(
                onPressed: () => ref.invalidate(groupDetailProvider(widget.groupId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Group not found')),
          );
        }

        if (group.isArchived) {
          return Scaffold(
            appBar: AppBar(title: Text(group.name)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.archive_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This group has been archived',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This group is no longer active.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              if (group.canCurrentUserModerate)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'members',
                      child: ListTile(
                        leading: Icon(Icons.people, size: 20),
                        title: Text('Members'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (group.isRequestToJoin)
                      const PopupMenuItem(
                        value: 'requests',
                        child: ListTile(
                          leading: Icon(Icons.person_add, size: 20),
                          title: Text('Join Requests'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (group.canCurrentUserManageRoles)
                      const PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(Icons.settings, size: 20),
                          title: Text('Settings'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'members':
                        context.push('/group/${group.id}/members');
                      case 'requests':
                        context.push('/group/${group.id}/requests');
                      case 'settings':
                        context.push('/group/${group.id}/settings');
                    }
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.people_outline),
                  onPressed: () => context.push('/group/${group.id}/members'),
                  tooltip: 'Members',
                ),
            ],
          ),
          floatingActionButton: group.isMember
              ? FloatingActionButton(
                  onPressed: () => context.push('/create-post?groupId=${group.id}'),
                  tooltip: 'New Post',
                  child: const Icon(Icons.edit),
                )
              : null,
          body: Column(
            children: [
              // Group header
              _buildHeader(context, group),
              // Divider
              const Divider(height: 1),
              // Feed or non-member message
              Expanded(
                child: group.isMember
                    ? _buildFeed(context, feedAsync)
                    : _buildNonMemberView(context, group),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Group group) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.description != null) ...[
            Text(
              group.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spacingSm),
          ],
          Row(
            children: [
              Icon(Icons.people_outline, size: 16, color: colorScheme.onSurfaceVariant),
              SizedBox(width: tokens.spacingXs),
              Text(
                '${group.memberCount} members',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: tokens.spacingMd),
              Icon(Icons.article_outlined, size: 16, color: colorScheme.onSurfaceVariant),
              SizedBox(width: tokens.spacingXs),
              Text(
                '${group.postCount} posts',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (!group.isPublic) ...[
                SizedBox(width: tokens.spacingMd),
                GroupVisibilityBadge(visibility: group.visibility),
              ],
              const Spacer(),
              GroupJoinButton(
                group: group,
                isLoading: _isJoinLoading,
                onJoin: () => _handleJoin(group),
                onLeave: () => _handleLeave(group),
                onRequestToJoin: () => _handleRequestToJoin(group),
                onCancelRequest: () => _handleCancelRequest(group),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(BuildContext context, AsyncValue<List<dynamic>> feedAsync) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            SizedBox(height: tokens.spacingMd),
            const Text('Failed to load posts'),
            SizedBox(height: tokens.spacingSm),
            FilledButton(
              onPressed: () => ref.read(groupFeedProvider(widget.groupId).notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                SizedBox(height: tokens.spacingMd),
                Text(
                  'No posts yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                SizedBox(height: tokens.spacingXs),
                Text(
                  'Be the first to post in this group!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            PinnedPostsBanner(groupId: widget.groupId),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(groupFeedProvider(widget.groupId).notifier).refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: posts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == posts.length) {
                      final notifier = ref.read(groupFeedProvider(widget.groupId).notifier);
                      if (notifier.isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox(height: 80);
                    }

                    final post = posts[index];
                    return Consumer(
                      builder: (context, ref, _) {
                        final cachedPost = ref.watch(cachedPostProvider(post.id)) ?? post;
                        return PostCard(
                          post: cachedPost,
                          onTap: () => context.push('/post/${cachedPost.id}'),
                          onReactionTap: () => showReactionPicker(context: context, ref: ref, post: cachedPost),
                          onCommentTap: () => context.push('/post/${cachedPost.id}#comments'),
                          onAuthorTap: () => context.push('/user/${cachedPost.userId}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNonMemberView(BuildContext context, Group group) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              'Join to see posts',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              'Join this group to view and create posts.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleJoin(Group group) async {
    final accepted = await GroupTermsSheet.show(context, group);
    if (accepted != true || !mounted) return;

    setState(() => _isJoinLoading = true);
    try {
      await ref.read(groupActionsProvider.notifier).joinGroup(group.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join: $e')),
      );
    } finally {
      if (mounted) setState(() => _isJoinLoading = false);
    }
  }

  Future<void> _handleLeave(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave group?'),
        content: Text('Are you sure you want to leave ${group.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isJoinLoading = true);
    try {
      await ref.read(groupActionsProvider.notifier).leaveGroup(group.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave: $e')),
      );
    } finally {
      if (mounted) setState(() => _isJoinLoading = false);
    }
  }

  Future<void> _handleRequestToJoin(Group group) async {
    final accepted = await GroupTermsSheet.show(context, group);
    if (accepted != true || !mounted) return;

    setState(() => _isJoinLoading = true);
    try {
      await ref.read(groupActionsProvider.notifier).requestToJoin(group.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isJoinLoading = false);
    }
  }

  Future<void> _handleCancelRequest(Group group) async {
    setState(() => _isJoinLoading = true);
    try {
      await ref.read(groupActionsProvider.notifier).cancelJoinRequest(group.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isJoinLoading = false);
    }
  }
}
