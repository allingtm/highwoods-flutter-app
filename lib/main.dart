import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/sentry_config.dart';
import 'core/config/supabase_config.dart';
import 'core/deep_link_handler.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/notification_navigation_service.dart';
import 'services/sentry_service.dart';
import 'theme/app_color_palette.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Must be called before SentryFlutter.init for frame tracking
  SentryWidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: '.env');
  await SentryConfig.initialize();

  await SentryFlutter.init(
    (options) {
      options.dsn = SentryConfig.dsn;
      options.release = SentryConfig.release;
      options.environment = SentryConfig.environment;
      options.tracesSampleRate = SentryConfig.isProduction ? 0.3 : 1.0;
      options.profilesSampleRate = SentryConfig.isProduction ? 0.3 : 1.0;
      options.captureFailedRequests = true;
      options.beforeBreadcrumb = SentryService.beforeBreadcrumb;
    },
    appRunner: () async {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      // Initialize push notifications (OneSignal)
      await NotificationService.initialize();

      // Initialize in-app purchases (RevenueCat)
      await PurchaseService.initialize();

      runApp(const ProviderScope(child: MainApp()));
    },
  );
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  /// Key for showing snackbars from outside the widget tree
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Deep link handler for app links
  DeepLinkHandler? _deepLinkHandler;

  /// Listens for passwordRecovery events from the SDK's automatic deep link
  /// handling. The supabase_flutter SDK intercepts auth deep links via
  /// app_links and calls getSessionFromUrl() internally, firing the
  /// passwordRecovery event. This global listener catches it and navigates
  /// to the reset password screen.
  StreamSubscription<AuthState>? _authRecoverySubscription;

  @override
  void initState() {
    super.initState();

    // Listen for password recovery events globally.
    // Must be set up early (before the SDK processes the deep link) so we
    // catch the passwordRecovery event that fires during code exchange.
    _authRecoverySubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(goRouterProvider).go('/auth/reset-password');
        });
      }
    });

    // Listen for foreground notifications to show as snackbar
    NotificationNavigationService.instance
        .addListener(_onForegroundNotification);

    // Register router after first frame (when router is available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerRouterAndDeepLinks();
    });
  }

  @override
  void dispose() {
    _authRecoverySubscription?.cancel();
    NotificationNavigationService.instance
        .removeListener(_onForegroundNotification);
    _deepLinkHandler?.dispose();
    super.dispose();
  }

  /// Register the router with NotificationNavigationService and init deep link handler
  void _registerRouterAndDeepLinks() {
    // Register router getter FIRST - this enables notification navigation
    // IMPORTANT: Pass a function that reads the router fresh each time, because
    // the router can be recreated when auth state changes (due to ref.watch)
    NotificationNavigationService.instance
        .registerRouter(() => ref.read(goRouterProvider));

    // Then init deep link handler - this listens for app links
    // IMPORTANT: Must be after router registration so notification navigation
    // takes priority over app links (prevents race condition)
    final router = ref.read(goRouterProvider);
    _deepLinkHandler = DeepLinkHandler(router);
    _deepLinkHandler!.init();
  }

  /// Show foreground notification as in-app snackbar
  void _onForegroundNotification() {
    final notification =
        NotificationNavigationService.instance.consumeForegroundNotification();
    if (notification == null) return;

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.primary,
        action: notification.additionalData != null
            ? SnackBarAction(
                label: 'View',
                textColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: () {
                  NotificationNavigationService.instance
                      .handleNotificationClick(notification.additionalData);
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final theme = ref.watch(themeDataProvider);

    return GestureDetector(
      // Dismiss keyboard when tapping anywhere outside text fields
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context).clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.3,
          ),
        ),
        child: MaterialApp.router(
          title: 'Highwoods',
          scaffoldMessengerKey: _scaffoldMessengerKey,
          theme: theme,
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeInOut,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
