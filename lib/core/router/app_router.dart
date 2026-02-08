import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../models/post_category.dart';
import '../../screens/welcome_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/edit_profile_screen.dart';
import '../../screens/user_profile_screen.dart';
import '../../screens/auth/auth_callback_screen.dart';
import '../../screens/feed/feed_screen.dart';
import '../../screens/feed/post_detail_screen.dart';
import '../../screens/feed/create_post_screen.dart';
import '../../screens/feed/edit_post_screen.dart';
import '../../screens/feed/search_screen.dart';
import '../../screens/feed/saved_posts_screen.dart';
import '../../screens/connections/invite_screen.dart';
import '../../screens/connections/accept_invite_screen.dart';
import '../../screens/connections/messages_list_screen.dart';
import '../../screens/connections/conversation_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/settings/appearance_screen.dart';
import '../../screens/settings/notifications_screen.dart';
import '../../screens/settings/privacy_screen.dart';
import '../../screens/settings/subscription_screen.dart';
import '../../screens/settings/account_screen.dart';
import '../../screens/settings/about_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_navigation_service.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    observers: [SentryNavigatorObserver()],
    redirect: (context, state) {
      final isAuth = isAuthenticated;
      final location = state.matchedLocation;

      // CRITICAL: Check for pending notification route (cold start fallback)
      // This handles the case where a notification is tapped before the router
      // was registered, or the microtask navigation failed to win the race.
      // We PEEK (not consume) here so that registerRouter can still do the
      // full two-step navigation (go to parent, then push target).
      final pendingRoute =
          NotificationNavigationService.instance.peekPendingRoute();
      if (pendingRoute != null) {
        debugPrint(
            'Router redirect: Found pending notification route, redirecting to parent: ${pendingRoute.parentRoute}');
        // Return parent route - registerRouter will handle pushing target
        return pendingRoute.parentRoute;
      }

      final isGoingToAuth = location == '/login' ||
          location.startsWith('/register') ||
          location == '/';
      final isAuthCallback = location.startsWith('/auth/');
      final isInviteLink = location.startsWith('/invite/');

      // Public routes that don't require authentication
      // Note: /post/:id/edit is protected, so we check it's not an edit route
      final isEditRoute = location.endsWith('/edit');
      final isPublicRoute = (location == '/feed' ||
          location == '/search' ||
          location.startsWith('/post/') ||
          location.startsWith('/user/')) && !isEditRoute;

      // Allow auth callback routes and invite links without authentication
      if (isAuthCallback || isInviteLink) {
        return null;
      }

      // Allow public routes (feed, post details) for all users
      if (isPublicRoute) {
        return null;
      }

      // Default to feed if authenticated, welcome if not
      if (location == '' || location == '/') {
        if (isAuth) {
          return '/home';
        }
        return '/';
      }

      // Redirect to login for protected routes when not authenticated
      if (!isAuth && !isGoingToAuth) {
        return '/login';
      }

      // Redirect authenticated users away from auth pages
      if (isAuth && isGoingToAuth && location != '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) {
          // Read optional invite code from query parameter
          final inviteCode = state.uri.queryParameters['code'];
          return RegisterScreen(inviteCode: inviteCode);
        },
      ),
      // Invite deep link - route based on auth state
      GoRoute(
        path: '/invite/:token',
        name: 'invite-link',
        redirect: (context, state) {
          final token = state.pathParameters['token'];
          final code = state.uri.queryParameters['code'];
          final inviteCode = code ?? token;
          // Authenticated users accept the invite; others register with it
          if (isAuthenticated) {
            return '/accept-invite?code=$inviteCode';
          }
          return '/register?code=$inviteCode';
        },
      ),
      // Accept invite - for authenticated users accepting an invitation
      GoRoute(
        path: '/accept-invite',
        name: 'accept-invite',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return AcceptInviteScreen(code: code ?? '');
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          // Support tab query parameter for notification deep linking
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = tabStr != null ? int.tryParse(tabStr) ?? 0 : 0;
          return HomeScreen(initialTab: initialTab);
        },
      ),
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/post/:postId',
        name: 'post-detail',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          final fromNotification =
              state.uri.queryParameters['fromNotification'] == 'true';
          return PostDetailScreen(
            postId: postId,
            fromNotification: fromNotification,
          );
        },
      ),
      GoRoute(
        path: '/post/:postId/edit',
        name: 'edit-post',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return EditPostScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/create-post',
        name: 'create-post',
        builder: (context, state) {
          // Read optional category query parameter
          final categoryStr = state.uri.queryParameters['category'];
          final category = categoryStr != null
              ? PostCategory.fromString(categoryStr)
              : null;
          return CreatePostScreen(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/saved',
        name: 'saved-posts',
        builder: (context, state) => const SavedPostsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/user/:userId',
        name: 'user-profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final hideMessageButton = state.uri.queryParameters['fromConversation'] == 'true';
          return UserProfileScreen(userId: userId, hideMessageButton: hideMessageButton);
        },
      ),
      GoRoute(
        path: '/stats',
        name: 'stats',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/appearance',
        name: 'appearance',
        builder: (context, state) => const AppearanceScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/auth/confirm',
        name: 'auth-confirm',
        builder: (context, state) => const AuthCallbackScreen(type: 'confirm'),
      ),
      GoRoute(
        path: '/auth/magic-link',
        name: 'auth-magic-link',
        builder: (context, state) => const AuthCallbackScreen(type: 'magic-link'),
      ),
      // Connections routes
      GoRoute(
        path: '/connections/invite',
        name: 'invite',
        builder: (context, state) => const InviteScreen(),
      ),
      GoRoute(
        path: '/connections/messages',
        name: 'messages',
        builder: (context, state) => const MessagesListScreen(),
      ),
      GoRoute(
        path: '/connections/conversation/:userId',
        name: 'conversation',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final fromNotification =
              state.uri.queryParameters['fromNotification'] == 'true';
          return ConversationScreen(
            otherUserId: userId,
            fromNotification: fromNotification,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
