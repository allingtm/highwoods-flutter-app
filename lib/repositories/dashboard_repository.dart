import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard/dashboard_models.dart';

/// Repository for dashboard data operations.
class DashboardRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches all community dashboard stats in one RPC call.
  Future<DashboardStats> getDashboardStats() async {
    final response = await _supabase.rpc('get_dashboard_stats');
    return DashboardStats.fromJson(response as Map<String, dynamic>);
  }

  /// Fetches personal dashboard stats for the current user.
  Future<UserDashboardStats> getUserDashboardStats() async {
    final response = await _supabase.rpc('get_user_dashboard_stats');
    return UserDashboardStats.fromJson(response as Map<String, dynamic>);
  }

  // ============================================================
  // Stage 2: Charts & Content
  // ============================================================

  /// Fetches activity timeline data (posts, comments, reactions by day).
  Future<List<ActivityDay>> getActivityTimeline({int days = 7}) async {
    final response = await _supabase.rpc(
      'get_activity_timeline',
      params: {'p_days': days},
    );
    return (response as List<dynamic>)
        .map((e) => ActivityDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches category breakdown comparing current vs previous period.
  Future<List<CategoryBreakdown>> getCategoryBreakdown({int days = 7}) async {
    final response = await _supabase.rpc(
      'get_category_breakdown',
      params: {'p_days': days},
    );
    return (response as List<dynamic>)
        .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the latest valid AI insight.
  Future<AiInsight?> getLatestInsight() async {
    final response = await _supabase.rpc('get_latest_insight');
    if (response == null) return null;
    return AiInsight.fromJson(response as Map<String, dynamic>);
  }

  // ============================================================
  // Stage 3: Retention Engine
  // ============================================================

  /// Fetches all badges for the current user.
  Future<List<UserBadge>> getUserBadges() async {
    final response = await _supabase.rpc('get_user_badges');
    return (response as List<dynamic>)
        .map((e) => UserBadge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Checks and awards any newly earned badges.
  Future<List<String>> checkAndAwardBadges() async {
    final response = await _supabase.rpc('check_and_award_badges');
    final data = response as Map<String, dynamic>;
    return (data['new_badges'] as List<dynamic>).cast<String>();
  }

  /// Records daily activity: updates streak and checks for new badges.
  Future<List<String>> recordDailyActivity() async {
    final response = await _supabase.rpc('record_daily_activity');
    final data = response as Map<String, dynamic>;
    return (data['new_badges'] as List<dynamic>).cast<String>();
  }

  /// Fetches badge progress counts for the current user.
  Future<BadgeProgress> getBadgeProgress() async {
    final response = await _supabase.rpc('get_badge_progress');
    return BadgeProgress.fromJson(response as Map<String, dynamic>);
  }

  /// Fetches personal wrapped/monthly summary data.
  Future<PersonalWrapped> getPersonalWrapped({int? month, int? year}) async {
    final response = await _supabase.rpc(
      'get_personal_wrapped',
      params: {
        if (month != null) 'p_month': month,
        if (year != null) 'p_year': year,
      },
    );
    return PersonalWrapped.fromJson(response as Map<String, dynamic>);
  }

  // ============================================================
  // Stage 4: Social Layer
  // ============================================================

  /// Fetches active neighbourhood goals.
  Future<List<NeighbourhoodGoal>> getActiveGoals() async {
    final response = await _supabase.rpc('get_active_goals');
    return (response as List<dynamic>)
        .map((e) => NeighbourhoodGoal.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
