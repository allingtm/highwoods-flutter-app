import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/deep_link_handler.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/notification_navigation_service.dart';
import 'theme/app_color_palette.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: '.env');

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

  @override
  void initState() {
    super.initState();
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
                textColor: Colors.white,
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
