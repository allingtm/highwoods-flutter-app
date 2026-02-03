import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/message.dart';
import '../../models/user_profile.dart';
import '../../providers/connections_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String otherUserId;

  const ConversationScreen({
    super.key,
    required this.otherUserId,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  UserProfile? _otherUser;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
    _markAsRead();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _unsubscribe();
    super.dispose();
  }

  Future<void> _loadOtherUser() async {
    // Try to find user from connections
    final connections = ref.read(connectionsProvider).valueOrNull ?? [];
    for (final conn in connections) {
      if (conn.otherUser?.id == widget.otherUserId) {
        setState(() => _otherUser = conn.otherUser);
        return;
      }
    }

    // Try to find from conversations
    final conversations = ref.read(conversationsProvider).valueOrNull ?? [];
    for (final conv in conversations) {
      if (conv.otherUser.id == widget.otherUserId) {
        setState(() => _otherUser = conv.otherUser);
        return;
      }
    }
  }

  Future<void> _markAsRead() async {
    await markMessagesAsRead(ref, widget.otherUserId);
  }

  void _subscribeToMessages() {
    final repository = ref.read(connectionsRepositoryProvider);
    _channel = repository.subscribeToMessages(
      onNewMessage: (message) {
        // Refresh messages if it's from this conversation
        if (message.senderId == widget.otherUserId) {
          ref.invalidate(messagesProvider(widget.otherUserId));
          _markAsRead();
        }
      },
    );
  }

  Future<void> _unsubscribe() async {
    if (_channel != null) {
      final repository = ref.read(connectionsRepositoryProvider);
      await repository.unsubscribe(_channel!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final messages = ref.watch(messagesProvider(widget.otherUserId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: _otherUser?.avatarUrl != null
                  ? NetworkImage(_otherUser!.avatarUrl!)
                  : null,
              child: _otherUser?.avatarUrl == null
                  ? Text(
                      _otherUser?.fullName.isNotEmpty == true
                          ? _otherUser!.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: tokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUser?.fullName ?? 'Loading...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_otherUser?.username != null)
                    Text(
                      '@${_otherUser!.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messages.when(
              data: (list) {
                if (list.isEmpty) {
                  return _buildEmptyChat(context, tokens, colorScheme);
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(tokens.spacingMd),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final message = list[index];
                    final isMine = message.senderId == currentUserId;
                    final showAvatar = !isMine &&
                        (index == list.length - 1 ||
                            list[index + 1].senderId != message.senderId);

                    return _buildMessageBubble(
                      context,
                      tokens,
                      colorScheme,
                      message,
                      isMine,
                      showAvatar,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    SizedBox(height: tokens.spacingMd),
                    const Text('Failed to load messages'),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(messagesProvider(widget.otherUserId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Message Input
          _buildMessageInput(context, tokens, colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(
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
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: _otherUser?.avatarUrl != null
                  ? NetworkImage(_otherUser!.avatarUrl!)
                  : null,
              child: _otherUser?.avatarUrl == null
                  ? Text(
                      _otherUser?.fullName.isNotEmpty == true
                          ? _otherUser!.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              'Start a conversation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              'Send a message to ${_otherUser?.fullName ?? 'this person'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    Message message,
    bool isMine,
    bool showAvatar,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: tokens.spacingSm,
        left: isMine ? tokens.spacing2xl : 0,
        right: isMine ? 0 : tokens.spacing2xl,
      ),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine && showAvatar)
            CircleAvatar(
              radius: 14,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: _otherUser?.avatarUrl != null
                  ? NetworkImage(_otherUser!.avatarUrl!)
                  : null,
              child: _otherUser?.avatarUrl == null
                  ? Text(
                      _otherUser?.fullName.isNotEmpty == true
                          ? _otherUser!.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            )
          else if (!isMine)
            const SizedBox(width: 28),
          SizedBox(width: tokens.spacingSm),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacingMd,
                vertical: tokens.spacingSm,
              ),
              decoration: BoxDecoration(
                color: isMine ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(tokens.radiusLg),
                  topRight: Radius.circular(tokens.radiusLg),
                  bottomLeft: Radius.circular(isMine ? tokens.radiusLg : tokens.radiusSm),
                  bottomRight: Radius.circular(isMine ? tokens.radiusSm : tokens.radiusLg),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMine ? colorScheme.onPrimary : colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: tokens.spacingXs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMine
                              ? colorScheme.onPrimary.withValues(alpha: 0.7)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isMine) ...[
                        SizedBox(width: tokens.spacingXs),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimary.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusXl),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: tokens.spacingLg,
                    vertical: tokens.spacingMd,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            SizedBox(width: tokens.spacingSm),
            IconButton.filled(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/user/${widget.otherUserId}?fromConversation=true');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.block,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Block User',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Block user
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await sendMessage(
        ref,
        recipientId: widget.otherUserId,
        content: content,
      );

      _messageController.clear();
      ref.invalidate(messagesProvider(widget.otherUserId));

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
