import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../core/config/revenuecat_config.dart';
import '../repositories/purchase_repository.dart';
import '../services/purchase_service.dart';
import 'auth_provider.dart';

/// Provider for PurchaseRepository singleton
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository();
});

/// StateNotifier for purchase state with real-time updates
class PurchaseStateNotifier extends StateNotifier<AsyncValue<CustomerInfo?>> {
  PurchaseStateNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _initialize();
  }

  final PurchaseRepository _repository;
  final String? _userId;

  void _initialize() {
    _loadCustomerInfo();
    PurchaseService.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);
  }

  Future<void> _loadCustomerInfo() async {
    if (_userId == null || !PurchaseService.isConfigured) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final info = await _repository.getCustomerInfo();
      state = AsyncValue.data(info);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void _onCustomerInfoUpdate(CustomerInfo info) {
    state = AsyncValue.data(info);
  }

  /// Present the paywall and refresh state after
  Future<PaywallResult> presentPaywall() async {
    final result = await _repository.presentPaywall();
    await _loadCustomerInfo();
    return result;
  }

  /// Present paywall only if needed
  Future<PaywallResult> presentPaywallIfNeeded() async {
    final result = await _repository.presentPaywallIfNeeded();
    await _loadCustomerInfo();
    return result;
  }

  /// Present customer center
  Future<void> presentCustomerCenter() async {
    await _repository.presentCustomerCenter();
    await _loadCustomerInfo();
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      final info = await _repository.restorePurchases();
      state = AsyncValue.data(info);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh customer info
  Future<void> refresh() async => _loadCustomerInfo();

  @override
  void dispose() {
    PurchaseService.removeCustomerInfoUpdateListener(_onCustomerInfoUpdate);
    super.dispose();
  }
}

/// StateNotifierProvider for purchase state management
final purchaseStateProvider =
    StateNotifierProvider<PurchaseStateNotifier, AsyncValue<CustomerInfo?>>(
        (ref) {
  final repository = ref.watch(purchaseRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return PurchaseStateNotifier(repository, user?.id);
});

/// Derived provider for quick entitlement check
final isSupporterProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(purchaseStateProvider);
  return customerInfo.maybeWhen(
    data: (info) =>
        info?.entitlements.active.containsKey(RevenueCatConfig.entitlementId) ??
        false,
    orElse: () => false,
  );
});
