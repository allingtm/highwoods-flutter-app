import 'package:flutter/material.dart';
import '../../models/group/group_models.dart';
import '../../theme/app_theme.dart';

/// Member row widget with role badge and overflow actions
class GroupMemberTile extends StatelessWidget {
  const GroupMemberTile({
    super.key,
    required this.member,
    this.currentUserRole,
    this.onPromote,
    this.onDemote,
    this.onRemove,
    this.onTap,
  });

  final GroupMember member;
  final GroupMemberRole? currentUserRole;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  bool get _canModerate => currentUserRole?.canModerate ?? false;
  bool get _canManageRoles => currentUserRole?.canManageRoles ?? false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: colorScheme.primaryContainer,
        backgroundImage: member.avatarUrl != null
            ? NetworkImage(member.avatarUrl!)
            : null,
        child: member.avatarUrl == null
            ? Text(
                member.displayName.isNotEmpty
                    ? member.displayName[0].toUpperCase()
                    : '?',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (member.role != GroupMemberRole.member) ...[
            SizedBox(width: tokens.spacingXs),
            _buildRoleBadge(context, member.role),
          ],
        ],
      ),
      subtitle: member.username != null
          ? Text(
              '@${member.username}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: _canModerate && member.role != GroupMemberRole.admin
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                if (_canManageRoles && member.role == GroupMemberRole.member)
                  const PopupMenuItem(
                    value: 'promote',
                    child: ListTile(
                      leading: Icon(Icons.arrow_upward, size: 20),
                      title: Text('Promote to Moderator'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (_canManageRoles && member.role == GroupMemberRole.moderator)
                  const PopupMenuItem(
                    value: 'demote',
                    child: ListTile(
                      leading: Icon(Icons.arrow_downward, size: 20),
                      title: Text('Demote to Member'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.person_remove, size: 20, color: Colors.red),
                    title: Text('Remove', style: TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'promote':
                    onPromote?.call();
                  case 'demote':
                    onDemote?.call();
                  case 'remove':
                    onRemove?.call();
                }
              },
            )
          : null,
    );
  }

  Widget _buildRoleBadge(BuildContext context, GroupMemberRole role) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color textColor;
    switch (role) {
      case GroupMemberRole.admin:
        backgroundColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
      case GroupMemberRole.moderator:
        backgroundColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
      case GroupMemberRole.member:
        backgroundColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
