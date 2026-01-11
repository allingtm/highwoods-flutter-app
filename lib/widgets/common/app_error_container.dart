import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppErrorContainer extends StatelessWidget {
  const AppErrorContainer({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
