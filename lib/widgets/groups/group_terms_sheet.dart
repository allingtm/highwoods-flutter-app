import 'package:flutter/material.dart';
import '../../models/group/group.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet for T&C acceptance before joining a group
class GroupTermsSheet extends StatelessWidget {
  const GroupTermsSheet({
    super.key,
    required this.group,
    required this.onAccept,
  });

  final Group group;
  final VoidCallback onAccept;

  static Future<bool?> show(BuildContext context, Group group) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => GroupTermsSheet(
        group: group,
        onAccept: () => Navigator.of(context).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final termsText = group.termsText ??
        'By joining this group you agree to be respectful to all members, '
            'follow community guidelines, and keep discussions relevant.';

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.all(tokens.spacingLg),
          child: ClipRect(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: tokens.spacingLg),
              // Title
              Text(
                'Join ${group.name}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: tokens.spacingSm),
              Text(
                'Please review and accept the group terms before joining.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spacingLg),
              // Terms content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(tokens.spacingMd),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Text(
                      termsText,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
              SizedBox(height: tokens.spacingLg),
              // Accept button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAccept,
                  child: const Text('Accept & Join'),
                ),
              ),
              SizedBox(height: tokens.spacingSm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}
