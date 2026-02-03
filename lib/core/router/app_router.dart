import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../screens/connections/messages_list_screen.dart';
import '../../screens/connections/conversation_screen.dart';
import '../../screens/directory/promo_detail_screen.dart';
import '../../screens/whatson/event_detail_screen.dart';
import '../../screens/settings_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_navigation_service.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    redirect: (context, state) {
      final isAuth = isAuthenticated;
      final location = state.matchedLocation;

      // CRITICAL: Check for pending notification route (cold start fallback)
      // This handles the case where a notification is tapped before the router
      // was registered, or the microtask navigation failed to win the race
      final pendingRoute =
          NotificationNavigationService.instance.consumePendingRoute();
      if (pendingRoute != null) {
        debugPrint(
            'Router redirect: Consuming pending notification route: $pendingRoute');
        return pendingRoute;
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
      // Invite deep link - redirect to register with code
      GoRoute(
        path: '/invite/:token',
        name: 'invite-link',
        redirect: (context, state) {
          final token = state.pathParameters['token'];
          final code = state.uri.queryParameters['code'];
          // Prefer the short code if available, otherwise use the token
          final inviteCode = code ?? token;
          return '/register?code=$inviteCode';
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
          return PostDetailScreen(postId: postId);
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
          return UserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
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
          return ConversationScreen(otherUserId: userId);
        },
      ),
      // Directory routes
      GoRoute(
        path: '/directory/promo/:promoId',
        name: 'promo-detail',
        builder: (context, state) {
          final promoId = state.pathParameters['promoId']!;
          return PromoDetailScreen(promoId: promoId);
        },
      ),
      // What's On routes
      GoRoute(
        path: '/whatson/event/:eventId',
        name: 'event-detail',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return EventDetailScreen(eventId: eventId);
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
