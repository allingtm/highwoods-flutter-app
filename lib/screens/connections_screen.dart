import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/connection.dart';
import '../providers/connections_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_tokens.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  @override
  void initState() {
    super.initState();
    // Subscribe to real-time updates when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionsRealtimeProvider).subscribeAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invite Someone',
            onPressed: () => context.push('/connections/invite'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: EdgeInsets.all(tokens.spacingLg),
          children: [
            // Pending Requests Section
            _buildPendingRequestsCard(context, tokens, colorScheme),
            SizedBox(height: tokens.spacingLg),

            // Messages Section
            _buildMessagesCard(context, tokens, colorScheme),
            SizedBox(height: tokens.spacingXl),

            // Friends Wall Header
            Row(
              children: [
                Text(
                  'Friends Wall',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: View all connections
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            SizedBox(height: tokens.spacingMd),

            // Friends Grid
            _buildFriendsGrid(context, tokens, colorScheme),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(connectionsProvider.notifier).refresh(),
      ref.read(pendingRequestsProvider.notifier).refresh(),
      ref.read(conversationsProvider.notifier).refresh(),
    ]);
  }

  Widget _buildPendingRequestsCard(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    final count = ref.watch(pendingRequestsCountProvider);

    return Card(
      child: ListTile(
        leading: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: colorScheme.primary,
              size: tokens.iconMd,
            ),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(tokens.spacingXs),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: const Text('Pending Requests'),
        subtitle: Text(
          count > 0 ? '$count pending' : 'No pending requests',
          style: TextStyle(
            color: count > 0 ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showPendingRequestsSheet(context),
      ),
    );
  }

  Widget _buildMessagesCard(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    final unreadCount = ref.watch(unreadMessagesCountProvider);

    return Card(
      child: ListTile(
        leading: Stack(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: colorScheme.primary,
              size: tokens.iconMd,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(tokens.spacingXs),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount.toString(),
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: const Text('Messages'),
        subtitle: Text(
          unreadCount > 0 ? '$unreadCount unread' : 'No new messages',
          style: TextStyle(
            color: unreadCount > 0 ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/connections/messages'),
      ),
    );
  }

  Widget _buildFriendsGrid(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    final connections = ref.watch(connectionsProvider);

    return connections.when(
      data: (list) {
        if (list.isEmpty) {
          return _buildEmptyState(context, tokens, colorScheme);
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: tokens.spacingMd,
            crossAxisSpacing: tokens.spacingMd,
            childAspectRatio: 0.85,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return _buildFriendCard(context, tokens, colorScheme, list[index]);
          },
        );
      },
      loading: () => _buildLoadingGrid(tokens),
      error: (error, _) => Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: tokens.iconLg),
            SizedBox(height: tokens.spacingMd),
            Text('Failed to load connections'),
            SizedBox(height: tokens.spacingSm),
            TextButton(
              onPressed: () => ref.read(connectionsProvider.notifier).load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacing2xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: tokens.iconXl,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              'Start Building Your Network',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              'Invite neighbours and local businesses\nto connect with you on Highwoods',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: tokens.spacingXl),
            FilledButton.icon(
              onPressed: () => context.push('/connections/invite'),
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Someone'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    Connection connection,
  ) {
    final user = connection.otherUser;
    if (user == null) return const SizedBox.shrink();

    return Card(
      child: InkWell(
        onTap: () => _showConnectionOptions(context, connection),
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingSm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage:
                    user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              SizedBox(height: tokens.spacingSm),
              Text(
                user.fullName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spacingXs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline, size: tokens.iconSm),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => context.push('/connections/conversation/${user.id}'),
                    tooltip: 'Message',
                  ),
                  SizedBox(width: tokens.spacingSm),
                  IconButton(
                    icon: Icon(Icons.more_vert, size: tokens.iconSm),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showConnectionOptions(context, connection),
                    tooltip: 'Options',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid(AppThemeTokens tokens) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: tokens.spacingMd,
        crossAxisSpacing: tokens.spacingMd,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(tokens.spacingSm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                SizedBox(height: tokens.spacingSm),
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(tokens.radiusSm),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPendingRequestsSheet(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final requests = ref.watch(pendingRequestsProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(tokens.spacingLg),
                      child: Row(
                        children: [
                          Text(
                            'Pending Requests',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: requests.when(
                        data: (list) {
                          if (list.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: tokens.iconXl,
                                    color: colorScheme.primary,
                                  ),
                                  SizedBox(height: tokens.spacingLg),
                                  const Text('No pending requests'),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              return _buildRequestTile(
                                context,
                                tokens,
                                colorScheme,
                                list[index],
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, _) => Center(
                          child: Text('Error: $error'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequestTile(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    Connection request,
  ) {
    final user = request.otherUser;
    if (user == null) return const SizedBox.shrink();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        backgroundImage:
            user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              )
            : null,
      ),
      title: Text(user.fullName),
      subtitle: Text(
        'Sent ${_formatTimeAgo(request.createdAt)}',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.close, color: colorScheme.error),
            onPressed: () => _rejectRequest(request.id),
            tooltip: 'Decline',
          ),
          IconButton(
            icon: Icon(Icons.check, color: colorScheme.primary),
            onPressed: () => _acceptRequest(request.id),
            tooltip: 'Accept',
          ),
        ],
      ),
    );
  }

  void _showConnectionOptions(BuildContext context, Connection connection) {
    final user = connection.otherUser;
    if (user == null) return;

    final tokens = context.tokens;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null
                      ? Text(user.fullName[0].toUpperCase())
                      : null,
                ),
                title: Text(user.fullName),
                subtitle: Text('@${user.username}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Send Message'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/connections/conversation/${user.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to profile
                },
              ),
              ListTile(
                leading: Icon(Icons.person_remove_outlined,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Remove Connection',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveConnection(context, connection);
                },
              ),
              SizedBox(height: tokens.spacingLg),
            ],
          ),
        );
      },
    );
  }

  void _confirmRemoveConnection(BuildContext context, Connection connection) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Connection'),
          content: Text(
            'Are you sure you want to remove ${connection.otherUser?.fullName ?? 'this connection'}? You will no longer be able to message each other.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeConnection(connection.id);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptRequest(String connectionId) async {
    try {
      await acceptConnectionRequest(ref, connectionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection accepted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String connectionId) async {
    try {
      await rejectConnectionRequest(ref, connectionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline: $e')),
        );
      }
    }
  }

  Future<void> _removeConnection(String connectionId) async {
    try {
      await removeConnection(ref, connectionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
