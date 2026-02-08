import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/feed/feed_models.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';

/// Horizontal banner showing pinned posts at the top of a group feed
class PinnedPostsBanner extends ConsumerWidget {
  const PinnedPostsBanner({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedAsync = ref.watch(groupPinnedPostsProvider(groupId));

    return pinnedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();

        final tokens = context.tokens;
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacingMd,
                vertical: tokens.spacingSm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: tokens.spacingXs),
                  Text(
                    'Pinned',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: tokens.spacingMd),
                itemCount: posts.length,
                separatorBuilder: (_, __) => SizedBox(width: tokens.spacingSm),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _PinnedPostChip(
                    post: post,
                    onTap: () => context.push('/post/${post.id}'),
                  );
                },
              ),
            ),
            SizedBox(height: tokens.spacingSm),
            Divider(height: 1, color: colorScheme.outlineVariant),
          ],
        );
      },
    );
  }
}

class _PinnedPostChip extends StatelessWidget {
  const _PinnedPostChip({required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final snippet = (post.content ?? '').length > 60
        ? '${post.content!.substring(0, 60)}...'
        : (post.content ?? 'Pinned post');

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingMd,
            vertical: tokens.spacingSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (post.authorAvatarUrl != null)
                CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(post.authorAvatarUrl!),
                )
              else
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.person, size: 14, color: colorScheme.primary),
                ),
              SizedBox(width: tokens.spacingSm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  snippet,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
