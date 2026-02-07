import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard/dashboard_models.dart';
import '../repositories/dashboard_repository.dart';

// ============================================================
// Repository Provider
// ============================================================

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

// ============================================================
// Community Stats Provider
// ============================================================

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) {
  return ref.read(dashboardRepositoryProvider).getDashboardStats();
});

// ============================================================
// User Stats Provider
// ============================================================

final userDashboardStatsProvider = FutureProvider.autoDispose<UserDashboardStats>((ref) {
  return ref.read(dashboardRepositoryProvider).getUserDashboardStats();
});

// ============================================================
// Mood Check-in Notifier
// ============================================================

class MoodCheckinNotifier extends StateNotifier<AsyncValue<MoodCounts?>> {
  final DashboardRepository _repository;

  MoodCheckinNotifier(this._repository) : super(const AsyncData(null));

  Future<void> submitMood(String mood) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.submitMoodCheckin(mood);
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final moodCheckinProvider =
    StateNotifierProvider.autoDispose<MoodCheckinNotifier, AsyncValue<MoodCounts?>>((ref) {
  return MoodCheckinNotifier(ref.read(dashboardRepositoryProvider));
});
