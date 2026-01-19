import 'package:flutter/material.dart';

import '../../models/feed/post.dart';
import '../../models/post_category.dart';
import '../../models/post_type.dart';
import '../../theme/app_theme.dart';

/// A button to message the author of a post.
///
/// Displays context-appropriate label based on the post type
/// (e.g., "Message Seller" for marketplace, "Contact Finder" for found items).
class MessageAuthorButton extends StatelessWidget {
  const MessageAuthorButton({
    super.key,
    required this.post,
    required this.onTap,
    this.expanded = true,
  });

  final Post post;
  final VoidCallback onTap;

  /// If true, button expands to full width. If false, wraps content.
  final bool expanded;

  String get _buttonLabel {
    switch (post.postType) {
      // Marketplace
      case PostType.forSale:
      case PostType.freeItem:
        return 'Message Seller';
      case PostType.wanted:
        return 'Contact Buyer';
      case PostType.borrowRent:
        return 'Message Owner';

      // Jobs
      case PostType.hiring:
        return 'Contact Employer';
      case PostType.lookingForWork:
        return 'Contact Job Seeker';

      // Lost & Found
      case PostType.lostPet:
      case PostType.lostItem:
        return 'Contact Owner';
      case PostType.foundPet:
      case PostType.foundItem:
        return 'Contact Finder';

      // Recommendations (help-related)
      case PostType.helpRequest:
      case PostType.helpOffer:
        return 'Get in Touch';

      // Social
      case PostType.hobbyPartner:
        return 'Message';

      // Default fallback (shouldn't be reached for enabled types)
      default:
        return 'Message';
    }
  }

  /// Returns true if this button should use filled (primary) style
  bool get _usePrimaryStyle {
    switch (post.category) {
      case PostCategory.marketplace:
      case PostCategory.jobs:
      case PostCategory.lostFound:
        return true;
      default:
        return false;
    }
  }

  /// Returns category color for lost & found emphasis
  Color? _getCategoryColor(BuildContext context) {
    if (post.category == PostCategory.lostFound) {
      return post.category.color;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final categoryColor = _getCategoryColor(context);

    if (_usePrimaryStyle) {
      // Filled button for high-priority categories
      return SizedBox(
        width: expanded ? double.infinity : null,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: Text(_buttonLabel),
          style: categoryColor != null
              ? FilledButton.styleFrom(
                  backgroundColor: categoryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spacingLg,
                    vertical: tokens.spacingMd,
                  ),
                )
              : FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spacingLg,
                    vertical: tokens.spacingMd,
                  ),
                ),
        ),
      );
    } else {
      // Outlined button for lower-priority categories
      return SizedBox(
        width: expanded ? double.infinity : null,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: Text(_buttonLabel),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacingLg,
              vertical: tokens.spacingMd,
            ),
          ),
        ),
      );
    }
  }
}
