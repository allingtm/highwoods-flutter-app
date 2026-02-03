import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../core/config/revenuecat_config.dart';

/// Service for managing in-app purchases via RevenueCat.
///
/// This service handles SDK initialization and provides static methods
/// for common purchase operations. Initialize once in main.dart before runApp.
class PurchaseService {
  PurchaseService._();

  static bool _isConfigured = false;

  /// Whether the RevenueCat SDK has been configured
  static bool get isConfigured => _isConfigured;

  /// Initialize RevenueCat SDK - call in main.dart before runApp
  static Future<void> initialize() async {
    final apiKey = RevenueCatConfig.apiKey;
    if (apiKey.isEmpty) {
      debugPrint('PurchaseService: API key not configured - skipping initialization');
      return;
    }

    // Enable debug logs in debug mode
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    // Configure the SDK
    final configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);
    _isConfigured = true;

    debugPrint('PurchaseService: Initialized successfully');
  }

  /// Link user to RevenueCat on login
  /// Call this after user authenticates with Supabase
  static Future<void> login(String userId) async {
    if (!_isConfigured) return;
    try {
      await Purchases.logIn(userId);
      debugPrint('PurchaseService: User logged in: $userId');
    } catch (e) {
      debugPrint('PurchaseService: Failed to log in user: $e');
    }
  }

  /// Clear user data on logout
  static Future<void> logout() async {
    if (!_isConfigured) return;
    try {
      await Purchases.logOut();
      debugPrint('PurchaseService: User logged out');
    } catch (e) {
      debugPrint('PurchaseService: Failed to log out: $e');
    }
  }

  /// Add listener for customer info updates
  static void addCustomerInfoUpdateListener(
    void Function(CustomerInfo) listener,
  ) {
    if (!_isConfigured) return;
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// Remove customer info update listener
  static void removeCustomerInfoUpdateListener(
    void Function(CustomerInfo) listener,
  ) {
    if (!_isConfigured) return;
    Purchases.removeCustomerInfoUpdateListener(listener);
  }
}
