import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
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
          // Security section
          _buildSectionHeader(context, 'Security'),
          SizedBox(height: tokens.spacingSm),
          _buildBiometricToggle(context, ref),
          SizedBox(height: tokens.spacingXl),

          // Danger Zone section
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

  Widget _buildBiometricToggle(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final canOffer = ref.watch(canOfferBiometricProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final biometricLabel = ref.watch(biometricLabelProvider);

    return canOffer.when(
      data: (canOffer) {
        if (!canOffer) {
          return Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            margin: EdgeInsets.only(bottom: tokens.spacingSm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: ListTile(
              leading: Icon(Icons.fingerprint,
                  color: colorScheme.onSurfaceVariant),
              title: const Text(
                'Biometric Login',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Not available on this device',
                style: TextStyle(color: context.colors.textSecondary),
              ),
            ),
          );
        }

        final label = biometricLabel.valueOrNull ?? 'Biometrics';
        final isEnabled = biometricEnabled.valueOrNull ?? false;

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          margin: EdgeInsets.only(bottom: tokens.spacingSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
          child: SwitchListTile(
            secondary: Icon(
              label == 'Face ID' ? Icons.face : Icons.fingerprint,
              color: colorScheme.primary,
            ),
            title: Text(
              '$label Login',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              isEnabled
                  ? 'Sign in quickly with $label'
                  : 'Use $label to sign in',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            value: isEnabled,
            onChanged: (value) async {
              if (value) {
                await _promptPasswordForBiometricEnrollment(
                    context, ref, label);
              } else {
                await ref.read(biometricEnabledProvider.notifier).disable();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$label login disabled',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: context.colors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _promptPasswordForBiometricEnrollment(
    BuildContext context,
    WidgetRef ref,
    String biometricLabel,
  ) async {
    final passwordController = TextEditingController();
    final tokens = context.tokens;

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Enable $biometricLabel Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your password to enable $biometricLabel login.'),
            SizedBox(height: tokens.spacingMd),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, passwordController.text),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    final email = currentUser?.email;

    if (email == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not determine your email address',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final error = await ref.read(biometricEnabledProvider.notifier).enable(
          email: email,
          password: password,
        );

    if (context.mounted) {
      final isSuccess = error == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuccess ? '$biometricLabel login enabled' : error,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor:
              isSuccess ? context.colors.success : context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {bool isDestructive = false}) {
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
        trailing: isDestructive
            ? null
            : Icon(Icons.chevron_right, color: context.colors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(
      BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final tokens = context.tokens;

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Theme.of(dialogContext).colorScheme.error),
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
              style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !context.mounted) return;

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
                      : Theme.of(dialogContext)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.38),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (secondConfirm != true || !context.mounted) return;

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
