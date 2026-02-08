import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/group/group_models.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/groups/group_member_tile.dart';

/// Screen showing all members of a group with role management
class GroupMembersScreen extends ConsumerWidget {
  const GroupMembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final currentUserRole = groupAsync.valueOrNull?.currentUserRole;

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load members'),
              SizedBox(height: tokens.spacingSm),
              FilledButton(
                onPressed: () => ref.invalidate(groupMembersProvider(groupId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No members'));
          }

          // Sort: admins first, then moderators, then members
          final sorted = List<GroupMember>.from(members);
          sorted.sort((a, b) {
            const order = {
              GroupMemberRole.admin: 0,
              GroupMemberRole.moderator: 1,
              GroupMemberRole.member: 2,
            };
            return (order[a.role] ?? 3).compareTo(order[b.role] ?? 3);
          });

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(groupMembersProvider(groupId)),
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final member = sorted[index];
                return GroupMemberTile(
                  member: member,
                  currentUserRole: currentUserRole,
                  onTap: () => context.push('/user/${member.userId}'),
                  onPromote: () => _updateRole(
                    context, ref, member, GroupMemberRole.moderator,
                  ),
                  onDemote: () => _updateRole(
                    context, ref, member, GroupMemberRole.member,
                  ),
                  onRemove: () => _removeMember(context, ref, member),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateRole(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
    GroupMemberRole newRole,
  ) async {
    try {
      await ref.read(groupActionsProvider.notifier).updateMemberRole(
            groupId: groupId,
            userId: member.userId,
            role: newRole,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.displayName} is now a ${newRole.displayName}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove ${member.displayName} from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(groupActionsProvider.notifier).removeMember(
            groupId: groupId,
            userId: member.userId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.displayName} removed')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }
}
