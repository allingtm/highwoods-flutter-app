import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme_tokens.dart';
import 'feed/feed_screen.dart';
import 'directory_screen.dart';
import 'whats_on_screen.dart';
import 'connections_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          FeedScreen(),         // index 0 - Feed
          DirectoryScreen(),    // index 1 - Directory
          WhatsOnScreen(),      // index 2 - What's On
          ConnectionsScreen(),  // index 3 - Connections
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(
        left: tokens.spacingLg,
        right: tokens.spacingLg,
        bottom: tokens.spacingLg,
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingSm,
            vertical: tokens.spacingMd,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, icon: Icons.forum_outlined, selectedIcon: Icons.forum, label: 'Feed', index: 0),
              _buildNavItem(context, icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: 'Directory', index: 1),
              _buildNavItem(context, icon: Icons.event_outlined, selectedIcon: Icons.event, label: "What's On", index: 2),
              _buildNavItem(context, icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Connections', index: 3),
            ],
          ),
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

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacingMd,
          vertical: tokens.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isSelected ? selectedIcon : icon,
            key: ValueKey(isSelected),
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: tokens.iconSm,
          ),
        ),
      ),
    );
  }
}
