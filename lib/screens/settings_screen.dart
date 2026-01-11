import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_tokens.dart';
import '../theme/app_colors.dart';

/// Settings screen with theme toggle and app info
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final currentThemeMode = ref.watch(themeModeProvider);

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
          _buildThemeSelector(context, ref, currentThemeMode, tokens),

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
              : AppColors.secondaryText,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
    AppThemeTokens tokens,
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
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_brightness, size: 18),
                  label: const Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                  label: const Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                  label: const Text('Dark'),
                ),
              ],
              selected: {currentMode},
              onSelectionChanged: (Set<ThemeMode> selected) {
                ref.read(themeModeProvider.notifier).setThemeMode(selected.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
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
                style: TextStyle(color: AppColors.secondaryText),
              )
            : null,
        trailing: isDestructive ? null : Icon(Icons.chevron_right, color: AppColors.secondaryText),
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
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
        );
      },
    );
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
