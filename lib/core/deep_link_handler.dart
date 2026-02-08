import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_navigation_service.dart';

/// Handler for deep links into the Highwoods app
class DeepLinkHandler {
  final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkHandler(this._router);

  /// Initialize deep link handling
  Future<void> init() async {
    // Handle initial link if app was launched from a deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        // Skip if a notification navigation is pending OR just completed (within 3 seconds)
        // This prevents AppLinks from overriding notification navigation
        if (NotificationNavigationService.instance.shouldSkipSplashNavigation) {
          debugPrint(
              'DeepLinkHandler: Skipping initial link - notification navigation pending/recent');
        } else {
          await _handleDeepLink(initialUri);
        }
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }

    // Listen for links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        // Also check for pending/recent notification navigation on stream events
        if (NotificationNavigationService.instance.shouldSkipSplashNavigation) {
          debugPrint(
              'DeepLinkHandler: Skipping stream link - notification navigation pending/recent');
          return;
        }
        _handleDeepLink(uri);
      },
      onError: (e) => debugPrint('Deep link error: $e'),
    );
  }

  /// Clean up resources
  void dispose() {
    _linkSubscription?.cancel();
  }

  /// Process incoming deep link
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('Received deep link: $uri');

    final path = uri.path;
    final pathSegments = uri.pathSegments;

    // For custom schemes like highwoods://path, the first part after ://
    // is interpreted as the host, not a path segment.
    // For https URLs like https://app.highwoods.co.uk/path -> pathSegments=['path', ...]

    if (uri.scheme == 'highwoods') {
      // Custom scheme handling (if needed in future)
      switch (uri.host) {
        case 'auth':
          // Auth callback: highwoods://auth/callback
          if (pathSegments.isNotEmpty && pathSegments[0] == 'callback') {
            await _handleAuthCallback(uri);
          }
          break;

        default:
          // Unknown host - navigate to home
          debugPrint('Unknown deep link host: ${uri.host}');
          _router.go('/home');
      }
    } else {
      // HTTPS app links: use path segments
      if (pathSegments.isNotEmpty) {
        switch (pathSegments[0]) {
          case 'auth':
            // Auth callback routes: /auth/confirm, /auth/magic-link
            if (pathSegments.length >= 2) {
              final authType = pathSegments[1];
              if (authType == 'confirm' || authType == 'magic-link' || authType == 'reset-password') {
                _router.go('/auth/$authType');
              } else if (authType == 'callback') {
                await _handleAuthCallback(uri);
              }
            }
            break;

          case 'post':
            // Post deep links: /post/{postId}
            if (pathSegments.length >= 2) {
              final postId = pathSegments[1];
              _router.go('/post/$postId');
            } else {
              _router.go('/home');
            }
            break;

          case 'invite':
            // Invitation deep links: /invite/{token}
            if (pathSegments.length >= 2) {
              final token = pathSegments[1];
              final code = uri.queryParameters['code'];
              final inviteCode = code ?? token;
              // Authenticated users accept the invite; others register with it
              final currentUser = Supabase.instance.client.auth.currentUser;
              if (currentUser != null) {
                _router.go('/accept-invite?code=$inviteCode');
              } else {
                _router.go('/register?code=$inviteCode');
              }
            }
            break;

          case 'connections':
            // Connections: /connections/conversation/{userId}
            if (pathSegments.length >= 3 && pathSegments[1] == 'conversation') {
              final userId = pathSegments[2];
              _router.go('/connections/conversation/$userId');
            } else if (pathSegments.length >= 2 &&
                pathSegments[1] == 'messages') {
              _router.go('/home?tab=2'); // Messages tab
            } else {
              _router.go('/home?tab=3'); // Network tab
            }
            break;

          case 'messages':
            // Messages tab
            _router.go('/home?tab=2');
            break;

          case 'dashboard':
            // Dashboard tab
            _router.go('/home?tab=1');
            break;

          case 'feed':
            // Feed tab
            _router.go('/home?tab=0');
            break;

          case 'profile':
            _router.go('/profile');
            break;

          case 'settings':
            // Settings was split into individual screens; default to appearance
            _router.go('/appearance');
            break;

          case 'home':
            // Home with optional tab
            final tab = uri.queryParameters['tab'] ?? '0';
            _router.go('/home?tab=$tab');
            break;

          default:
            // Unknown path - navigate to home
            debugPrint('Unknown deep link path: $path');
            _router.go('/home');
        }
      } else {
        // No path - go home
        _router.go('/home');
      }
    }
  }

  /// Handle auth callback from magic link
  Future<void> _handleAuthCallback(Uri uri) async {
    debugPrint('Auth callback received: $uri');

    try {
      // The magic link contains tokens in the fragment (after #)
      // Format: highwoods://auth/callback#access_token=...&refresh_token=...&type=...
      final fragment = uri.fragment;

      if (fragment.isNotEmpty) {
        // Parse the fragment as query parameters
        final params = Uri.splitQueryString(fragment);
        final refreshToken = params['refresh_token'];

        if (refreshToken != null) {
          debugPrint('Setting session from magic link tokens');
          await Supabase.instance.client.auth.setSession(refreshToken);
          debugPrint('Session set successfully');
        }
      }

      // Navigate to home - the auth state listener will handle the rest
      _router.go('/home');
    } catch (e) {
      debugPrint('Error handling auth callback: $e');
      // Still navigate to home even if there's an error
      _router.go('/home');
    }
  }
}
