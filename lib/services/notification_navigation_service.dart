import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Data class for foreground notifications to be displayed as snackbar
class ForegroundNotification {
  final String title;
  final String body;
  final Map<String, dynamic>? additionalData;

  const ForegroundNotification({
    required this.title,
    required this.body,
    this.additionalData,
  });
}

/// Service for handling notification-triggered navigation
///
/// Handles three scenarios:
/// 1. Cold start: App terminated → notification tap → stores pending route
///    until router is registered
/// 2. Warm start: App backgrounded → notification tap → immediate navigation
/// 3. Foreground: App visible → queues notification for in-app snackbar display
///
/// Uses ChangeNotifier to notify listeners (MainApp) when a foreground
/// notification is ready to be displayed.
class NotificationNavigationService extends ChangeNotifier {
  NotificationNavigationService._();

  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  /// Router getter function - set via registerRouter()
  GoRouter Function()? _getRouter;

  /// Pending route from notification click (cold start scenario)
  String? _pendingRoute;

  /// Whether the pending navigation has been consumed
  bool _navigationConsumed = false;

  /// Timestamp when navigation was completed (for race condition prevention)
  DateTime? _navigationCompletedAt;

  /// Pending foreground notification to display as snackbar
  ForegroundNotification? _pendingForegroundNotification;

  /// Check if there's a pending route
  bool get hasPendingRoute => _pendingRoute != null;

  /// Check if navigation should be skipped by other handlers (e.g., deep link handler)
  /// Returns true if:
  /// - There's a pending notification route, OR
  /// - A notification navigation completed within the last 3 seconds
  bool get shouldSkipSplashNavigation {
    if (hasPendingRoute) return true;
    if (_navigationCompletedAt != null) {
      final elapsed = DateTime.now().difference(_navigationCompletedAt!);
      if (elapsed.inSeconds < 3) {
        return true;
      }
    }
    return false;
  }

  /// Register the router for navigation
  /// Call this in MainApp.initState() after the router is available
  ///
  /// This handles cold start: if a notification was tapped before the router
  /// was ready, the pending route will be consumed and navigated to.
  void registerRouter(GoRouter Function() getRouter) {
    _getRouter = getRouter;

    // Check for pending route from cold start
    final pending = consumePendingRoute();
    if (pending != null) {
      debugPrint('NotificationNavigationService: Cold start navigation to $pending');
      _getRouter!().go(pending);
      _navigationCompletedAt = DateTime.now();
    }
  }

  /// Handle notification click - maps deep link to app route and navigates
  ///
  /// Called by NotificationService when a notification is tapped.
  /// Handles both warm start (router available) and cold start (router not yet ready).
  void handleNotificationClick(Map<String, dynamic>? additionalData) {
    if (additionalData == null) {
      debugPrint('NotificationNavigationService: No additional data in notification');
      return;
    }

    debugPrint('NotificationNavigationService: Handling click with data: $additionalData');

    // Extract notification data
    final type = additionalData['type'] as String?;
    final targetId = additionalData['target_id'] as String?;
    final deepLinkPath = additionalData['deep_link_path'] as String?;

    // Map to app route
    final mappedPath = _mapDeepLinkToRoute(
      type: type,
      targetId: targetId,
      deepLinkPath: deepLinkPath,
    );

    if (mappedPath == null) {
      debugPrint('NotificationNavigationService: Could not map notification to route');
      return;
    }

    debugPrint('NotificationNavigationService: Mapped path: $mappedPath');

    // Store pending route
    _pendingRoute = mappedPath;
    _navigationConsumed = false;

    // For warm start (app already running), navigate immediately
    // For cold start, the router redirect will pick up the pending route
    if (_getRouter != null) {
      _navigationConsumed = true;
      debugPrint('NotificationNavigationService: Immediate navigation to $mappedPath');
      _getRouter!().go(mappedPath);
      _pendingRoute = null;
      _navigationCompletedAt = DateTime.now();
    } else {
      debugPrint('NotificationNavigationService: Router not ready, storing pending route: $mappedPath');
    }
  }

  /// Consume and return the pending route
  /// Returns null if no pending route or already consumed
  String? consumePendingRoute() {
    if (_pendingRoute == null || _navigationConsumed) {
      return null;
    }
    _navigationConsumed = true;
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  /// Queue a foreground notification for display as snackbar
  ///
  /// Called by NotificationService when a notification arrives while the app
  /// is in the foreground. Notifies listeners (MainApp) to show the snackbar.
  void showForegroundNotification({
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) {
    debugPrint('NotificationNavigationService: Queuing foreground notification: $title');
    _pendingForegroundNotification = ForegroundNotification(
      title: title,
      body: body,
      additionalData: additionalData,
    );
    notifyListeners();
  }

  /// Consume and return the pending foreground notification
  /// Returns null if no pending notification
  ForegroundNotification? consumeForegroundNotification() {
    final notification = _pendingForegroundNotification;
    _pendingForegroundNotification = null;
    return notification;
  }

  /// Check if there's a pending foreground notification
  bool get hasForegroundNotification => _pendingForegroundNotification != null;

  /// Map notification data to an app route
  ///
  /// Supports both:
  /// - Type-based mapping (type + target_id)
  /// - Direct deep link path (deep_link_path)
  String? _mapDeepLinkToRoute({
    String? type,
    String? targetId,
    String? deepLinkPath,
  }) {
    debugPrint('NotificationNavigationService: _mapDeepLinkToRoute called');
    debugPrint('  type=$type, targetId=$targetId, deepLinkPath=$deepLinkPath');

    // If a direct deep link path is provided, use it
    if (deepLinkPath != null && deepLinkPath.isNotEmpty) {
      final result = _mapPathToRoute(deepLinkPath);
      debugPrint('  Using deep_link_path, mapped to: $result');
      return result;
    }

    // Otherwise, map based on type and target_id
    if (type == null) return null;

    switch (type) {
      case 'post':
      case 'comment':
      case 'safety_alert':
        if (targetId != null) {
          return '/post/$targetId';
        }
        return '/home'; // Fallback to feed

      case 'message':
        if (targetId != null) {
          return '/connections/conversation/$targetId';
        }
        return '/home?tab=3'; // Fallback to connections tab

      case 'connection':
        return '/home?tab=3'; // Connections tab

      case 'event':
        if (targetId != null) {
          return '/whatson/event/$targetId';
        }
        return '/home?tab=2'; // Fallback to What's On tab

      default:
        debugPrint('NotificationNavigationService: Unknown notification type: $type');
        return '/home';
    }
  }

  /// Map a deep link path to an app route
  ///
  /// Handles path normalization and tab-based routing for paths that
  /// should preserve the app shell (bottom navigation).
  String _mapPathToRoute(String path) {
    // Remove leading slash if present for consistent matching
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    // Posts - direct navigation
    if (normalizedPath.startsWith('/post/')) {
      return normalizedPath;
    }

    // Events - direct navigation
    if (normalizedPath.startsWith('/whatson/event/')) {
      return normalizedPath;
    }

    // Conversations - direct navigation
    if (normalizedPath.startsWith('/connections/conversation/')) {
      return normalizedPath;
    }

    // Tab-based routes (preserve app shell)
    if (normalizedPath == '/feed' || normalizedPath.startsWith('/feed/')) {
      return '/home?tab=0';
    }
    if (normalizedPath == '/directory' || normalizedPath.startsWith('/directory/')) {
      return '/home?tab=1';
    }
    if (normalizedPath == '/whatson' || normalizedPath == '/events') {
      return '/home?tab=2';
    }
    if (normalizedPath == '/connections' || normalizedPath == '/messages') {
      return '/home?tab=3';
    }

    // Profile and settings
    if (normalizedPath.startsWith('/profile') || normalizedPath.startsWith('/settings')) {
      return normalizedPath;
    }

    // Default: return the path as-is, GoRouter will handle unknown routes
    return normalizedPath;
  }
}
