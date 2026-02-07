import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';
import '../services/sentry_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );

  if (user != null) {
    _tagUserForNotifications(user);
    SentryService.setUser(id: user.id, email: user.email);
  } else {
    SentryService.clearUser();
  }

  return user;
});

/// Tags the user in OneSignal and RevenueCat when they log in
void _tagUserForNotifications(User user) {
  // OneSignal tagging
  NotificationService.setExternalUserId(user.id);
  NotificationService.setUserTags(
    userId: user.id,
    email: user.email,
  );

  // RevenueCat user identification
  PurchaseService.login(user.id);
}

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Helper function to delete the current user's account
/// This permanently deletes all user data and cannot be undone
Future<void> deleteAccount(WidgetRef ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  await authRepo.deleteAccount();
}
