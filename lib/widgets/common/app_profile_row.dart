import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppProfileRow extends StatelessWidget {
  const AppProfileRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: tokens.iconSm),
        SizedBox(width: tokens.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spacingXs),
              Text(
                value,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
