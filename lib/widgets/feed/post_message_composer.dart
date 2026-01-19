import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/feed/post.dart';
import '../../models/post_type.dart';
import '../../providers/connections_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_utils.dart';

/// A bottom sheet for composing and sending a message to a post author.
///
/// Shows post context (title/image) and provides a pre-filled message template
/// based on the post type. Sends the message with post context for tracking.
class PostMessageComposer extends ConsumerStatefulWidget {
  const PostMessageComposer({
    super.key,
    required this.post,
    this.onMessageSent,
  });

  final Post post;

  /// Called after the message is successfully sent
  final VoidCallback? onMessageSent;

  @override
  ConsumerState<PostMessageComposer> createState() => _PostMessageComposerState();
}

class _PostMessageComposerState extends ConsumerState<PostMessageComposer> {
  late final TextEditingController _messageController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: _getDefaultTemplate());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Returns a pre-filled message template based on post type
  String _getDefaultTemplate() {
    final title = widget.post.title ?? 'this item';

    switch (widget.post.postType) {
      // Marketplace
      case PostType.forSale:
        return 'Hi, I\'m interested in "$title". Is it still available?';
      case PostType.freeItem:
        return 'Hi, I\'m interested in "$title". Is it still available?';
      case PostType.wanted:
        return 'Hi, I might have what you\'re looking for. Let me know if you\'re interested!';
      case PostType.borrowRent:
        return 'Hi, I\'d like to borrow/rent "$title". Is it available?';

      // Jobs
      case PostType.hiring:
        return 'Hi, I\'m interested in this opportunity. I\'d love to discuss further.';
      case PostType.lookingForWork:
        return 'Hi, I saw your post about looking for work. I might have something for you.';

      // Lost & Found
      case PostType.lostPet:
        return 'Hi, I think I may have seen your pet. Let me know how I can help!';
      case PostType.foundPet:
        return 'Hi, I think this might be my pet! Can we arrange a time to meet?';
      case PostType.lostItem:
        return 'Hi, I think I may have found your item. Let me know if it\'s what you\'re looking for.';
      case PostType.foundItem:
        return 'Hi, I think this might be mine! Can we arrange to meet?';

      // Recommendations (help)
      case PostType.helpRequest:
        return 'Hi, I\'d be happy to help with this. Let me know more details!';
      case PostType.helpOffer:
        return 'Hi, I\'m interested in your offer. Could we discuss details?';

      // Social
      case PostType.hobbyPartner:
        return 'Hi, I\'d love to join! When are you planning to meet?';

      default:
        return 'Hi, I\'m reaching out about your post.';
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await sendMessage(
        ref,
        recipientId: widget.post.userId,
        content: content,
        postId: widget.post.id,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onMessageSent?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getErrorMessage(e)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final post = widget.post;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Send Message',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              SizedBox(height: tokens.spacingLg),

              // Post context card
              Container(
                padding: EdgeInsets.all(tokens.spacingMd),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                ),
                child: Row(
                  children: [
                    // Post image thumbnail
                    if (post.hasImages)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(tokens.radiusSm),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Image.network(
                            post.primaryImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: theme.colorScheme.surfaceContainerHigh,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: post.category.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(tokens.radiusSm),
                        ),
                        child: Icon(
                          post.category.icon,
                          color: post.category.color,
                          size: 24,
                        ),
                      ),

                    SizedBox(width: tokens.spacingMd),

                    // Post info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title ?? post.postType.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: tokens.spacingXs),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                backgroundImage: post.authorAvatarUrl != null
                                    ? NetworkImage(post.authorAvatarUrl!)
                                    : null,
                                child: post.authorAvatarUrl == null
                                    ? Text(
                                        (post.authorName ?? '?')[0].toUpperCase(),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer,
                                          fontSize: 10,
                                        ),
                                      )
                                    : null,
                              ),
                              SizedBox(width: tokens.spacingXs),
                              Expanded(
                                child: Text(
                                  post.authorName ?? 'Anonymous',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: tokens.spacingLg),

              // Message input
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Your message',
                  hintText: 'Type your message...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                  ),
                ),
                maxLength: 2000,
                maxLines: 4,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                enabled: !_isSending,
              ),

              SizedBox(height: tokens.spacingXl),

              // Send button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isSending ? 'Sending...' : 'Send Message'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: tokens.spacingMd,
                    ),
                  ),
                ),
              ),

              SizedBox(height: tokens.spacingSm),

              // Info text
              Text(
                'This message will be sent directly to ${post.authorName ?? 'the author'}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the post message composer as a bottom sheet
Future<void> showPostMessageComposer(
  BuildContext context, {
  required Post post,
  VoidCallback? onMessageSent,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => PostMessageComposer(
      post: post,
      onMessageSent: onMessageSent,
    ),
  );
}
