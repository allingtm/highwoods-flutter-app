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
// Stage 2: Activity Timeline Provider
// ============================================================

final activityTimelineDaysProvider = StateProvider<int>((ref) => 7);

final activityTimelineProvider = FutureProvider.autoDispose<List<ActivityDay>>((ref) {
  final days = ref.watch(activityTimelineDaysProvider);
  return ref.read(dashboardRepositoryProvider).getActivityTimeline(days: days);
});

// ============================================================
// Stage 2: Category Breakdown Provider
// ============================================================

final categoryBreakdownProvider = FutureProvider.autoDispose<List<CategoryBreakdown>>((ref) {
  return ref.read(dashboardRepositoryProvider).getCategoryBreakdown();
});

// ============================================================
// Stage 2: AI Insights Provider
// ============================================================

final latestInsightProvider = FutureProvider.autoDispose<AiInsight?>((ref) {
  return ref.read(dashboardRepositoryProvider).getLatestInsight();
});

// ============================================================
// Daily Activity & Badge Progress Providers
// ============================================================

final dailyActivityProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.read(dashboardRepositoryProvider).recordDailyActivity();
});

final badgeProgressProvider = FutureProvider.autoDispose<BadgeProgress>((ref) {
  return ref.read(dashboardRepositoryProvider).getBadgeProgress();
});

// ============================================================
// Stage 3: User Badges Provider
// ============================================================

final userBadgesProvider = FutureProvider.autoDispose<List<UserBadge>>((ref) {
  return ref.read(dashboardRepositoryProvider).getUserBadges();
});

// ============================================================
// Stage 3: Personal Wrapped Provider
// ============================================================

final personalWrappedProvider = FutureProvider.autoDispose<PersonalWrapped>((ref) {
  return ref.read(dashboardRepositoryProvider).getPersonalWrapped();
});

// ============================================================
// Stage 4: Neighbourhood Goals Provider
// ============================================================

final activeGoalsProvider = FutureProvider.autoDispose<List<NeighbourhoodGoal>>((ref) {
  return ref.read(dashboardRepositoryProvider).getActiveGoals();
});
