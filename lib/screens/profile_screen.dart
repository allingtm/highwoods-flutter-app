import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/feed_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final userProfile = ref.watch(userProfileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: userProfile.when(
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: tokens.iconXl),
                    SizedBox(height: tokens.spacingLg),
                    const Text('Profile not found'),
                  ],
                ),
              );
            }

            final postCountAsync =
                ref.watch(userPostCountProvider(profile.id));
            final followerCountAsync = ref.watch(ownFollowerCountProvider);
            final followingCountAsync =
                ref.watch(followingCountProvider(profile.id));

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacingXl,
                vertical: tokens.spacingLg,
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: profile.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              profile.avatarUrl!,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 55,
                                  color: theme
                                      .colorScheme.onPrimaryContainer,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 55,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                  ),
                  SizedBox(height: tokens.spacingLg),

                  // Full name
                  Text(
                    profile.fullName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spacingXs),

                  // Username
                  Text(
                    '@${profile.username}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Bio
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    SizedBox(height: tokens.spacingMd),
                    Text(
                      profile.bio!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: tokens.spacingXl),

                  // Stats row
                  Row(
                    children: [
                      _StatColumn(
                        label: 'Posts',
                        asyncValue: postCountAsync,
                      ),
                      _StatColumn(
                        label: 'Followers',
                        asyncValue: followerCountAsync,
                      ),
                      _StatColumn(
                        label: 'Following',
                        asyncValue: followingCountAsync,
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spacingXl),

                  // Edit Profile button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/profile/edit'),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: EdgeInsets.all(tokens.spacingXl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: tokens.iconXl,
                    color: theme.colorScheme.error,
                  ),
                  SizedBox(height: tokens.spacingLg),
                  const Text('Error loading profile'),
                  SizedBox(height: tokens.spacingLg),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(userProfileNotifierProvider.notifier)
                          .refresh();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.asyncValue,
  });

  final String label;
  final AsyncValue<int> asyncValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          asyncValue.when(
            data: (count) => Text(
              '$count',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            loading: () => SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            error: (_, __) => Text(
              '-',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
