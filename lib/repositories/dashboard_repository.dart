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

  /// Submits a mood check-in and returns today's aggregated mood counts.
  Future<MoodCounts> submitMoodCheckin(String mood) async {
    final response = await _supabase.rpc(
      'submit_mood_checkin',
      params: {'p_mood': mood},
    );
    return MoodCounts.fromJson(response as Map<String, dynamic>);
  }

  /// Fetches personal dashboard stats for the current user.
  Future<UserDashboardStats> getUserDashboardStats() async {
    final response = await _supabase.rpc('get_user_dashboard_stats');
    return UserDashboardStats.fromJson(response as Map<String, dynamic>);
  }
}
