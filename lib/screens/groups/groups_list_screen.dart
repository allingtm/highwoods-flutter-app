import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/group/group.dart';
import '../../providers/groups_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/groups/group_card.dart';
import '../../widgets/groups/group_terms_sheet.dart';

/// Main groups tab screen showing joined groups and discoverable groups
class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final allGroups = ref.watch(allGroupsProvider);
    final userProfile = ref.watch(userProfileProvider);
    final isAdmin = userProfile.valueOrNull?.role == 'admin';

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
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push('/create-group'),
              tooltip: 'Create Group',
              child: const Icon(Icons.add),
            )
          : null,
      body: allGroups.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              SizedBox(height: tokens.spacingMd),
              Text('Failed to load groups', style: textTheme.bodyLarge),
              SizedBox(height: tokens.spacingSm),
              FilledButton(
                onPressed: () => ref.read(allGroupsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: tokens.spacingLg),
                  Text('No groups yet', style: textTheme.headlineSmall),
                ],
              ),
            );
          }

          final myGroups = groups.where((g) => g.isMember).toList();
          final discoverGroups = groups.where((g) => !g.isMember).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(allGroupsProvider.notifier).refresh(),
            child: ListView(
              children: [
                // My Groups section
                if (myGroups.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spacingLg,
                      tokens.spacingLg,
                      tokens.spacingLg,
                      tokens.spacingSm,
                    ),
                    child: Text(
                      'My Groups',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...myGroups.map((group) => GroupCard(
                        group: group,
                        onTap: () => context.push('/group/${group.id}'),
                      )),
                ],
                // Discover section
                if (discoverGroups.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spacingLg,
                      tokens.spacingLg,
                      tokens.spacingLg,
                      tokens.spacingSm,
                    ),
                    child: Text(
                      'Discover',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...discoverGroups.map((group) => GroupCard(
                        group: group,
                        onTap: () => _handleGroupTap(context, ref, group),
                      )),
                ],
                SizedBox(height: tokens.spacingXl),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleGroupTap(BuildContext context, WidgetRef ref, Group group) {
    if (group.isMember) {
      context.push('/group/${group.id}');
      return;
    }

    // For non-members, show join prompt or navigate to group detail
    if (group.isPublic) {
      _showJoinFlow(context, ref, group);
    } else if (group.isRequestToJoin) {
      if (group.hasPendingRequest) {
        // Already requested, show info
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your request is pending approval')),
        );
      } else {
        _showJoinFlow(context, ref, group);
      }
    }
  }

  Future<void> _showJoinFlow(BuildContext context, WidgetRef ref, Group group) async {
    final accepted = await GroupTermsSheet.show(context, group);
    if (accepted != true || !context.mounted) return;

    try {
      if (group.isPublic) {
        await ref.read(groupActionsProvider.notifier).joinGroup(group.id);
        if (!context.mounted) return;
        context.push('/group/${group.id}');
      } else if (group.isRequestToJoin) {
        await ref.read(groupActionsProvider.notifier).requestToJoin(group.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join request sent')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }
}
