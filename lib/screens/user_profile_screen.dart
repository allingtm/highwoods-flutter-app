import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

/// Provider to fetch a user profile by ID
final otherUserProfileProvider =
    FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getUserProfile(userId);
});

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final profileAsync = ref.watch(otherUserProfileProvider(userId));
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.id == userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_outlined, size: tokens.iconXl),
                    SizedBox(height: tokens.spacingLg),
                    const Text('User not found'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: profile.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                profile.avatarUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 60,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                    ),
                  ),
                  SizedBox(height: tokens.spacingLg),
                  // Display name prominently below avatar
                  Text(
                    profile.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spacingXs),
                  Text(
                    '@${profile.username}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (profile.bio != null) ...[
                    SizedBox(height: tokens.spacingLg),
                    Text(
                      profile.bio!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: tokens.spacingXl),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppProfileRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member Since',
                          value: _formatDate(profile.createdAt),
                        ),
                      ],
                    ),
                  ),
                  // Show message button if logged in and not viewing own profile
                  if (currentUser != null && !isOwnProfile) ...[
                    SizedBox(height: tokens.spacingLg),
                    AppButton(
                      text: 'Message',
                      icon: Icons.message_outlined,
                      onPressed: () {
                        context.push('/connections/conversation/$userId');
                      },
                    ),
                  ],
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
                    color: Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(height: tokens.spacingLg),
                  const Text('Error loading profile'),
                  SizedBox(height: tokens.spacingSm),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spacingLg),
                  AppButton(
                    text: 'Retry',
                    fullWidth: false,
                    onPressed: () {
                      ref.invalidate(otherUserProfileProvider(userId));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
