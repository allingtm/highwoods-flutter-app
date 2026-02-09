import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/biometric_service.dart';
import 'auth_provider.dart';

/// Whether the device supports biometric login (hardware + enrolled).
final canOfferBiometricProvider = FutureProvider<bool>((ref) async {
  return await BiometricService.canOfferBiometricLogin();
});

/// Whether biometric login is currently enabled by the user.
final biometricEnabledProvider =
    StateNotifierProvider<BiometricEnabledNotifier, AsyncValue<bool>>(
  (ref) => BiometricEnabledNotifier(ref),
);

class BiometricEnabledNotifier extends StateNotifier<AsyncValue<bool>> {
  BiometricEnabledNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = AsyncValue.data(await BiometricService.isBiometricEnabled());
  }

  /// Enable biometric login: verify password, authenticate biometrics,
  /// then store credentials.
  ///
  /// Returns a message string: null on success, or an error description.
  Future<String?> enable({
    required String email,
    required String password,
  }) async {
    // Verify the password is correct before storing it
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (_) {
      return 'Incorrect password. Please try again.';
    }

    final authenticated = await BiometricService.authenticate(
      reason: 'Verify your identity to enable biometric login',
    );
    if (!authenticated) return 'Biometric authentication was cancelled.';

    await BiometricService.storeCredentials(email: email, password: password);
    await BiometricService.setBiometricEnabled(true);
    state = const AsyncValue.data(true);
    return null;
  }

  /// Disable biometric login and clear stored credentials.
  Future<void> disable() async {
    await BiometricService.disableBiometricLogin();
    state = const AsyncValue.data(false);
  }
}

/// Human-readable label for the biometric type ("Face ID", "Fingerprint", etc.).
final biometricLabelProvider = FutureProvider<String>((ref) async {
  return await BiometricService.getBiometricLabel();
});

/// Whether biometric login should be attempted on the login screen.
final shouldAttemptBiometricProvider = FutureProvider<bool>((ref) async {
  return await BiometricService.shouldAttemptBiometricLogin();
});

/// Holds credentials temporarily after a successful password login
/// so the HomeScreen can prompt for biometric enrollment.
final pendingBiometricEnrollmentProvider =
    StateProvider<({String email, String password})?>((_) => null);
