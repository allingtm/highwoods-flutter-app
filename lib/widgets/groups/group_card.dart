import 'package:flutter/material.dart';
import '../../models/group/group.dart';
import '../../theme/app_theme.dart';
import 'group_visibility_badge.dart';

/// Card widget displaying a group in the groups list
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  final Group group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: tokens.spacingMd,
        vertical: tokens.spacingXs,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingMd),
          child: Row(
            children: [
              // Group icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                ),
                child: group.iconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(tokens.radiusMd),
                        child: Image.network(
                          group.iconUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildIconPlaceholder(colorScheme),
                        ),
                      )
                    : _buildIconPlaceholder(colorScheme),
              ),
              SizedBox(width: tokens.spacingMd),
              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!group.isPublic)
                          Padding(
                            padding: EdgeInsets.only(left: tokens.spacingXs),
                            child: GroupVisibilityBadge(visibility: group.visibility),
                          ),
                      ],
                    ),
                    if (group.description != null) ...[
                      SizedBox(height: tokens.spacingXs),
                      Text(
                        group.description!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: tokens.spacingXs),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: tokens.spacingXs),
                        Text(
                          '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (group.postCount > 0) ...[
                          SizedBox(width: tokens.spacingMd),
                          Icon(
                            Icons.article_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: tokens.spacingXs),
                          Text(
                            '${group.postCount} posts',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Member indicator
              if (group.isMember)
                Padding(
                  padding: EdgeInsets.only(left: tokens.spacingSm),
                  child: Icon(
                    Icons.check_circle,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.groups,
        color: colorScheme.onPrimaryContainer,
        size: 24,
      ),
    );
  }
}
