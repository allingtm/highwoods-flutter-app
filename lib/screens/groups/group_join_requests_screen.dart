import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/group/group_join_request.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';

/// Screen for admins/mods to manage pending join requests
class GroupJoinRequestsScreen extends ConsumerWidget {
  const GroupJoinRequestsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final requestsAsync = ref.watch(pendingJoinRequestsProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests')),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load requests'),
              SizedBox(height: tokens.spacingSm),
              FilledButton(
                onPressed: () => ref.invalidate(pendingJoinRequestsProvider(groupId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: tokens.spacingMd),
                  Text(
                    'No pending requests',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(pendingJoinRequestsProvider(groupId)),
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildRequestTile(context, ref, request);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestTile(
    BuildContext context,
    WidgetRef ref,
    GroupJoinRequest request,
  ) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: tokens.spacingMd,
        vertical: tokens.spacingXs,
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingMd),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: request.avatarUrl != null
                  ? NetworkImage(request.avatarUrl!)
                  : null,
              child: request.avatarUrl == null
                  ? Text(
                      request.displayName.isNotEmpty
                          ? request.displayName[0].toUpperCase()
                          : '?',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: tokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.displayName,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (request.message != null) ...[
                    SizedBox(height: tokens.spacingXs),
                    Text(
                      request.message!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: tokens.spacingSm),
            IconButton(
              onPressed: () => _rejectRequest(context, ref, request),
              icon: const Icon(Icons.close),
              tooltip: 'Reject',
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
            ),
            SizedBox(width: tokens.spacingXs),
            IconButton.filled(
              onPressed: () => _approveRequest(context, ref, request),
              icon: const Icon(Icons.check),
              tooltip: 'Approve',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(
    BuildContext context,
    WidgetRef ref,
    GroupJoinRequest request,
  ) async {
    try {
      await ref.read(groupActionsProvider.notifier).approveJoinRequest(
            requestId: request.id,
            groupId: groupId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.displayName} approved')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    WidgetRef ref,
    GroupJoinRequest request,
  ) async {
    try {
      await ref.read(groupActionsProvider.notifier).rejectJoinRequest(
            requestId: request.id,
            groupId: groupId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.displayName} rejected')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }
}
