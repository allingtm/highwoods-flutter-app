import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for biometric authentication and secure credential storage.
///
/// Uses platform biometrics (Face ID, fingerprint) to guard access to
/// encrypted credentials stored in iOS Keychain / Android EncryptedSharedPreferences.
class BiometricService {
  BiometricService._();

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _biometricEnabledKey = 'biometric_login_enabled';
  static const String _emailKey = 'biometric_email';
  static const String _passwordKey = 'biometric_password';

  // ─── Device Capability ──────────────────────────────────────────

  /// Whether the device hardware supports biometric authentication.
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('BiometricService: isDeviceSupported error: $e');
      return false;
    }
  }

  /// Returns available biometric types (face, fingerprint, etc.).
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('BiometricService: getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Returns a human-readable label: "Face ID", "Fingerprint", or "Biometrics".
  ///
  /// Falls back to platform defaults when [getAvailableBiometrics] returns
  /// empty (e.g. iOS Face ID permission not yet granted).
  static Future<String> getBiometricLabel() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    // getAvailableBiometrics() can return [] on iOS when Face ID permission
    // hasn't been granted yet. Fall back to a sensible platform default.
    if (Platform.isIOS) return 'Face ID';
    if (Platform.isAndroid) return 'Fingerprint';
    return 'Biometrics';
  }

  /// Whether biometric login can be offered.
  ///
  /// Only checks hardware support via [isDeviceSupported]. We intentionally
  /// don't gate on [hasEnrolledBiometrics] because on iOS,
  /// `getAvailableBiometrics()` returns empty until the app has been granted
  /// Face ID permission — which only happens when [authenticate] is called.
  static Future<bool> canOfferBiometricLogin() async {
    return isDeviceSupported();
  }

  // ─── Biometric Prompt ───────────────────────────────────────────

  /// Prompts the user for biometric authentication.
  static Future<bool> authenticate({
    String reason = 'Sign in to Highwoods',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService: authenticate error: $e');
      return false;
    }
  }

  // ─── Credential Storage ─────────────────────────────────────────

  /// Stores encrypted credentials after a successful password login.
  static Future<void> storeCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _emailKey, value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  /// Retrieves stored credentials. Returns null if not found.
  static Future<({String email, String password})?> getCredentials() async {
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);
    if (email != null && password != null) {
      return (email: email, password: password);
    }
    return null;
  }

  /// Clears stored credentials from secure storage.
  static Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  // ─── Biometric Preference ──────────────────────────────────────

  /// Whether biometric login is enabled by the user.
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('BiometricService: isBiometricEnabled error: $e');
      return false;
    }
  }

  /// Sets the biometric-enabled preference.
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Whether biometric login should be attempted on the login screen.
  /// Requires: enabled + device support + stored credentials.
  static Future<bool> shouldAttemptBiometricLogin() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return false;
    final canOffer = await canOfferBiometricLogin();
    if (!canOffer) return false;
    final credentials = await getCredentials();
    return credentials != null;
  }

  /// Full disable: clears both preference and stored credentials.
  static Future<void> disableBiometricLogin() async {
    await setBiometricEnabled(false);
    await clearCredentials();
  }
}
