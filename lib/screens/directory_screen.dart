import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text('Directory')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: tokens.iconXl,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              'Directory',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              'Coming soon',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
