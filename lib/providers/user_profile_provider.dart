import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';
import 'auth_provider.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return null;
  }

  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getUserProfile(user.id);
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  UserProfileNotifier(this._authRepository, this._userId) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  final AuthRepository _authRepository;
  final String? _userId;

  Future<void> _loadProfile() async {
    if (_userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final profile = await _authRepository.getUserProfile(_userId);
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bio,
    bool? allowOpenMessaging,
  }) async {
    if (_userId == null) return;

    try {
      await _authRepository.updateUserProfile(
        userId: _userId,
        username: username,
        firstName: firstName,
        lastName: lastName,
        avatarUrl: avatarUrl,
        bio: bio,
        allowOpenMessaging: allowOpenMessaging,
      );
      await _loadProfile();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateMessagingPrivacy(bool allowOpenMessaging) async {
    await updateProfile(allowOpenMessaging: allowOpenMessaging);
  }

  Future<void> refresh() async {
    await _loadProfile();
  }
}

final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return UserProfileNotifier(authRepository, user?.id);
});
