import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final userProfile = ref.watch(userProfileNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authRepository = ref.read(authRepositoryProvider);
              await authRepository.signOut();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
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
                    SizedBox(height: tokens.spacingSm),
                    Text(
                      'Email: ${currentUser?.email ?? "Unknown"}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 60,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                    ),
                  ),
                  SizedBox(height: tokens.spacingXl),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: tokens.spacingLg),
                        AppProfileRow(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: profile.fullName,
                        ),
                        Divider(height: tokens.spacingXl),
                        AppProfileRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: profile.email,
                        ),
                        if (profile.bio != null) ...[
                          Divider(height: tokens.spacingXl),
                          AppProfileRow(
                            icon: Icons.info_outline,
                            label: 'Bio',
                            value: profile.bio!,
                          ),
                        ],
                        Divider(height: tokens.spacingXl),
                        AppProfileRow(
                          icon: Icons.badge_outlined,
                          label: 'Role',
                          value: profile.role.toUpperCase(),
                        ),
                        Divider(height: tokens.spacingXl),
                        AppProfileRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member Since',
                          value: _formatDate(profile.createdAt),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.spacingLg),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Edit Profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit profile feature coming soon!'),
                          ),
                        );
                      },
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
                      ref.read(userProfileNotifierProvider.notifier).refresh();
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
    return '${date.day}/${date.month}/${date.year}';
  }
}
