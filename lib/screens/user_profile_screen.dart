import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/connection.dart';
import '../models/user_profile.dart';
import '../models/feed/feed_models.dart';
import '../providers/auth_provider.dart';
import '../providers/connections_provider.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../widgets/feed/post_card.dart';
import '../widgets/feed/post_interactions.dart';

/// Provider to fetch a user profile by ID
final otherUserProfileProvider =
    FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getUserProfile(userId);
});

/// Provider to check connection status with a specific user
final connectionWithUserProvider =
    FutureProvider.family<Connection?, String>((ref, userId) async {
  final repository = ref.watch(connectionsRepositoryProvider);
  return await repository.getConnectionWith(userId);
});

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key, required this.userId, this.hideMessageButton = false});

  final String userId;
  final bool hideMessageButton;

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final profileAsync = ref.watch(otherUserProfileProvider(widget.userId));
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.id == widget.userId;
    final connectionAsync = ref.watch(connectionWithUserProvider(widget.userId));

    return Scaffold(
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildErrorState(
              context,
              icon: Icons.person_off_outlined,
              message: 'User not found',
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 320,
                floating: false,
                pinned: true,
                forceElevated: innerBoxIsScrolled,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final expandedHeight = 320.0;
                    final collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
                    final currentHeight = constraints.maxHeight;
                    final tabBarHeight = 48.0;

                    // Calculate opacity: fade out as we approach collapsed state
                    final availableRange = expandedHeight - collapsedHeight - tabBarHeight;
                    final currentOffset = currentHeight - collapsedHeight - tabBarHeight;
                    final opacity = (currentOffset / availableRange).clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      background: SafeArea(
                        child: Opacity(
                          opacity: opacity,
                          child: _ProfileHeader(
                            profile: profile,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                bottom: _ProfileTabBar(
                  tabController: _tabController,
                  showMessageButton: currentUser != null &&
                      !isOwnProfile &&
                      !widget.hideMessageButton &&
                      (profile.allowOpenMessaging ||
                          connectionAsync.valueOrNull?.status == ConnectionStatus.accepted),
                  onMessageTap: () {
                    context.push('/connections/conversation/${widget.userId}');
                  },
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _PostsTab(userId: widget.userId),
                _CommentsTab(userId: widget.userId),
                _LikesTab(userId: widget.userId),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(
          context,
          icon: Icons.error_outline,
          message: 'Error loading profile',
          error: error.toString(),
          onRetry: () => ref.invalidate(otherUserProfileProvider(widget.userId)),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context, {
    required IconData icon,
    required String message,
    String? error,
    VoidCallback? onRetry,
  }) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: tokens.iconXl, color: theme.colorScheme.error),
              SizedBox(height: tokens.spacingLg),
              Text(message, style: theme.textTheme.titleMedium),
              if (error != null) ...[
                SizedBox(height: tokens.spacingSm),
                Text(
                  error,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                SizedBox(height: tokens.spacingLg),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom tab bar with optional message button
class _ProfileTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileTabBar({
    required this.tabController,
    required this.showMessageButton,
    this.onMessageTap,
  });

  final TabController tabController;
  final bool showMessageButton;
  final VoidCallback? onMessageTap;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showMessageButton)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: IconButton.filled(
              onPressed: onMessageTap,
              icon: const Icon(Icons.message_outlined, size: 20),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
              ),
            ),
          ),
        Expanded(
          child: TabBar(
            controller: tabController,
            tabs: const [
              Tab(icon: Icon(Icons.grid_on_rounded), text: 'Posts'),
              Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: 'Comments'),
              Tab(icon: Icon(Icons.favorite_border_rounded), text: 'Likes'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Profile header with avatar, name, and bio
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spacingXl,
        tokens.spacingLg,
        tokens.spacingXl,
        tokens.spacingMd,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          SizedBox(height: tokens.spacingMd),
          // Name
          Text(
            profile.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spacingXs),
          // Username
          Text(
            '@${profile.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            SizedBox(height: tokens.spacingSm),
            Text(
              profile.bio!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Posts tab showing user's posts
class _PostsTab extends ConsumerWidget {
  const _PostsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsByIdProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userPostsByIdProvider(userId));
      },
      child: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                _EmptyTabState(
                  icon: Icons.grid_on_rounded,
                  message: 'No posts yet',
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: context.tokens.spacingSm),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                onTap: () => context.push('/post/${post.id}'),
                onReactionTap: () => showReactionPicker(context: context, ref: ref, post: post),
                onCommentTap: () => context.push('/post/${post.id}'),
                onSaveTap: () => handleSavePost(context: context, ref: ref, post: post),
                onAuthorTap: () => context.push('/user/${post.userId}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorTabState(
          message: 'Failed to load posts',
          onRetry: () => ref.invalidate(userPostsByIdProvider(userId)),
        ),
      ),
    );
  }
}

/// Comments tab showing user's comments
class _CommentsTab extends ConsumerWidget {
  const _CommentsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(userCommentsByIdProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userCommentsByIdProvider(userId));
      },
      child: commentsAsync.when(
        data: (comments) {
          if (comments.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                _EmptyTabState(
                  icon: Icons.chat_bubble_outline_rounded,
                  message: 'No comments yet',
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(context.tokens.spacingMd),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return _CommentCard(
                comment: comment,
                onTap: () => context.push('/post/${comment.postId}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorTabState(
          message: 'Failed to load comments',
          onRetry: () => ref.invalidate(userCommentsByIdProvider(userId)),
        ),
      ),
    );
  }
}

/// Likes tab showing posts the user has liked
class _LikesTab extends ConsumerWidget {
  const _LikesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedPostsAsync = ref.watch(userLikedPostsProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userLikedPostsProvider(userId));
      },
      child: likedPostsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                _EmptyTabState(
                  icon: Icons.favorite_border_rounded,
                  message: 'No liked posts yet',
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: context.tokens.spacingSm),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                onTap: () => context.push('/post/${post.id}'),
                onReactionTap: () => showReactionPicker(context: context, ref: ref, post: post),
                onCommentTap: () => context.push('/post/${post.id}'),
                onSaveTap: () => handleSavePost(context: context, ref: ref, post: post),
                onAuthorTap: () => context.push('/user/${post.userId}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorTabState(
          message: 'Failed to load liked posts',
          onRetry: () => ref.invalidate(userLikedPostsProvider(userId)),
        ),
      ),
    );
  }
}

/// Card widget for displaying a user's comment
class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    this.onTap,
  });

  final PostComment comment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: tokens.spacingMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Comment content
              Text(
                comment.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: tokens.spacingSm),
              // Post context and timestamp
              Row(
                children: [
                  Icon(
                    Icons.reply_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: tokens.spacingXs),
                  Expanded(
                    child: Text(
                      'on a post',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    comment.timeAgo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget for tabs
class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: tokens.iconXl,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: tokens.spacingMd),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state widget for tabs
class _ErrorTabState extends StatelessWidget {
  const _ErrorTabState({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: tokens.iconLg,
            color: theme.colorScheme.error,
          ),
          SizedBox(height: tokens.spacingMd),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(height: tokens.spacingMd),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
