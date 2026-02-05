import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_category.dart';
import '../models/post_type.dart';
import '../models/feed/feed_models.dart';
import '../repositories/feed_repository.dart';
import 'auth_provider.dart';

// ============================================================
// Repository Provider
// ============================================================

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

// ============================================================
// Post Cache Provider - Single Source of Truth
// ============================================================

/// Shared cache for individual post states.
/// Both feed list and detail views read from and write to this cache,
/// ensuring consistent state across all views.
class PostCacheNotifier extends StateNotifier<Map<String, Post>> {
  PostCacheNotifier() : super({});

  /// Cache a single post
  void cachePost(Post post) {
    state = {...state, post.id: post};
  }

  /// Cache multiple posts (e.g., when loading feed)
  void cachePosts(List<Post> posts) {
    final newState = Map<String, Post>.from(state);
    for (final post in posts) {
      newState[post.id] = post;
    }
    state = newState;
  }

  /// Get a post from cache (non-reactive)
  Post? getPost(String postId) => state[postId];

  /// Update a post in the cache
  void updatePost(Post post) {
    state = {...state, post.id: post};
  }

  /// Remove a post from cache
  void removePost(String postId) {
    state = Map<String, Post>.from(state)..remove(postId);
  }

  /// Clear the entire cache
  void clear() {
    state = {};
  }
}

final postCacheProvider = StateNotifierProvider<PostCacheNotifier, Map<String, Post>>(
  (ref) => PostCacheNotifier(),
);

/// Get a single post from cache (reactive - rebuilds when post changes)
final cachedPostProvider = Provider.family<Post?, String>((ref, postId) {
  final cache = ref.watch(postCacheProvider);
  return cache[postId];
});

// ============================================================
// Filter State
// ============================================================

/// Currently selected category filter (null = all categories)
final selectedCategoryProvider = StateProvider<PostCategory?>((ref) => null);

// ============================================================
// Feed Posts Provider
// ============================================================

/// Paginated feed posts with category filtering
class FeedPostsNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  FeedPostsNotifier(this._ref, this._repository, this._category)
      : super(const AsyncValue.loading()) {
    loadInitial();
  }

  final Ref _ref;
  final FeedRepository _repository;
  final PostCategory? _category;
  String? _cursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    _cursor = null;
    _hasMore = true;

    try {
      final posts = await _repository.getFeedPosts(
        category: _category,
        limit: 20,
      );

      _hasMore = posts.length >= 20;
      if (posts.isNotEmpty) {
        _cursor = posts.last.createdAt.toIso8601String();
      }

      // Cache all posts for shared access across views
      _ref.read(postCacheProvider.notifier).cachePosts(posts);

      state = AsyncValue.data(posts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    final currentPosts = state.valueOrNull ?? [];
    _isLoadingMore = true;

    try {
      final newPosts = await _repository.getFeedPosts(
        category: _category,
        cursor: _cursor,
        limit: 20,
      );

      _hasMore = newPosts.length >= 20;
      if (newPosts.isNotEmpty) {
        _cursor = newPosts.last.createdAt.toIso8601String();
      }

      // Cache new posts
      _ref.read(postCacheProvider.notifier).cachePosts(newPosts);

      state = AsyncValue.data([...currentPosts, ...newPosts]);
    } catch (error, stackTrace) {
      // Keep existing posts on error, just log it
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  /// Add a new post to the top of the list (for real-time updates)
  void prependPost(Post post) {
    final currentPosts = state.valueOrNull ?? [];
    // Don't add if already exists
    if (currentPosts.any((p) => p.id == post.id)) return;
    // Check category filter
    if (_category != null && post.category != _category) return;

    state = AsyncValue.data([post, ...currentPosts]);
  }

  /// Update a post in the list (e.g., after reaction/save toggle)
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

final feedPostsNotifierProvider =
    StateNotifierProvider<FeedPostsNotifier, AsyncValue<List<Post>>>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  return FeedPostsNotifier(ref, repository, category);
});

// ============================================================
// Active Alerts Provider
// ============================================================

/// Active sticky alerts for the urgent banner
final activeAlertsProvider = FutureProvider<List<Post>>((ref) async {
  final repository = ref.watch(feedRepositoryProvider);
  return repository.getActiveAlerts();
});

// ============================================================
// Single Post Provider
// ============================================================

/// Get a single post by ID
final postDetailProvider = FutureProvider.family<Post?, String>((ref, postId) async {
  final repository = ref.watch(feedRepositoryProvider);
  return repository.getPostById(postId);
});

// ============================================================
// Post Comments Provider
// ============================================================

/// Comments for a specific post
final postCommentsProvider = FutureProvider.family<List<PostComment>, String>((ref, postId) async {
  final repository = ref.watch(feedRepositoryProvider);
  return repository.getComments(postId);
});

// ============================================================
// Post Reaction Counts Provider
// ============================================================

/// Per-type reaction counts for a specific post (lazy-loaded when bottom sheet opens)
final postReactionCountsProvider = FutureProvider.family<Map<String, int>, String>((ref, postId) async {
  final repository = ref.watch(feedRepositoryProvider);
  return repository.getReactionCounts(postId);
});

// ============================================================
// User Posts Provider
// ============================================================

/// Current user's own posts
final userPostsProvider = FutureProvider<List<Post>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(feedRepositoryProvider);
  return repository.getUserPosts(user.id);
});

/// Saved posts for current user
final savedPostsProvider = FutureProvider<List<Post>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(feedRepositoryProvider);
  return repository.getSavedPosts();
});

// ============================================================
// Public User Profile Content Providers
// ============================================================

/// Posts by a specific user (for public profile)
/// Merges fetched posts with cached data to ensure latest reaction state is shown
final userPostsByIdProvider = FutureProvider.family<List<Post>, String>((ref, userId) async {
  final repository = ref.watch(feedRepositoryProvider);
  final posts = await repository.getUserPosts(userId);

  // Merge with cache to get latest reaction state
  final cache = ref.read(postCacheProvider);
  return posts.map((post) {
    final cachedPost = cache[post.id];
    if (cachedPost != null) {
      // Use cached reaction state (more up-to-date)
      return post.copyWith(
        userReaction: cachedPost.userReaction,
        reactionCount: cachedPost.reactionCount,
        isSaved: cachedPost.isSaved,
      );
    }
    return post;
  }).toList();
});

/// Comments by a specific user (for public profile)
final userCommentsByIdProvider = FutureProvider.family<List<PostComment>, String>((ref, userId) async {
  final repository = ref.watch(feedRepositoryProvider);
  return repository.getUserComments(userId);
});

/// Posts liked/reacted to by a specific user (for public profile)
/// Merges fetched posts with cached data to ensure latest reaction state is shown
final userLikedPostsProvider = FutureProvider.family<List<Post>, String>((ref, userId) async {
  final repository = ref.watch(feedRepositoryProvider);
  final posts = await repository.getUserLikedPosts(userId);

  // Merge with cache to get latest reaction state
  final cache = ref.read(postCacheProvider);
  return posts.map((post) {
    final cachedPost = cache[post.id];
    if (cachedPost != null) {
      // Use cached reaction state (more up-to-date)
      return post.copyWith(
        userReaction: cachedPost.userReaction,
        reactionCount: cachedPost.reactionCount,
        isSaved: cachedPost.isSaved,
      );
    }
    return post;
  }).toList();
});

// ============================================================
// Feed Actions Notifier
// ============================================================

/// Notifier for feed mutations (create, react, comment, save, etc.)
class FeedActionsNotifier extends StateNotifier<AsyncValue<void>> {
  FeedActionsNotifier(this._ref, this._repository)
      : super(const AsyncValue.data(null));

  final Ref _ref;
  final FeedRepository _repository;

  /// Toggle reaction on a post
  ///
  /// Uses the post cache as the source of truth to ensure consistent state.
  Future<void> toggleReaction({
    required String postId,
    required String reactionType,
  }) async {
    // Get current post from cache (always has latest state)
    final post = _ref.read(postCacheProvider)[postId];
    if (post == null) return;

    try {
      final hadExistingReaction = post.userReaction != null;
      final wasAdded = await _repository.toggleReaction(
        postId: postId,
        reactionType: reactionType,
      );

      // Calculate new reaction count:
      // - If adding new (no reaction, wasAdded=true): count + 1
      // - If removing (clicked same type, wasAdded=false): count - 1
      // - If switching types (had reaction, wasAdded=true): count stays same
      int newCount = post.reactionCount;
      if (wasAdded && !hadExistingReaction) {
        newCount = post.reactionCount + 1;
      } else if (!wasAdded) {
        newCount = post.reactionCount > 0 ? post.reactionCount - 1 : 0;
      }
      // If switching (hadExistingReaction && wasAdded), count stays the same

      final updatedPost = post.copyWith(
        userReaction: wasAdded ? reactionType : null,
        reactionCount: newCount,
      );

      // Update cache first (single source of truth)
      _ref.read(postCacheProvider.notifier).updatePost(updatedPost);

      // Also update feed list state
      _ref.read(feedPostsNotifierProvider.notifier).updatePost(updatedPost);

      // Invalidate reaction counts so bottom sheet shows fresh data
      _ref.invalidate(postReactionCountsProvider(postId));

      // Invalidate profile providers so they refresh when viewed
      _ref.invalidate(userLikedPostsProvider);
      _ref.invalidate(userPostsByIdProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Toggle save/bookmark on a post
  Future<void> toggleSave(Post post) async {
    try {
      final isSaved = await _repository.toggleSave(post.id);

      // Update the post
      final updatedPost = post.copyWith(isSaved: isSaved);

      // Update cache first (single source of truth)
      _ref.read(postCacheProvider.notifier).updatePost(updatedPost);

      // Also update feed list state
      _ref.read(feedPostsNotifierProvider.notifier).updatePost(updatedPost);

      // Invalidate saved posts list
      _ref.invalidate(savedPostsProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Add a comment to a post
  Future<PostComment> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    try {
      final comment = await _repository.addComment(
        postId: postId,
        content: content,
        parentId: parentId,
      );

      // Invalidate comments list for this post
      _ref.invalidate(postCommentsProvider(postId));

      return comment;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    try {
      await _repository.deleteComment(commentId);

      // Invalidate comments list for this post
      _ref.invalidate(postCommentsProvider(postId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Toggle RSVP for an event
  Future<void> toggleRsvp({
    required String postId,
    required String status,
  }) async {
    try {
      await _repository.toggleRsvp(
        postId: postId,
        status: status,
      );

      // Invalidate post detail to refresh RSVP state
      _ref.invalidate(postDetailProvider(postId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Create a new post
  Future<Post> createPost({
    required PostCategory category,
    required PostType postType,
    String? title,
    String? content,
    MarketplaceDetails? marketplaceDetails,
    EventDetails? eventDetails,
    AlertDetails? alertDetails,
    LostFoundDetails? lostFoundDetails,
    JobDetails? jobDetails,
    RecommendationDetails? recommendationDetails,
    List<File>? imageFiles,
    File? videoFile,
    int? videoDurationSeconds,
  }) async {
    try {
      // Create the post first
      final post = await _repository.createPost(
        category: category,
        postType: postType,
        title: title,
        content: content,
        marketplaceDetails: marketplaceDetails,
        eventDetails: eventDetails,
        alertDetails: alertDetails,
        lostFoundDetails: lostFoundDetails,
        jobDetails: jobDetails,
        recommendationDetails: recommendationDetails,
      );

      // Upload images if provided (mutually exclusive with video)
      List<PostImage>? uploadedImages;
      if (imageFiles != null && imageFiles.isNotEmpty) {
        uploadedImages = await _repository.uploadPostImages(
          postId: post.id,
          files: imageFiles,
        );
      }

      // Upload video if provided (mutually exclusive with images)
      PostVideo? uploadedVideo;
      if (videoFile != null) {
        uploadedVideo = await _repository.uploadPostVideo(
          postId: post.id,
          file: videoFile,
          durationSeconds: videoDurationSeconds,
        );
      }

      // Build the updated post with media
      var postWithMedia = post;
      if (uploadedImages != null) {
        postWithMedia = postWithMedia.copyWith(
          images: uploadedImages,
          primaryImageUrl: uploadedImages.isNotEmpty ? uploadedImages.first.url : null,
        );
      }
      if (uploadedVideo != null) {
        postWithMedia = postWithMedia.copyWith(
          video: uploadedVideo,
          videoStatus: uploadedVideo.status.dbValue,
        );
      }

      // Add to feed
      _ref.read(feedPostsNotifierProvider.notifier).prependPost(postWithMedia);

      // Invalidate user posts
      _ref.invalidate(userPostsProvider);

      // Start polling for video processing in the background
      if (uploadedVideo != null) {
        _pollVideoProcessing(post.id, uploadedVideo.streamVideoUid);
      }

      return postWithMedia;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Polls for video processing completion in the background
  void _pollVideoProcessing(String postId, String videoUid) async {
    const pollInterval = Duration(seconds: 5);
    const maxAttempts = 24; // 2 minutes max polling

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollInterval);

      try {
        final updatedVideo = await _repository.pollVideoStatus(postId, videoUid);

        if (updatedVideo.status == VideoStatus.ready ||
            updatedVideo.status == VideoStatus.error) {
          // Update the post in the cache with the final video state
          final cachedPost = _ref.read(postCacheProvider)[postId];
          if (cachedPost != null) {
            final updatedPost = cachedPost.copyWith(
              video: updatedVideo,
              videoThumbnailUrl: updatedVideo.thumbnailUrl,
              videoPlaybackUrl: updatedVideo.playbackUrl,
              videoStatus: updatedVideo.status.dbValue,
            );
            _ref.read(postCacheProvider.notifier).updatePost(updatedPost);
            _ref.read(feedPostsNotifierProvider.notifier).updatePost(updatedPost);
          }
          return; // Stop polling
        }
      } catch (_) {
        // Silently continue polling on error
      }
    }
  }

  /// Delete a video from a post
  Future<void> deletePostVideo({
    required String videoId,
    required String streamVideoUid,
    required String postId,
  }) async {
    try {
      await _repository.deletePostVideo(videoId, streamVideoUid);

      // Update the post in the cache
      final cachedPost = _ref.read(postCacheProvider)[postId];
      if (cachedPost != null) {
        final updatedPost = cachedPost.copyWith(
          video: null,
          videoThumbnailUrl: null,
          videoPlaybackUrl: null,
          videoStatus: null,
        );
        _ref.read(postCacheProvider.notifier).updatePost(updatedPost);
        _ref.read(feedPostsNotifierProvider.notifier).updatePost(updatedPost);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update a post
  Future<Post> updatePost({
    required String postId,
    String? title,
    String? content,
    String? status,
    String? locationText,
    MarketplaceDetails? marketplaceDetails,
    EventDetails? eventDetails,
    AlertDetails? alertDetails,
    LostFoundDetails? lostFoundDetails,
    JobDetails? jobDetails,
    RecommendationDetails? recommendationDetails,
  }) async {
    try {
      final updatedPost = await _repository.updatePost(
        postId: postId,
        title: title,
        content: content,
        status: status,
        locationText: locationText,
        marketplaceDetails: marketplaceDetails,
        eventDetails: eventDetails,
        alertDetails: alertDetails,
        lostFoundDetails: lostFoundDetails,
        jobDetails: jobDetails,
        recommendationDetails: recommendationDetails,
      );

      // Update in feed
      _ref.read(feedPostsNotifierProvider.notifier).updatePost(updatedPost);

      // Invalidate related providers
      _ref.invalidate(postDetailProvider(postId));
      _ref.invalidate(userPostsProvider);

      return updatedPost;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update post status (convenience method)
  Future<Post> updatePostStatus({
    required String postId,
    required String status,
  }) async {
    return updatePost(postId: postId, status: status);
  }

  /// Delete a post (soft delete)
  Future<void> deletePost(String postId) async {
    try {
      await _repository.deletePost(postId);

      // Remove from feed
      _ref.read(feedPostsNotifierProvider.notifier).removePost(postId);

      // Invalidate user posts
      _ref.invalidate(userPostsProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Report a post
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    try {
      await _repository.reportPost(
        postId: postId,
        reason: reason,
        details: details,
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final feedActionsProvider =
    StateNotifierProvider<FeedActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return FeedActionsNotifier(ref, repository);
});

// ============================================================
// Search Provider
// ============================================================

/// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search category filter (optional)
final searchCategoryProvider = StateProvider<PostCategory?>((ref) => null);

/// Search results with debouncing
final searchResultsProvider = FutureProvider<List<Post>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(searchCategoryProvider);

  // Don't search if query is too short
  if (query.trim().length < 2) {
    return [];
  }

  final repository = ref.watch(feedRepositoryProvider);
  return repository.searchPosts(
    query: query,
    category: category,
  );
});

// ============================================================
// Event Attendees Provider
// ============================================================

/// Get attendees for a specific event
final eventAttendeesProvider = FutureProvider.family<List<EventRsvp>, String>((ref, postId) async {
  final repository = ref.watch(feedRepositoryProvider);
  return repository.getEventAttendees(postId);
});
