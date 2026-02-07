import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/purchase_provider.dart';
import '../../utils/error_utils.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';
import '../../theme/app_color_palette.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacingLg),
        children: [
          _buildSubscriptionSettings(context, ref, tokens),
        ],
      ),
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
    } catch (e, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(handleError(e, stackTrace, operation: 'present_paywall'))),
        );
      }
    }
  }

  Future<void> _presentCustomerCenter(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(purchaseStateProvider.notifier).presentCustomerCenter();
    } catch (e, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(handleError(e, stackTrace, operation: 'customer_center'))),
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
    } catch (e, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(handleError(e, stackTrace, operation: 'restore_purchases'))),
        );
      }
    }
  }
}
