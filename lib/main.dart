import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/notification_navigation_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  @override
  void initState() {
    super.initState();
    // Listen for foreground notifications to show as snackbar
    NotificationNavigationService.instance.addListener(_onForegroundNotification);

    // Register router after first frame (when router is available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerRouter();
    });
  }

  @override
  void dispose() {
    NotificationNavigationService.instance.removeListener(_onForegroundNotification);
    super.dispose();
  }

  /// Register the router with NotificationNavigationService for cold start support
  void _registerRouter() {
    final router = ref.read(goRouterProvider);
    NotificationNavigationService.instance.registerRouter(() => router);
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
        backgroundColor: AppColors.brandPrimary,
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
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Highwoods',
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
