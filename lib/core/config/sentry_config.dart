import 'package:flutter_dotenv/flutter_dotenv.dart';

class SentryConfig {
  static String get dsn => dotenv.env['SENTRY_DSN'] ?? '';
}
