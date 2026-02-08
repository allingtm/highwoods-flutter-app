import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/connections_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/groups_provider.dart';
import '../providers/presence_provider.dart';
import '../providers/realtime_status_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme_tokens.dart';
import 'feed/feed_screen.dart';
import 'groups/groups_list_screen.dart';
import 'connections_screen.dart';
import 'connections/messages_list_screen.dart';

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
  bool _showBottomNav = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Realtime manager references for badge listeners
  FeedRealtimeManager? _feedRealtime;
  GroupsRealtimeManager? _groupsRealtime;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    WidgetsBinding.instance.addObserver(this);

    // Initialize all realtime subscriptions on app load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionsRealtimeProvider).subscribeAll();
      ref.read(feedRealtimeProvider).subscribeAll();
      ref.read(groupsRealtimeProvider).subscribeAll();
      ref.read(presenceProvider).startTracking();

      // Store references and add badge listeners
      _feedRealtime = ref.read(feedRealtimeProvider);
      _groupsRealtime = ref.read(groupsRealtimeProvider);
      _feedRealtime!.addListener(_onBadgeCountChanged);
      _groupsRealtime!.addListener(_onBadgeCountChanged);
    });
  }

  void _onBadgeCountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _feedRealtime?.removeListener(_onBadgeCountChanged);
    _groupsRealtime?.removeListener(_onBadgeCountChanged);
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

    final realtimeStatus = ref.watch(realtimeStatusProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, tokens, colorScheme),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              FeedScreen(
                onMenuTap: _openDrawer,
                onScrollVisibilityChanged: (visible) {
                  if (_showBottomNav != visible) {
                    setState(() => _showBottomNav = visible);
                  }
                },
              ),
              GroupsListScreen(onMenuTap: _openDrawer),
              MessagesListScreen(onMenuTap: _openDrawer),
              ConnectionsScreen(onMenuTap: _openDrawer),
            ],
          ),
          // Connection lost banner
          if (realtimeStatus == RealtimeStatus.disconnected)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Material(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spacingLg,
                    vertical: tokens.spacingSm,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      SizedBox(width: tokens.spacingSm),
                      Text(
                        'Connection lost. Reconnecting...',
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              offset: _showBottomNav ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showBottomNav ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_showBottomNav,
                  child: _buildBottomNavBar(context),
                ),
              ),
            ),
          ),
        ],
      ),
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
              color: colorScheme.primary,
            ),
            child: userProfile.when(
              data: (profile) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
                    child: profile?.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              profile!.avatarUrl!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 32,
                                  color: colorScheme.onPrimary,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 32,
                            color: colorScheme.onPrimary,
                          ),
                  ),
                  SizedBox(height: tokens.spacingMd),
                  Text(
                    profile?.fullName ?? 'Highwoods Resident',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: tokens.spacingXs),
                  Text(
                    profile?.email ?? '',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              loading: () => Center(
                child: CircularProgressIndicator(color: colorScheme.onPrimary),
              ),
              error: (_, __) => Icon(
                Icons.person,
                size: 48,
                color: colorScheme.onPrimary,
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
                  icon: Icons.palette_outlined,
                  label: 'Appearance',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/appearance');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/notifications');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.lock_outline,
                  label: 'Privacy',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/privacy');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.star_outline,
                  label: 'Subscription',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/subscription');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.manage_accounts_outlined,
                  label: 'Account',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/account');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline,
                  label: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/about');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart_outlined,
                  label: 'Stats',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/stats');
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
            _buildNavItem(context, icon: Icons.forum_outlined, selectedIcon: Icons.forum, label: 'Social', index: 0, badgeCount: _feedRealtime?.newPostsCount ?? 0),
            _buildNavItem(context, icon: Icons.groups_outlined, selectedIcon: Icons.groups, label: 'Groups', index: 1, badgeCount: _groupsRealtime?.totalNewPostsCount ?? 0),
            _buildNavItem(context, icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: 'Messages', index: 2, badgeCount: ref.watch(unreadMessagesCountProvider)),
            _buildNavItem(context, icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Network', index: 3, badgeCount: ref.watch(pendingRequestsCountProvider)),
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
    int badgeCount = 0,
  }) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0) _feedRealtime?.resetNewPostsCount();
          setState(() {
            _selectedIndex = index;
            _showBottomNav = true;
          });
        },
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
              Badge(
                isLabelVisible: badgeCount > 0 && !isSelected,
                label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    key: ValueKey(isSelected),
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    size: tokens.iconMd,
                  ),
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
