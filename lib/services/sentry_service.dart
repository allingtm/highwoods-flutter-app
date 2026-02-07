import 'package:sentry_flutter/sentry_flutter.dart';

/// Thin static wrapper for Sentry calls.
/// Keeps repositories and providers clean by centralizing metric names,
/// breadcrumb formatting, and error capture logic.
class SentryService {
  SentryService._();

  // ============================================================
  // User Context
  // ============================================================

  /// Set the Sentry user when auth state changes
  static void setUser({required String id, String? email, String? username}) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
        username: username,
      ));
    });
  }

  /// Clear user context on sign-out
  static void clearUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  // ============================================================
  // Error Capture
  // ============================================================

  /// Capture an error with optional context
  static Future<void> captureError(
    Object error,
    StackTrace? stackTrace, {
    String? operation,
    Map<String, dynamic>? extras,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (operation != null) {
          scope.setTag('operation', operation);
        }
        if (extras != null) {
          scope.setContexts('extras', extras);
        }
      },
    );
  }

  // ============================================================
  // Breadcrumbs
  // ============================================================

  /// Add a navigation/action breadcrumb
  static void addBreadcrumb(String message,
      {String? category, Map<String, dynamic>? data}) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category ?? 'app',
      data: data,
    ));
  }

  /// beforeBreadcrumb callback to strip sensitive data
  static Breadcrumb? beforeBreadcrumb(Breadcrumb? crumb, Hint hint) {
    if (crumb == null) return null;

    if (crumb.data != null) {
      for (final key in crumb.data!.keys.toList()) {
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains('email') ||
            lowerKey.contains('token') ||
            lowerKey.contains('password') ||
            lowerKey.contains('secret') ||
            lowerKey.contains('authorization')) {
          crumb.data![key] = '[REDACTED]';
        }
      }
    }

    return crumb;
  }

  // ============================================================
  // Custom Metrics
  // ============================================================

  static Map<String, SentryAttribute>? _toAttributes(
      Map<String, String>? tags) {
    if (tags == null) return null;
    return tags.map((k, v) => MapEntry(k, SentryAttribute.string(v)));
  }

  /// Count a business event
  static void countEvent(String name, {Map<String, String>? tags}) {
    Sentry.metrics.count(name, 1, attributes: _toAttributes(tags));
  }

  /// Record a latency distribution in milliseconds
  static void recordLatency(String name, double milliseconds,
      {Map<String, String>? tags}) {
    Sentry.metrics.distribution(name, milliseconds,
        unit: SentryMetricUnit.millisecond, attributes: _toAttributes(tags));
  }

  /// Record a gauge value
  static void recordGauge(String name, double value,
      {Map<String, String>? tags}) {
    Sentry.metrics.gauge(name, value, attributes: _toAttributes(tags));
  }

  // ============================================================
  // Performance Transactions
  // ============================================================

  /// Start a custom transaction for a key operation
  static ISentrySpan startTransaction(String name, String operation) {
    return Sentry.startTransaction(name, operation, bindToScope: true);
  }
}
