import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'notification_navigation_service.dart';

/// Service for managing push notifications via OneSignal
class NotificationService {
  /// Notification permission rationale message
  static const String permissionRationale =
      'Get notified about community updates, safety alerts, events, and messages from your neighbors.';
  NotificationService._();

  static String get _appId => dotenv.env['ONESIGNAL_APP_ID'] ?? '';

  /// Initialize OneSignal - call in main.dart before runApp
  static Future<void> initialize() async {
    final appId = _appId;
    if (appId.isEmpty) {
      // OneSignal not configured - skip initialization
      return;
    }

    // Enable verbose logging in debug mode
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize with App ID
    OneSignal.initialize(appId);

    // Setup notification click handler
    OneSignal.Notifications.addClickListener(_onNotificationClick);

    // Setup foreground notification handler
    OneSignal.Notifications.addForegroundWillDisplayListener(
      _onForegroundNotification,
    );
  }

  /// Request notification permission
  /// Returns true if permission was granted
  static Future<bool> requestPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }

  /// Show a rationale dialog before requesting permission
  /// This improves opt-in rates by explaining the value
  /// Returns true if permission was granted
  static Future<bool> requestPermissionWithRationale(BuildContext context) async {
    // Show rationale dialog first
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Stay Connected'),
        content: const Text(permissionRationale),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable Notifications'),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      return await requestPermission();
    }
    return false;
  }

  /// Check if notifications are enabled
  static bool get hasPermission => OneSignal.Notifications.permission;

  /// Set external user ID for targeting
  /// Call this after user logs in
  static Future<void> setExternalUserId(String userId) async {
    await OneSignal.login(userId);
  }

  /// Set user tags for targeted notifications
  static void setUserTags({
    required String userId,
    String? username,
    String? email,
  }) {
    OneSignal.User.addTags({
      'user_id': userId,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      'community': 'highwoods',
    });
  }

  /// Update notification preferences
  /// These tags are used by OneSignal segments for targeting
  static void setNotificationPreferences({
    bool posts = true,
    bool comments = true,
    bool messages = true,
    bool connections = true,
    bool events = true,
    bool safetyAlerts = true,
  }) {
    OneSignal.User.addTags({
      'notify_posts': posts.toString(),
      'notify_comments': comments.toString(),
      'notify_messages': messages.toString(),
      'notify_connections': connections.toString(),
      'notify_events': events.toString(),
      'notify_safety': safetyAlerts.toString(),
    });
  }

  /// Clear user data on logout
  static Future<void> logout() async {
    await OneSignal.logout();
  }

  /// Handle notification click - delegates to NotificationNavigationService
  static void _onNotificationClick(OSNotificationClickEvent event) {
    debugPrint('NotificationService: Notification clicked');
    NotificationNavigationService.instance.handleNotificationClick(
      event.notification.additionalData,
    );
  }

  /// Handle foreground notifications - suppress system notification and show in-app snackbar
  static void _onForegroundNotification(
    OSNotificationWillDisplayEvent event,
  ) {
    debugPrint('NotificationService: Foreground notification received');
    // Prevent system notification banner
    event.preventDefault();

    // Queue for in-app snackbar display
    NotificationNavigationService.instance.showForegroundNotification(
      title: event.notification.title ?? 'Notification',
      body: event.notification.body ?? '',
      additionalData: event.notification.additionalData,
    );
  }
}
