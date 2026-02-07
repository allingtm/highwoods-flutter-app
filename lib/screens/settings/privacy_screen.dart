import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';
import '../../theme/app_color_palette.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacingLg),
        children: [
          _buildPrivacySettings(context, ref, tokens),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings(
    BuildContext context,
    WidgetRef ref,
    AppThemeTokens tokens,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final userProfile = ref.watch(userProfileNotifierProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: userProfile.when(
        data: (profile) {
          final allowOpenMessaging = profile?.allowOpenMessaging ?? true;
          final showFollowerCount = profile?.showFollowerCount ?? false;
          return Column(
            children: [
              SwitchListTile(
                secondary: Icon(
                  Icons.message_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text(
                  'Open Messaging',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  allowOpenMessaging
                      ? 'Anyone can message you'
                      : 'Only contacts can message you (except for post inquiries)',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                value: allowOpenMessaging,
                onChanged: (value) async {
                  try {
                    await ref
                        .read(userProfileNotifierProvider.notifier)
                        .updateMessagingPrivacy(value);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update setting: $e')),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Icon(
                  Icons.visibility_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text(
                  'Show Follower Count',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  showFollowerCount
                      ? 'Your follower count is visible on your profile'
                      : 'Your follower count is hidden',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                value: showFollowerCount,
                onChanged: (value) async {
                  try {
                    await ref
                        .read(userProfileNotifierProvider.notifier)
                        .updateShowFollowerCount(value);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update setting: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
        loading: () => const ListTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Loading...'),
        ),
        error: (_, __) => ListTile(
          leading: Icon(Icons.error_outline, color: colorScheme.error),
          title: const Text('Failed to load settings'),
        ),
      ),
    );
  }
}
