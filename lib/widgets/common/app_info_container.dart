import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppInfoContainer extends StatelessWidget {
  const AppInfoContainer({
    super.key,
    required this.child,
    this.icon,
  });

  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(tokens.spacingLg),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: tokens.iconLg,
              color: colorScheme.onPrimaryContainer,
            ),
            SizedBox(height: tokens.spacingMd),
          ],
          DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
            child: child,
          ),
        ],
      ),
    );
  }
}
