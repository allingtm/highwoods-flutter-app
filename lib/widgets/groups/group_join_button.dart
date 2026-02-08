import 'package:flutter/material.dart';
import '../../models/group/group.dart';

/// Stateful join/leave/request button for groups
class GroupJoinButton extends StatelessWidget {
  const GroupJoinButton({
    super.key,
    required this.group,
    required this.onJoin,
    required this.onLeave,
    required this.onRequestToJoin,
    required this.onCancelRequest,
    this.isLoading = false,
  });

  final Group group;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onRequestToJoin;
  final VoidCallback onCancelRequest;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (group.isMember) {
      return OutlinedButton.icon(
        onPressed: onLeave,
        icon: const Icon(Icons.check, size: 16),
        label: const Text('Joined'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    if (group.hasPendingRequest) {
      return OutlinedButton.icon(
        onPressed: onCancelRequest,
        icon: const Icon(Icons.hourglass_top, size: 16),
        label: const Text('Pending'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    if (group.isRequestToJoin) {
      return FilledButton.icon(
        onPressed: onRequestToJoin,
        icon: const Icon(Icons.person_add, size: 16),
        label: const Text('Request'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    // Public group
    return FilledButton.icon(
      onPressed: onJoin,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Join'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
