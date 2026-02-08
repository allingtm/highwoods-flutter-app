import 'package:flutter/material.dart';
import '../../models/group/group.dart';

/// Small badge showing group visibility type
class GroupVisibilityBadge extends StatelessWidget {
  const GroupVisibilityBadge({super.key, required this.visibility});

  final GroupVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    switch (visibility) {
      case GroupVisibility.public_:
        icon = Icons.public;
      case GroupVisibility.requestToJoin:
        icon = Icons.lock_open;
      case GroupVisibility.private_:
        icon = Icons.lock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            visibility.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
