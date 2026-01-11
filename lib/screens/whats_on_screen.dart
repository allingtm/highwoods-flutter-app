import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WhatsOnScreen extends StatelessWidget {
  const WhatsOnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text("What's On")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event,
              size: tokens.iconXl,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              "What's On",
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
