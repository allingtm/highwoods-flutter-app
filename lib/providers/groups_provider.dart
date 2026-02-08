import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group/group_models.dart';
import '../models/feed/feed_models.dart';
import '../repositories/groups_repository.dart';
import 'feed_provider.dart';

// ============================================================
// Repository Provider
// ============================================================

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository();
});

// ============================================================
// All Groups Provider (for discovery/browse)
// ============================================================

class AllGroupsNotifier extends StateNotifier<AsyncValue<List<Group>>> {
  AllGroupsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final GroupsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final groups = await _repository.getGroups();
      if (!mounted) return;
      state = AsyncValue.data(groups);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async => load();

  /// Update a group in the list (e.g., after joining/leaving)
  void updateGroup(Group updatedGroup) {
    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((g) => g.id == updatedGroup.id);
    if (index == -1) return;
    final newList = [...current];
    newList[index] = updatedGroup;
    state = AsyncValue.data(newList);
  }
}

final allGroupsProvider =
    StateNotifierProvider<AllGroupsNotifier, AsyncValue<List<Group>>>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return AllGroupsNotifier(repository);
});

// ============================================================
// My Groups Provider
// ============================================================

final myGroupsProvider = FutureProvider<List<Group>>((ref) async {
  final repository = ref.watch(groupsRepositoryProvider);
  return repository.getMyGroups();
});

// ============================================================
// Single Group Detail Provider
// ============================================================

final groupDetailProvider =
    FutureProvider.autoDispose.family<Group?, String>((ref, groupId) async {
  final repository = ref.watch(groupsRepositoryProvider);
  return repository.getGroupById(groupId);
});

// ============================================================
// Group Feed Provider (per group, mirrors FeedPostsNotifier)
// ============================================================

class GroupFeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  GroupFeedNotifier(this._ref, this._repository, this._groupId)
      : super(const AsyncValue.loading()) {
    loadInitial();
  }

  final Ref _ref;
  final GroupsRepository _repository;
  final String _groupId;
  String? _cursor;
  String? _cursorId;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    _cursor = null;
    _cursorId = null;
    _hasMore = true;

    try {
      final posts = await _repository.getGroupFeedPosts(
        groupId: _groupId,
        sort: 'new',
        limit: 20,
      );

      if (!mounted) return;

      _hasMore = posts.length >= 20;
      if (posts.isNotEmpty) {
        _cursor = posts.last.createdAt.toIso8601String();
      }

      // Cache all posts for shared access
      _ref.read(postCacheProvider.notifier).cachePosts(posts);

      state = AsyncValue.data(posts);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    final currentPosts = state.valueOrNull ?? [];
    _isLoadingMore = true;

    try {
      final newPosts = await _repository.getGroupFeedPosts(
        groupId: _groupId,
        cursor: _cursor,
        cursorId: _cursorId,
        sort: 'new',
        limit: 20,
      );

      if (!mounted) return;

      _hasMore = newPosts.length >= 20;
      if (newPosts.isNotEmpty) {
        _cursor = newPosts.last.createdAt.toIso8601String();
      }

      _ref.read(postCacheProvider.notifier).cachePosts(newPosts);

      state = AsyncValue.data([...currentPosts, ...newPosts]);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async => loadInitial();

  /// Add a new post to the top
  void prependPost(Post post) {
    final currentPosts = state.valueOrNull ?? [];
    if (currentPosts.any((p) => p.id == post.id)) return;
    state = AsyncValue.data([post, ...currentPosts]);
  }

  /// Update a post in the list
  void updatePost(Post updatedPost) {
    final currentPosts = state.valueOrNull ?? [];
    final index = currentPosts.indexWhere((p) => p.id == updatedPost.id);
    if (index == -1) return;
    final newPosts = [...currentPosts];
    newPosts[index] = updatedPost;
    state = AsyncValue.data(newPosts);
  }

  /// Remove a post from the list
  void removePost(String postId) {
    final currentPosts = state.valueOrNull ?? [];
    state = AsyncValue.data(
      currentPosts.where((p) => p.id != postId).toList(),
    );
  }
}

final groupFeedProvider = StateNotifierProvider.autoDispose
    .family<GroupFeedNotifier, AsyncValue<List<Post>>, String>(
  (ref, groupId) {
    final repository = ref.watch(groupsRepositoryProvider);
    return GroupFeedNotifier(ref, repository, groupId);
  },
);

// ============================================================
// Group Pinned Posts Provider
// ============================================================

final groupPinnedPostsProvider =
    FutureProvider.autoDispose.family<List<Post>, String>(
  (ref, groupId) async {
    final repository = ref.watch(groupsRepositoryProvider);
    final pinnedIds = await repository.getGroupPinnedPostIds(groupId);
    if (pinnedIds.isEmpty) return [];
    final cache = ref.read(postCacheProvider);
    return pinnedIds
        .where((id) => cache.containsKey(id))
        .map((id) => cache[id]!)
        .toList();
  },
);

// ============================================================
// Group Members Provider
// ============================================================

final groupMembersProvider =
    FutureProvider.autoDispose.family<List<GroupMember>, String>(
  (ref, groupId) async {
    final repository = ref.watch(groupsRepositoryProvider);
    return repository.getGroupMembers(groupId);
  },
);

// ============================================================
// Pending Join Requests Provider (admin/mod)
// ============================================================

final pendingJoinRequestsProvider =
    FutureProvider.autoDispose.family<List<GroupJoinRequest>, String>(
  (ref, groupId) async {
    final repository = ref.watch(groupsRepositoryProvider);
    return repository.getPendingJoinRequests(groupId);
  },
);

// ============================================================
// Group Actions Notifier
// ============================================================

class GroupActionsNotifier extends StateNotifier<AsyncValue<void>> {
  GroupActionsNotifier(this._ref, this._repository)
      : super(const AsyncValue.data(null));

  final Ref _ref;
  final GroupsRepository _repository;

  /// Join a public group
  Future<void> joinGroup(String groupId) async {
    try {
      await _repository.joinGroup(groupId);
      _ref.invalidate(allGroupsProvider);
      _ref.invalidate(myGroupsProvider);
      _ref.invalidate(groupDetailProvider(groupId));
      _ref.invalidate(groupMembersProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    try {
      await _repository.leaveGroup(groupId);
      _ref.invalidate(allGroupsProvider);
      _ref.invalidate(myGroupsProvider);
      _ref.invalidate(groupDetailProvider(groupId));
      _ref.invalidate(groupMembersProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Request to join a group
  Future<void> requestToJoin(String groupId, {String? message}) async {
    try {
      await _repository.requestToJoin(groupId, message: message);
      _ref.invalidate(allGroupsProvider);
      _ref.invalidate(groupDetailProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Cancel a pending join request
  Future<void> cancelJoinRequest(String groupId) async {
    try {
      await _repository.cancelJoinRequest(groupId);
      _ref.invalidate(allGroupsProvider);
      _ref.invalidate(groupDetailProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update a member's role
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupMemberRole role,
  }) async {
    try {
      await _repository.updateMemberRole(
        groupId: groupId,
        userId: userId,
        role: role,
      );
      _ref.invalidate(groupMembersProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Remove a member from a group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _repository.removeMember(groupId: groupId, userId: userId);
      _ref.invalidate(groupMembersProvider(groupId));
      _ref.invalidate(groupDetailProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Approve a join request
  Future<void> approveJoinRequest({
    required String requestId,
    required String groupId,
  }) async {
    try {
      await _repository.approveJoinRequest(requestId);
      _ref.invalidate(pendingJoinRequestsProvider(groupId));
      _ref.invalidate(groupMembersProvider(groupId));
      _ref.invalidate(groupDetailProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Reject a join request
  Future<void> rejectJoinRequest({
    required String requestId,
    required String groupId,
  }) async {
    try {
      await _repository.rejectJoinRequest(requestId);
      _ref.invalidate(pendingJoinRequestsProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Pin a post in a group
  Future<void> pinPost({
    required String groupId,
    required String postId,
  }) async {
    try {
      await _repository.pinPost(groupId: groupId, postId: postId);
      // Refresh group feed and pinned posts to reflect pin status
      _ref.invalidate(groupFeedProvider(groupId));
      _ref.invalidate(groupPinnedPostsProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Unpin a post from a group
  Future<void> unpinPost({
    required String groupId,
    required String postId,
  }) async {
    try {
      await _repository.unpinPost(groupId: groupId, postId: postId);
      _ref.invalidate(groupFeedProvider(groupId));
      _ref.invalidate(groupPinnedPostsProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Create a new group (admin only)
  Future<Group> createGroup({
    required String name,
    required String slug,
    String? description,
    GroupVisibility visibility = GroupVisibility.public_,
    String? termsText,
  }) async {
    try {
      final group = await _repository.createGroup(
        name: name,
        slug: slug,
        description: description,
        visibility: visibility,
        termsText: termsText,
      );
      _ref.invalidate(allGroupsProvider);
      _ref.invalidate(myGroupsProvider);
      return group;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update a group's settings (admin only)
  Future<void> updateGroupSettings({
    required String groupId,
    String? name,
    String? description,
    GroupVisibility? visibility,
    String? termsText,
  }) async {
    try {
      await _repository.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        visibility: visibility,
        termsText: termsText,
      );
      _ref.invalidate(allGroupsProvider);
      _ref.invalidate(groupDetailProvider(groupId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final groupActionsProvider =
    StateNotifierProvider<GroupActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GroupActionsNotifier(ref, repository);
});

// ============================================================
// Groups Realtime Manager
// ============================================================

class GroupsRealtimeManager {
  GroupsRealtimeManager(this._ref, this._repository);

  final Ref _ref;
  final GroupsRepository _repository;

  // Per-group channels
  final Map<String, RealtimeChannel> _postChannels = {};
  final Map<String, RealtimeChannel> _memberChannels = {};
  final Map<String, RealtimeChannel> _pinChannels = {};
  final Map<String, RealtimeChannel> _requestChannels = {};

  // User-level channel
  RealtimeChannel? _userGroupsChannel;
  bool _isSubscribed = false;

  // New posts count per group (for badges)
  final Map<String, int> _newPostsCounts = {};
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  int getNewPostsCount(String groupId) => _newPostsCounts[groupId] ?? 0;
  int get totalNewPostsCount => _newPostsCounts.values.fold(0, (sum, c) => sum + c);

  // Callback for when the current user is removed from a group
  void Function(String groupId)? _onCurrentUserRemoved;
  void setOnCurrentUserRemoved(void Function(String groupId)? cb) =>
      _onCurrentUserRemoved = cb;

  void resetNewPostsCount(String groupId) {
    _newPostsCounts[groupId] = 0;
    _notifyListeners();
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Called on app init (in HomeScreen.initState)
  void subscribeAll() {
    if (_isSubscribed) return;
    _isSubscribed = true;
    _subscribeToUserGroupNotifications();
  }

  /// Subscribe to user-level group notifications (request approved, etc.)
  void _subscribeToUserGroupNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _userGroupsChannel = _repository.subscribeToGroupNotifications(
      onNotification: (payload) {
        final status = payload['status'] as String?;
        if (status == 'approved') {
          _ref.invalidate(myGroupsProvider);
          _ref.invalidate(allGroupsProvider);
        }
      },
    );
  }

  /// Subscribe to a specific group's real-time updates
  /// Called when entering GroupDetailScreen
  void subscribeToGroup(String groupId) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Subscribe to posts channel
    if (!_postChannels.containsKey(groupId)) {
      _postChannels[groupId] = _repository.subscribeToGroupPosts(
        groupId: groupId,
        onNewPost: (postId, authorId) {
          if (authorId == currentUserId) return;
          _newPostsCounts[groupId] = (_newPostsCounts[groupId] ?? 0) + 1;
          _notifyListeners();
        },
      );
    }

    // Subscribe to member changes
    if (!_memberChannels.containsKey(groupId)) {
      _memberChannels[groupId] = _repository.subscribeToGroupMembers(
        groupId: groupId,
        onMemberChange: (userId, event) {
          _ref.invalidate(groupMembersProvider(groupId));
          _ref.invalidate(groupDetailProvider(groupId));

          // Check if the current user was removed (kicked)
          if (event == 'left') {
            final currentUserId =
                Supabase.instance.client.auth.currentUser?.id;
            if (currentUserId != null && userId == currentUserId) {
              _onCurrentUserRemoved?.call(groupId);
            }
          }
        },
      );
    }

    // Subscribe to pin changes
    if (!_pinChannels.containsKey(groupId)) {
      _pinChannels[groupId] = _repository.subscribeToGroupPinChanges(
        groupId: groupId,
        onPinChange: () {
          _ref.invalidate(groupFeedProvider(groupId));
          _ref.invalidate(groupPinnedPostsProvider(groupId));
        },
      );
    }
  }

  /// Subscribe to join request channel (for admin/mod of group)
  void subscribeToRequests(String groupId) {
    if (!_requestChannels.containsKey(groupId)) {
      _requestChannels[groupId] = _repository.subscribeToJoinRequests(
        groupId: groupId,
        onNewRequest: (requestId) {
          _ref.invalidate(pendingJoinRequestsProvider(groupId));
        },
      );
    }
  }

  /// Unsubscribe from a group's updates
  void unsubscribeFromGroup(String groupId) {
    if (_postChannels.containsKey(groupId)) {
      _repository.unsubscribe(_postChannels[groupId]!);
      _postChannels.remove(groupId);
    }
    if (_memberChannels.containsKey(groupId)) {
      _repository.unsubscribe(_memberChannels[groupId]!);
      _memberChannels.remove(groupId);
    }
    if (_pinChannels.containsKey(groupId)) {
      _repository.unsubscribe(_pinChannels[groupId]!);
      _pinChannels.remove(groupId);
    }
    if (_requestChannels.containsKey(groupId)) {
      _repository.unsubscribe(_requestChannels[groupId]!);
      _requestChannels.remove(groupId);
    }
    _newPostsCounts.remove(groupId);
  }

  Future<void> dispose() async {
    _isSubscribed = false;

    if (_userGroupsChannel != null) {
      await _repository.unsubscribe(_userGroupsChannel!);
      _userGroupsChannel = null;
    }

    for (final channel in _postChannels.values) {
      await _repository.unsubscribe(channel);
    }
    _postChannels.clear();

    for (final channel in _memberChannels.values) {
      await _repository.unsubscribe(channel);
    }
    _memberChannels.clear();

    for (final channel in _pinChannels.values) {
      await _repository.unsubscribe(channel);
    }
    _pinChannels.clear();

    for (final channel in _requestChannels.values) {
      await _repository.unsubscribe(channel);
    }
    _requestChannels.clear();

    _newPostsCounts.clear();
    _listeners.clear();
  }
}

final groupsRealtimeProvider = Provider<GroupsRealtimeManager>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  final manager = GroupsRealtimeManager(ref, repository);
  ref.onDispose(() => manager.dispose());
  return manager;
});
