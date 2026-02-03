import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../core/config/revenuecat_config.dart';
import '../services/purchase_service.dart';

/// Repository for in-app purchase operations.
///
/// Encapsulates all RevenueCat SDK interactions following the
/// repository pattern used throughout the app.
class PurchaseRepository {
  void _ensureConfigured() {
    if (!PurchaseService.isConfigured) {
      throw Exception('RevenueCat SDK not configured');
    }
  }

  /// Get current customer info
  Future<CustomerInfo> getCustomerInfo() async {
    _ensureConfigured();
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      throw Exception('Failed to get customer info: $e');
    }
  }

  /// Check if user has active supporter entitlement
  Future<bool> hasActiveEntitlement() async {
    _ensureConfigured();
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement = info.entitlements.all[RevenueCatConfig.entitlementId];
      return entitlement?.isActive ?? false;
    } catch (e) {
      throw Exception('Failed to check entitlement: $e');
    }
  }

  /// Get available subscription offerings
  Future<Offerings> getOfferings() async {
    _ensureConfigured();
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      throw Exception('Failed to get offerings: $e');
    }
  }

  /// Get the current offering
  Future<Offering?> getCurrentOffering() async {
    _ensureConfigured();
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      throw Exception('Failed to get current offering: $e');
    }
  }

  /// Present the paywall modal
  /// Returns PaywallResult indicating what happened
  Future<PaywallResult> presentPaywall() async {
    _ensureConfigured();
    try {
      return await RevenueCatUI.presentPaywall();
    } catch (e) {
      throw Exception('Failed to present paywall: $e');
    }
  }

  /// Present paywall only if user doesn't have entitlement
  /// Returns PaywallResult (notPresented if user already has access)
  Future<PaywallResult> presentPaywallIfNeeded() async {
    _ensureConfigured();
    try {
      return await RevenueCatUI.presentPaywallIfNeeded(
        RevenueCatConfig.entitlementId,
      );
    } catch (e) {
      throw Exception('Failed to present paywall: $e');
    }
  }

  /// Present customer center for subscription management
  Future<void> presentCustomerCenter() async {
    _ensureConfigured();
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      throw Exception('Failed to present customer center: $e');
    }
  }

  /// Restore previous purchases
  Future<CustomerInfo> restorePurchases() async {
    _ensureConfigured();
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      throw Exception('Failed to restore purchases: $e');
    }
  }

  /// Log in user to RevenueCat
  Future<LogInResult> login(String userId) async {
    _ensureConfigured();
    try {
      return await Purchases.logIn(userId);
    } catch (e) {
      throw Exception('Failed to log in: $e');
    }
  }

  /// Log out user from RevenueCat
  Future<CustomerInfo> logout() async {
    _ensureConfigured();
    try {
      return await Purchases.logOut();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }
}
