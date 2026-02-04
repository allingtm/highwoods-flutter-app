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

/// Data class for notification navigation with parent route for back navigation
class NotificationRoute {
  final String parentRoute;
  final String targetRoute;

  const NotificationRoute({
    required this.parentRoute,
    required this.targetRoute,
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
  NotificationRoute? _pendingRoute;

  /// Whether the pending navigation has been consumed
  bool _navigationConsumed = false;

  /// Timestamp when navigation was completed (for race condition prevention)
  DateTime? _navigationCompletedAt;

  /// Pending foreground notification to display as snackbar
  ForegroundNotification? _pendingForegroundNotification;

  /// Check if there's a pending route
  bool get hasPendingRoute => _pendingRoute != null;

  /// Peek at the pending route without consuming it
  /// Used by router redirect to return parent route without preventing
  /// registerRouter from doing the full two-step navigation
  NotificationRoute? peekPendingRoute() {
    return _pendingRoute;
  }

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
      debugPrint('NotificationNavigationService: Cold start navigation');
      debugPrint('  Parent: ${pending.parentRoute}');
      debugPrint('  Target: ${pending.targetRoute}');
      _navigateWithParent(pending);
      _navigationCompletedAt = DateTime.now();
    }
  }

  /// Navigate with two-step navigation: go to parent first, then push target
  /// This ensures proper back navigation from notification-opened screens
  void _navigateWithParent(NotificationRoute route) {
    final router = _getRouter!();

    // If parent and target are the same, just navigate once (tab-based routes)
    if (route.parentRoute == route.targetRoute) {
      debugPrint('NotificationNavigationService: Same parent/target, single navigation');
      router.go(route.parentRoute);
      return;
    }

    // Two-step navigation: go to parent first, then push target
    debugPrint('NotificationNavigationService: Two-step navigation');
    router.go(route.parentRoute);
    // Then push target (adds to stack, enabling back navigation)
    // Use Future.microtask to ensure parent navigation completes first
    Future.microtask(() {
      router.push(route.targetRoute);
    });
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

    // Map to app route with parent for back navigation
    final notificationRoute = _mapDeepLinkToRoute(
      type: type,
      targetId: targetId,
      deepLinkPath: deepLinkPath,
    );

    if (notificationRoute == null) {
      debugPrint('NotificationNavigationService: Could not map notification to route');
      return;
    }

    debugPrint('NotificationNavigationService: Mapped route');
    debugPrint('  Parent: ${notificationRoute.parentRoute}');
    debugPrint('  Target: ${notificationRoute.targetRoute}');

    // Store pending route
    _pendingRoute = notificationRoute;
    _navigationConsumed = false;

    // For warm start (app already running), navigate immediately
    // For cold start, the router redirect will pick up the pending route
    if (_getRouter != null) {
      _navigationConsumed = true;
      debugPrint('NotificationNavigationService: Immediate navigation');
      _navigateWithParent(notificationRoute);
      _pendingRoute = null;
      _navigationCompletedAt = DateTime.now();
    } else {
      debugPrint('NotificationNavigationService: Router not ready, storing pending route');
    }
  }

  /// Consume and return the pending route
  /// Returns null if no pending route or already consumed
  NotificationRoute? consumePendingRoute() {
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

  /// Map notification data to an app route with parent for back navigation
  ///
  /// Supports both:
  /// - Type-based mapping (type + target_id)
  /// - Direct deep link path (deep_link_path)
  ///
  /// Returns a NotificationRoute with:
  /// - parentRoute: The parent screen to navigate to first (for back button)
  /// - targetRoute: The actual target screen with fromNotification=true param
  NotificationRoute? _mapDeepLinkToRoute({
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
          return NotificationRoute(
            parentRoute: '/home?tab=0', // Feed tab
            targetRoute: '/post/$targetId?fromNotification=true',
          );
        }
        // Fallback to feed (no push needed)
        return NotificationRoute(
          parentRoute: '/home?tab=0',
          targetRoute: '/home?tab=0',
        );

      case 'message':
        if (targetId != null) {
          return NotificationRoute(
            parentRoute: '/home?tab=2', // Messages tab
            targetRoute: '/connections/conversation/$targetId?fromNotification=true',
          );
        }
        // Fallback to messages tab (no push needed)
        return NotificationRoute(
          parentRoute: '/home?tab=2',
          targetRoute: '/home?tab=2',
        );

      case 'connection':
        // Network tab - no separate screen to push
        return NotificationRoute(
          parentRoute: '/home?tab=3',
          targetRoute: '/home?tab=3',
        );

      default:
        debugPrint('NotificationNavigationService: Unknown notification type: $type');
        return NotificationRoute(
          parentRoute: '/home',
          targetRoute: '/home',
        );
    }
  }

  /// Map a deep link path to an app route with parent for back navigation
  ///
  /// Handles path normalization and tab-based routing for paths that
  /// should preserve the app shell (bottom navigation).
  NotificationRoute _mapPathToRoute(String path) {
    // Remove leading slash if present for consistent matching
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    // Posts - direct navigation with Feed as parent
    if (normalizedPath.startsWith('/post/')) {
      // Add fromNotification param if not already present
      final targetPath = normalizedPath.contains('?')
          ? '$normalizedPath&fromNotification=true'
          : '$normalizedPath?fromNotification=true';
      return NotificationRoute(
        parentRoute: '/home?tab=0', // Feed tab
        targetRoute: targetPath,
      );
    }

    // Conversations - direct navigation with Messages as parent
    if (normalizedPath.startsWith('/connections/conversation/')) {
      // Add fromNotification param if not already present
      final targetPath = normalizedPath.contains('?')
          ? '$normalizedPath&fromNotification=true'
          : '$normalizedPath?fromNotification=true';
      return NotificationRoute(
        parentRoute: '/home?tab=2', // Messages tab
        targetRoute: targetPath,
      );
    }

    // Tab-based routes (preserve app shell) - no separate push needed
    if (normalizedPath == '/feed' || normalizedPath.startsWith('/feed/')) {
      return NotificationRoute(
        parentRoute: '/home?tab=0',
        targetRoute: '/home?tab=0',
      );
    }
    if (normalizedPath == '/directory' || normalizedPath.startsWith('/directory/')) {
      return NotificationRoute(
        parentRoute: '/home?tab=1',
        targetRoute: '/home?tab=1',
      );
    }
    if (normalizedPath == '/messages') {
      return NotificationRoute(
        parentRoute: '/home?tab=2',
        targetRoute: '/home?tab=2',
      );
    }
    if (normalizedPath == '/connections') {
      return NotificationRoute(
        parentRoute: '/home?tab=3',
        targetRoute: '/home?tab=3',
      );
    }

    // Profile and settings - use home as parent
    if (normalizedPath.startsWith('/profile')) {
      return NotificationRoute(
        parentRoute: '/home',
        targetRoute: normalizedPath,
      );
    }
    if (normalizedPath.startsWith('/settings')) {
      return NotificationRoute(
        parentRoute: '/home',
        targetRoute: normalizedPath,
      );
    }

    // Default: use home as parent
    return NotificationRoute(
      parentRoute: '/home',
      targetRoute: normalizedPath,
    );
  }
}
