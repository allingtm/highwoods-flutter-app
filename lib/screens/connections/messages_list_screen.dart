import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/message.dart';
import '../../providers/connections_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';

class MessagesListScreen extends ConsumerWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
        child: conversations.when(
          data: (list) {
            if (list.isEmpty) {
              return _buildEmptyState(context, tokens, colorScheme);
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: tokens.spacingSm),
              itemCount: list.length,
              itemBuilder: (context, index) {
                return _buildConversationTile(
                  context,
                  ref,
                  tokens,
                  colorScheme,
                  list[index],
                );
              },
            );
          },
          loading: () => _buildLoadingState(tokens),
          error: (error, _) => _buildErrorState(context, ref, tokens, colorScheme, error),
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
        padding: EdgeInsets.all(tokens.spacing2xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: tokens.iconXl,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              'No Messages Yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              'Start a conversation with one of your connections',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: tokens.spacingXl),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.people),
              label: const Text('View Connections'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppThemeTokens tokens) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: tokens.spacingSm),
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          title: Container(
            height: 14,
            width: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(tokens.radiusSm),
            ),
          ),
          subtitle: Container(
            height: 12,
            width: 150,
            margin: EdgeInsets.only(top: tokens.spacingXs),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(tokens.radiusSm),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    Object error,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: tokens.iconLg),
          SizedBox(height: tokens.spacingMd),
          const Text('Failed to load messages'),
          SizedBox(height: tokens.spacingSm),
          TextButton(
            onPressed: () => ref.read(conversationsProvider.notifier).load(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    WidgetRef ref,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    Conversation conversation,
  ) {
    final user = conversation.otherUser;
    final lastMessage = conversation.lastMessage;
    final hasUnread = conversation.hasUnread;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        user.fullName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        lastMessage.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(lastMessage.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: hasUnread ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
          ),
          if (hasUnread) ...[
            SizedBox(height: tokens.spacingXs),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacingSm,
                vertical: tokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(tokens.radiusSm),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () => context.push('/connections/conversation/${user.id}'),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show time
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      // Older - show date
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
