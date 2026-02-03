import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for RevenueCat in-app purchases.
///
/// API key is loaded from environment variables.
/// Entitlement ID matches RevenueCat dashboard configuration.
class RevenueCatConfig {
  /// RevenueCat API key from environment
  static String get apiKey => dotenv.env['REVENUECAT_API_KEY'] ?? '';

  /// Entitlement identifier for premium features
  static const String entitlementId = 'Highwoods Supporter';

  /// Product identifiers
  static const String monthlyProductId = 'monthly';
  static const String yearlyProductId = 'yearly';
}
