import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';
import '../../theme/app_color_palette.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final notificationPrefs = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacingLg),
        children: [
          _buildNotificationSettings(context, ref, notificationPrefs, tokens),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences prefs,
    AppThemeTokens tokens,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPermission = ref.watch(notificationPermissionProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Column(
        children: [
          if (!hasPermission)
            ListTile(
              leading: Icon(Icons.notifications_off, color: colorScheme.error),
              title: const Text('Notifications Disabled'),
              subtitle: const Text('Tap to enable push notifications'),
              trailing: FilledButton(
                onPressed: () async {
                  final granted = await NotificationService.requestPermission();
                  ref.read(notificationPermissionProvider.notifier).state = granted;
                },
                child: const Text('Enable'),
              ),
            ),
          if (!hasPermission) const Divider(height: 1),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.article_outlined,
            title: 'New Posts',
            subtitle: 'Posts from your community',
            value: prefs.posts,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).togglePosts(v),
          ),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.comment_outlined,
            title: 'Comments',
            subtitle: 'Replies to your posts',
            value: prefs.comments,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).toggleComments(v),
          ),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.message_outlined,
            title: 'Messages',
            subtitle: 'New direct messages',
            value: prefs.messages,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).toggleMessages(v),
          ),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.people_outline,
            title: 'Connections',
            subtitle: 'Friend requests',
            value: prefs.connections,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).toggleConnections(v),
          ),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.event_outlined,
            title: 'Events',
            subtitle: 'Event reminders',
            value: prefs.events,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).toggleEvents(v),
          ),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.warning_amber_outlined,
            title: 'Safety Alerts',
            subtitle: 'Important community alerts',
            value: prefs.safetyAlerts,
            onChanged: (v) =>
                ref.read(notificationPreferencesProvider.notifier).toggleSafetyAlerts(v),
            isHighPriority: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isHighPriority = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isHighPriority ? colorScheme.error : colorScheme.primary;

    return SwitchListTile(
      secondary: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
