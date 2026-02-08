import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group/group_models.dart';
import '../models/feed/feed_models.dart';

/// Repository for group operations
class GroupsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ============================================================
  // Group Queries
  // ============================================================

  /// Gets all visible groups with current user's membership status
  Future<List<Group>> getGroups() async {
    try {
      final response = await _supabase.rpc('get_groups_with_membership');
      return (response as List<dynamic>)
          .map((json) => Group.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch groups: ${e.message}');
    }
  }

  /// Gets groups the current user is a member of
  Future<List<Group>> getMyGroups() async {
    try {
      final response = await _supabase.rpc('get_groups_with_membership');
      return (response as List<dynamic>)
          .map((json) => Group.fromJson(json as Map<String, dynamic>))
          .where((g) => g.isMember)
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch my groups: ${e.message}');
    }
  }

  /// Gets a single group by ID with membership info
  Future<Group?> getGroupById(String groupId) async {
    try {
      final userId = _currentUserId;

      final response = await _supabase
          .from('groups')
          .select()
          .eq('id', groupId)
          .maybeSingle();

      if (response == null) return null;

      // Get membership info
      GroupMemberRole? currentUserRole;
      bool isMember = false;
      bool hasPendingRequest = false;

      if (userId != null) {
        final memberResponse = await _supabase
            .from('group_members')
            .select('role')
            .eq('group_id', groupId)
            .eq('user_id', userId)
            .maybeSingle();

        if (memberResponse != null) {
          isMember = true;
          currentUserRole = GroupMemberRole.fromString(memberResponse['role'] as String);
        } else {
          final requestResponse = await _supabase
              .from('group_join_requests')
              .select('status')
              .eq('group_id', groupId)
              .eq('user_id', userId)
              .eq('status', 'pending')
              .maybeSingle();
          hasPendingRequest = requestResponse != null;
        }
      }

      return Group.fromJson({
        ...response,
        'current_user_role': currentUserRole?.dbValue,
        'is_member': isMember,
        'has_pending_request': hasPendingRequest,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch group: ${e.message}');
    }
  }

  // ============================================================
  // Group Feed (reuses post infrastructure)
  // ============================================================

  /// Gets paginated posts for a specific group
  Future<List<Post>> getGroupFeedPosts({
    required String groupId,
    String? cursor,
    String? cursorId,
    String sort = 'new',
    int limit = 20,
    String? category,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_group_feed_posts',
        params: {
          'p_group_id': groupId,
          'p_cursor': cursor,
          'p_cursor_id': cursorId,
          'p_sort': sort,
          'p_limit': limit,
          'p_category': category,
        },
      );

      return (response as List<dynamic>)
          .map((json) => Post.fromFeedJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch group posts: ${e.message}');
    }
  }

  /// Gets pinned posts for a group
  Future<List<String>> getGroupPinnedPostIds(String groupId) async {
    try {
      final response = await _supabase
          .from('group_pinned_posts')
          .select('post_id')
          .eq('group_id', groupId)
          .order('pinned_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => json['post_id'] as String)
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch pinned posts: ${e.message}');
    }
  }

  // ============================================================
  // Group CRUD (admin only)
  // ============================================================

  /// Creates a new group (admin only - enforced by RLS)
  Future<Group> createGroup({
    required String name,
    required String slug,
    String? description,
    GroupVisibility visibility = GroupVisibility.public_,
    String? termsText,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User must be authenticated');

      final response = await _supabase
          .from('groups')
          .insert({
            'name': name,
            'slug': slug,
            if (description != null) 'description': description,
            'visibility': visibility.dbValue,
            'created_by': userId,
            if (termsText != null) 'terms_text': termsText,
          })
          .select()
          .single();

      final group = Group.fromJson({
        ...response,
        'is_member': false,
        'has_pending_request': false,
      });

      // Auto-add creator as group admin
      await _supabase.from('group_members').insert({
        'group_id': group.id,
        'user_id': userId,
        'role': 'admin',
        'accepted_terms_at': DateTime.now().toIso8601String(),
      });

      return group.copyWith(
        isMember: true,
        currentUserRole: GroupMemberRole.admin,
        memberCount: 1,
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to create group: ${e.message}');
    }
  }

  /// Updates a group's settings
  Future<Group> updateGroup({
    required String groupId,
    String? name,
    String? description,
    GroupVisibility? visibility,
    String? termsText,
    bool? isArchived,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (visibility != null) updates['visibility'] = visibility.dbValue;
      if (termsText != null) updates['terms_text'] = termsText;
      if (isArchived != null) updates['is_archived'] = isArchived;

      final response = await _supabase
          .from('groups')
          .update(updates)
          .eq('id', groupId)
          .select()
          .single();

      return Group.fromJson({
        ...response,
        'is_member': true,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to update group: ${e.message}');
    }
  }

  // ============================================================
  // Membership
  // ============================================================

  /// Joins a public group (with T&C acceptance)
  Future<void> joinGroup(String groupId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User must be authenticated');

      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
        'accepted_terms_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to join group: ${e.message}');
    }
  }

  /// Leaves a group
  Future<void> leaveGroup(String groupId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User must be authenticated');

      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to leave group: ${e.message}');
    }
  }

  /// Requests to join a request-to-join group
  Future<void> requestToJoin(String groupId, {String? message}) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User must be authenticated');

      await _supabase.from('group_join_requests').insert({
        'group_id': groupId,
        'user_id': userId,
        if (message != null) 'message': message,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to request to join: ${e.message}');
    }
  }

  /// Cancels a pending join request
  Future<void> cancelJoinRequest(String groupId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User must be authenticated');

      await _supabase
          .from('group_join_requests')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .eq('status', 'pending');
    } on PostgrestException catch (e) {
      throw Exception('Failed to cancel join request: ${e.message}');
    }
  }

  // ============================================================
  // Members Management
  // ============================================================

  /// Gets members of a group with profile data
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('''
            *,
            profile:user_id (
              username, first_name, last_name, avatar_url
            )
          ''')
          .eq('group_id', groupId)
          .order('role', ascending: true)
          .order('joined_at', ascending: true);

      return (response as List<dynamic>)
          .map((json) => GroupMember.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch group members: ${e.message}');
    }
  }

  /// Updates a member's role (admin only)
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupMemberRole role,
  }) async {
    try {
      await _supabase
          .from('group_members')
          .update({'role': role.dbValue})
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update member role: ${e.message}');
    }
  }

  /// Removes a member from a group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to remove member: ${e.message}');
    }
  }

  // ============================================================
  // Join Request Management
  // ============================================================

  /// Gets pending join requests for a group
  Future<List<GroupJoinRequest>> getPendingJoinRequests(String groupId) async {
    try {
      final response = await _supabase
          .from('group_join_requests')
          .select('''
            *,
            profile:user_id (
              username, first_name, last_name, avatar_url
            )
          ''')
          .eq('group_id', groupId)
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((json) => GroupJoinRequest.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch join requests: ${e.message}');
    }
  }

  /// Approves a join request and adds the user as a member
  Future<void> approveJoinRequest(String requestId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User must be authenticated');

      // Update the request status
      final requestResponse = await _supabase
          .from('group_join_requests')
          .update({
            'status': 'approved',
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      // Add user as member
      await _supabase.from('group_members').insert({
        'group_id': requestResponse['group_id'],
        'user_id': requestResponse['user_id'],
        'role': 'member',
        'accepted_terms_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to approve join request: ${e.message}');
    }
  }

  /// Rejects a join request
  Future<void> rejectJoinRequest(String requestId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User must be authenticated');

      await _supabase
          .from('group_join_requests')
          .update({
            'status': 'rejected',
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to reject join request: ${e.message}');
    }
  }

  // ============================================================
  // Pin Management
  // ============================================================

  /// Pins a post in a group
  Future<void> pinPost({required String groupId, required String postId}) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User must be authenticated');

      await _supabase.from('group_pinned_posts').insert({
        'group_id': groupId,
        'post_id': postId,
        'pinned_by': userId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to pin post: ${e.message}');
    }
  }

  /// Unpins a post from a group
  Future<void> unpinPost({required String groupId, required String postId}) async {
    try {
      await _supabase
          .from('group_pinned_posts')
          .delete()
          .eq('group_id', groupId)
          .eq('post_id', postId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to unpin post: ${e.message}');
    }
  }

  // ============================================================
  // Real-time Subscriptions (Broadcast)
  // ============================================================

  /// Subscribes to new posts in a group
  RealtimeChannel subscribeToGroupPosts({
    required String groupId,
    required void Function(String postId, String? authorId) onNewPost,
  }) {
    return _supabase
        .channel(
          'group:$groupId:posts',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: 'INSERT',
          callback: (payload) {
            try {
              final postId = payload['id'] as String;
              final authorId = payload['author_id'] as String?;
              onNewPost(postId, authorId);
            } catch (e) {
              debugPrint('Error parsing group post broadcast: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribes to member changes in a group
  RealtimeChannel subscribeToGroupMembers({
    required String groupId,
    required void Function(String userId, String event) onMemberChange,
  }) {
    return _supabase
        .channel(
          'group:$groupId:members',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: '*',
          callback: (payload) {
            try {
              final userId = payload['user_id'] as String;
              final event = payload['event'] as String? ?? 'unknown';
              onMemberChange(userId, event);
            } catch (e) {
              debugPrint('Error parsing member broadcast: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribes to join requests for a group (admin/mod)
  RealtimeChannel subscribeToJoinRequests({
    required String groupId,
    required void Function(String requestId) onNewRequest,
  }) {
    return _supabase
        .channel(
          'group:$groupId:requests',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: 'INSERT',
          callback: (payload) {
            try {
              final requestId = payload['id'] as String;
              onNewRequest(requestId);
            } catch (e) {
              debugPrint('Error parsing join request broadcast: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribes to user-level group notifications
  RealtimeChannel subscribeToGroupNotifications({
    required void Function(Map<String, dynamic> payload) onNotification,
  }) {
    final userId = _currentUserId;
    return _supabase
        .channel(
          'user:$userId:groups',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: '*',
          callback: (payload) {
            try {
              onNotification(payload);
            } catch (e) {
              debugPrint('Error parsing group notification broadcast: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribes to pin changes in a group
  RealtimeChannel subscribeToGroupPinChanges({
    required String groupId,
    required void Function() onPinChange,
  }) {
    return _supabase
        .channel(
          'group:$groupId:pinned',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: '*',
          callback: (_) {
            onPinChange();
          },
        )
        .subscribe();
  }

  /// Unsubscribes from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
