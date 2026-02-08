import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder screen for the upcoming Groups feature.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: onMenuTap != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuTap,
                tooltip: 'Open menu',
              )
            : null,
        title: const Text('Groups'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              SizedBox(height: tokens.spacingLg),
              Text(
                'Coming Soon',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: tokens.spacingSm),
              Text(
                'Connect with your neighbours in groups.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
