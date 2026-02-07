import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_color_palette.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacingLg),
        children: [
          _buildSectionHeader(context, 'Danger Zone', isDestructive: true),
          SizedBox(height: tokens.spacingSm),
          _buildSettingsTile(
            context,
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and data',
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
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

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final tokens = context.tokens;

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
              const Text('Type DELETE ACCOUNT to confirm:'),
              SizedBox(height: tokens.spacingMd),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'DELETE ACCOUNT',
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
              onPressed: textController.text == 'DELETE ACCOUNT'
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: Text(
                'Permanently Delete',
                style: TextStyle(
                  color: textController.text == 'DELETE ACCOUNT'
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

      if (context.mounted) {
        Navigator.of(context).pop();
        router.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
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
