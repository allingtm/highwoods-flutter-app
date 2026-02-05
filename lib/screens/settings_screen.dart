import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/notification_service.dart';
import '../utils/error_utils.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_tokens.dart';
import '../theme/app_color_palette.dart';
import '../theme/app_palettes.dart';

/// Settings screen with theme toggle and app info
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colors = context.colors;
    final colorScheme = Theme.of(context).colorScheme;
    final currentThemeVariant = ref.watch(themeVariantProvider);
    final notificationPrefs = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacingLg),
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          SizedBox(height: tokens.spacingSm),
          _buildThemeSelector(context, ref, currentThemeVariant, tokens, colors),

          SizedBox(height: tokens.spacingXl),

          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          SizedBox(height: tokens.spacingSm),
          _buildNotificationSettings(context, ref, notificationPrefs, tokens),

          SizedBox(height: tokens.spacingXl),

          // Privacy Section
          _buildSectionHeader(context, 'Privacy'),
          SizedBox(height: tokens.spacingSm),
          _buildPrivacySettings(context, ref, tokens),

          SizedBox(height: tokens.spacingXl),

          // Subscription Section
          _buildSectionHeader(context, 'Subscription'),
          SizedBox(height: tokens.spacingSm),
          _buildSubscriptionSettings(context, ref, tokens),

          SizedBox(height: tokens.spacingXl),

          // Account Section
          _buildSectionHeader(context, 'Account'),
          SizedBox(height: tokens.spacingSm),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update your profile information',
            onTap: () => context.push('/profile'),
          ),

          SizedBox(height: tokens.spacingXl),

          // About Section
          _buildSectionHeader(context, 'About'),
          SizedBox(height: tokens.spacingSm),
          _buildAppVersionTile(context),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms & Conditions coming soon')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy coming soon')),
              );
            },
          ),

          SizedBox(height: tokens.spacingXl),

          // Danger Zone
          _buildSectionHeader(context, 'Account Actions', isDestructive: true),
          SizedBox(height: tokens.spacingSm),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            isDestructive: true,
            onTap: () => _showSignOutDialog(context, ref),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and data',
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),

          SizedBox(height: tokens.spacing2xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool isDestructive = false}) {
    final tokens = context.tokens;
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(left: tokens.spacingSm),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: isDestructive
              ? Theme.of(context).colorScheme.error
              : colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences prefs,
    AppThemeTokens tokens,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPermission = ref.watch(notificationPermissionProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Column(
        children: [
          // Enable notifications button (if not enabled)
          if (!hasPermission)
            ListTile(
              leading: Icon(Icons.notifications_off, color: colorScheme.error),
              title: const Text('Notifications Disabled'),
              subtitle: const Text('Tap to enable push notifications'),
              trailing: FilledButton(
                onPressed: () async {
                  final granted = await NotificationService.requestPermission();
                  ref.read(notificationPermissionProvider.notifier).state = granted;
                },
                child: const Text('Enable'),
              ),
            ),
          if (!hasPermission) const Divider(height: 1),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.article_outlined,
            title: 'New Posts',
            subtitle: 'Posts from your community',
            value: prefs.posts,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).togglePosts(v),
          ),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.comment_outlined,
            title: 'Comments',
            subtitle: 'Replies to your posts',
            value: prefs.comments,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).toggleComments(v),
          ),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.message_outlined,
            title: 'Messages',
            subtitle: 'New direct messages',
            value: prefs.messages,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).toggleMessages(v),
          ),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.people_outline,
            title: 'Connections',
            subtitle: 'Friend requests',
            value: prefs.connections,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).toggleConnections(v),
          ),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.event_outlined,
            title: 'Events',
            subtitle: 'Event reminders',
            value: prefs.events,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).toggleEvents(v),
          ),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.warning_amber_outlined,
            title: 'Safety Alerts',
            subtitle: 'Important community alerts',
            value: prefs.safetyAlerts,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).toggleSafetyAlerts(v),
            isHighPriority: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isHighPriority = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isHighPriority ? colorScheme.error : colorScheme.primary;

    return SwitchListTile(
      secondary: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
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
          return SwitchListTile(
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

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeVariant currentVariant,
    AppThemeTokens tokens,
    AppColorPalette colors,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: tokens.spacingSm),
                Text(
                  'Theme',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spacingMd),
            // Theme variant grid
            Wrap(
              spacing: tokens.spacingSm,
              runSpacing: tokens.spacingSm,
              children: ThemeVariant.values.map((variant) {
                final isSelected = variant == currentVariant;
                final previewColors = AppPalettes.getPreviewColors(variant);
                final bgColor = previewColors[0];
                final primaryColor = previewColors[1];

                return GestureDetector(
                  onTap: () {
                    ref.read(themeVariantProvider.notifier).setThemeVariant(variant);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colors.primary : colors.border,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: _getCheckColor(primaryColor),
                                    size: 14,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(height: tokens.spacingXs),
                      SizedBox(
                        width: 56,
                        child: Text(
                          variant.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? colors.primary : colors.textMuted,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCheckColor(Color backgroundColor) {
    // Use white check for dark colors, dark check for light colors
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF1A1C1E) : Colors.white;
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      margin: EdgeInsets.only(bottom: tokens.spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: context.colors.textSecondary),
              )
            : null,
        trailing: isDestructive ? null : Icon(Icons.chevron_right, color: context.colors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAppVersionTile(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : 'Loading...';

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          margin: EdgeInsets.only(bottom: tokens.spacingSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
          child: ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.onSurface),
            title: const Text(
              'App Version',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              version,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionSettings(
    BuildContext context,
    WidgetRef ref,
    AppThemeTokens tokens,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSupporter = ref.watch(isSupporterProvider);
    final purchaseState = ref.watch(purchaseStateProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isSupporter ? Icons.star : Icons.star_border,
              color: isSupporter ? context.colors.warning : colorScheme.primary,
            ),
            title: Text(
              isSupporter ? 'Highwoods Supporter' : 'Become a Supporter',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              isSupporter
                  ? 'Thank you for supporting the community!'
                  : 'Support the Highwoods community app',
              style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
            ),
            trailing: isSupporter
                ? null
                : FilledButton(
                    onPressed: purchaseState.isLoading
                        ? null
                        : () => _presentPaywall(context, ref),
                    child: const Text('Upgrade'),
                  ),
          ),
          if (isSupporter) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.manage_accounts, color: colorScheme.primary),
              title: const Text(
                'Manage Subscription',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.chevron_right, color: context.colors.textSecondary),
              onTap: () => _presentCustomerCenter(context, ref),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.restore, color: colorScheme.primary),
            title: const Text(
              'Restore Purchases',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: purchaseState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.chevron_right, color: context.colors.textSecondary),
            onTap: purchaseState.isLoading
                ? null
                : () => _restorePurchases(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _presentPaywall(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(purchaseStateProvider.notifier).presentPaywall();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _presentCustomerCenter(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(purchaseStateProvider.notifier).presentCustomerCenter();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(purchaseStateProvider.notifier).restorePurchases();
      final isSupporter = ref.read(isSupporterProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSupporter
                  ? 'Purchases restored successfully!'
                  : 'No previous purchases found.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _showSignOutDialog(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signOut();
      router.go('/');
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final tokens = context.tokens;

    // First confirmation dialog
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Theme.of(dialogContext).colorScheme.error),
            SizedBox(width: tokens.spacingSm),
            const Text('Delete Account?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. All your data will be permanently deleted including:',
            ),
            SizedBox(height: tokens.spacingMd),
            _buildDeleteWarningItem(dialogContext, 'Your profile'),
            _buildDeleteWarningItem(dialogContext, 'Your posts and comments'),
            _buildDeleteWarningItem(dialogContext, 'Your messages'),
            _buildDeleteWarningItem(dialogContext, 'Your connections'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete Account',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Second confirmation dialog - type DELETE to confirm
    final textController = TextEditingController();
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Are you absolutely sure?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type DELETE to confirm:'),
              SizedBox(height: tokens.spacingMd),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: textController.text == 'DELETE'
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: Text(
                'Permanently Delete',
                style: TextStyle(
                  color: textController.text == 'DELETE'
                      ? Theme.of(dialogContext).colorScheme.error
                      : Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (secondConfirm != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Deleting account...'),
          ],
        ),
      ),
    );

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.deleteAccount();

      // Close loading dialog and navigate to welcome screen
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        router.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  Widget _buildDeleteWarningItem(BuildContext context, String text) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacingXs),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: tokens.spacingSm),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
