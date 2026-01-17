import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/notification_navigation_service.dart';
import '../theme/app_theme_tokens.dart';
import '../theme/app_colors.dart';
import 'feed/feed_screen.dart';
import 'directory_screen.dart';
import 'whats_on_screen.dart';
import 'connections_screen.dart';

/// Main home screen with bottom navigation and side drawer
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialTab = 0});

  /// Initial tab index for deep link navigation
  final int initialTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle tab changes from notification deep links when already mounted
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() {
        _selectedIndex = widget.initialTab;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App lifecycle handling - can be extended for other purposes
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, tokens, colorScheme),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          FeedScreen(onMenuTap: _openDrawer),
          DirectoryScreen(onMenuTap: _openDrawer),
          WhatsOnScreen(onMenuTap: _openDrawer),
          ConnectionsScreen(onMenuTap: _openDrawer),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildDrawer(BuildContext context, AppThemeTokens tokens, ColorScheme colorScheme) {
    final userProfile = ref.watch(userProfileNotifierProvider);

    return Drawer(
      child: Column(
        children: [
          // Drawer Header with user info
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + tokens.spacingLg,
              left: tokens.spacingLg,
              right: tokens.spacingLg,
              bottom: tokens.spacingLg,
            ),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
            ),
            child: userProfile.when(
              data: (profile) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: profile?.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              profile!.avatarUrl!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.white,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.white,
                          ),
                  ),
                  SizedBox(height: tokens.spacingMd),
                  Text(
                    profile?.fullName ?? 'Highwoods Resident',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: tokens.spacingXs),
                  Text(
                    profile?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (_, __) => const Icon(
                Icons.person,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: tokens.spacingSm),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.mail_outline,
                  label: 'Invite Friends',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/connections/invite');
                  },
                ),
                // Debug section - only visible in debug builds
                if (kDebugMode) ...[
                  const Divider(),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacingLg,
                      vertical: tokens.spacingSm,
                    ),
                    child: Text(
                      'Debug',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Test Notification',
                    onTap: () {
                      Navigator.pop(context);
                      // Trigger a test foreground notification
                      NotificationNavigationService.instance.showForegroundNotification(
                        title: 'Test Notification',
                        body: 'This is a test notification to verify the snackbar display.',
                        additionalData: {
                          'type': 'post',
                          'target_id': 'test-post-id',
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          // Sign Out at bottom
          const Divider(height: 1),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            label: 'Sign Out',
            isDestructive: true,
            onTap: () => _showSignOutDialog(context),
          ),
          SizedBox(height: tokens.spacingMd + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      onTap: onTap,
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      navigator.pop(); // Close drawer
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signOut();
      if (mounted) {
        router.go('/');
      }
    }
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(
        left: tokens.spacingLg,
        right: tokens.spacingLg,
        bottom: tokens.spacingMd + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: tokens.spacingLg,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacingSm,
          vertical: tokens.spacingXs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, icon: Icons.forum_outlined, selectedIcon: Icons.forum, label: 'Social', index: 0),
            _buildNavItem(context, icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: 'Business', index: 1),
            _buildNavItem(context, icon: Icons.event_outlined, selectedIcon: Icons.event, label: 'Calendar', index: 2),
            _buildNavItem(context, icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Network', index: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingXs,
            vertical: tokens.spacingXs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: tokens.iconMd,
                ),
              ),
              SizedBox(height: tokens.spacingXs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
