import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/follow_repository.dart';

/// Repository provider for follow operations
final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository();
});

/// Check if the current user follows a specific user
final isFollowingProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.isFollowing(userId);
});

/// Get follower count for a user (null if they opted out of showing it)
final followerCountProvider = FutureProvider.family<int?, String>((ref, userId) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getFollowerCount(userId);
});

/// Get follower count for the current user (always returns a count, bypasses privacy)
final ownFollowerCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getOwnFollowerCount();
});

/// Get the number of users that a user is following
final followingCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getFollowingCount(userId);
});
