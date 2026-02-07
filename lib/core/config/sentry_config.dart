import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SentryConfig {
  static String get dsn => dotenv.env['SENTRY_DSN'] ?? '';
  static String get environment =>
      dotenv.env['SENTRY_ENVIRONMENT'] ?? 'development';
  static bool get isProduction => environment == 'production';

  static String _release = '';
  static String get release => _release;

  /// Call once during app startup to resolve package info
  static Future<void> initialize() async {
    final info = await PackageInfo.fromPlatform();
    _release = '${info.packageName}@${info.version}+${info.buildNumber}';
  }
}
