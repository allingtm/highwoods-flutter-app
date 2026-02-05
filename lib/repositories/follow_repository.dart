import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for follow/unfollow operations
class FollowRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Toggles follow status for a user
  /// Returns true if now following, false if unfollowed
  Future<bool> toggleFollow(String userId) async {
    try {
      final response = await _supabase.rpc(
        'toggle_follow',
        params: {'p_user_id': userId},
      );
      return response as bool;
    } on PostgrestException catch (e) {
      throw Exception('Failed to toggle follow: ${e.message}');
    }
  }

  /// Checks if the current user is following a specific user
  Future<bool> isFollowing(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', currentUserId)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check follow status: ${e.message}');
    }
  }

  /// Gets follower count for a user
  /// Returns null if the user has opted out of showing follower count
  Future<int?> getFollowerCount(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('follower_count, show_follower_count')
          .eq('id', userId)
          .single();

      final showCount = response['show_follower_count'] as bool? ?? false;
      if (!showCount) return null;

      return response['follower_count'] as int? ?? 0;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get follower count: ${e.message}');
    }
  }
}
