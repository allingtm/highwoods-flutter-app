import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;

import '../models/post_category.dart';
import '../models/post_type.dart';
import '../models/feed/feed_models.dart';
import '../services/r2_storage_service.dart';
import '../services/cloudflare_stream_service.dart';

/// Exception thrown when image validation fails
class ImageValidationException implements Exception {
  final String message;
  ImageValidationException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when video validation fails
class VideoValidationException implements Exception {
  final String message;
  VideoValidationException(this.message);

  @override
  String toString() => message;
}

/// Repository for community feed operations
class FeedRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // Feed Queries
  // ============================================================

  /// Gets paginated feed posts using cursor-based pagination
  /// [sort] can be 'new' (chronological) or 'active' (by last comment activity)
  Future<List<Post>> getFeedPosts({
    PostCategory? category,
    String? cursor,
    String? cursorId,
    String sort = 'new',
    int limit = 20,
    bool followingOnly = false,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_feed_posts',
        params: {
          'p_category': category?.dbValue,
          'p_cursor': cursor,
          'p_cursor_id': cursorId,
          'p_sort': sort,
          'p_limit': limit,
          'p_following_only': followingOnly,
        },
      );

      final posts = (response as List<dynamic>)
          .map((json) => Post.fromFeedJson(json as Map<String, dynamic>))
          .toList();

      return posts;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch feed: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch feed: $e');
    }
  }

  /// Searches posts using full-text search
  /// Returns posts matching the query, optionally filtered by category
  Future<List<Post>> searchPosts({
    required String query,
    PostCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Don't search if query is too short
      if (query.trim().length < 2) {
        return [];
      }

      final response = await _supabase.rpc(
        'search_posts',
        params: {
          'p_query': query.trim(),
          'p_category': category?.dbValue,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      return (response as List<dynamic>)
          .map((json) => Post.fromFeedJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to search posts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  /// Gets active sticky alerts for the urgent banner
  Future<List<Post>> getActiveAlerts() async {
    try {
      final response = await _supabase
          .from('active_alerts_view')
          .select()
          .order('alert_priority', ascending: false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Post.fromFeedJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch alerts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch alerts: $e');
    }
  }

  /// Gets a single post by ID with full details
  Future<Post?> getPostById(String postId) async {
    try {
      // Get base post data from view
      final postResponse = await _supabase
          .from('feed_posts_view')
          .select()
          .eq('id', postId)
          .maybeSingle();

      if (postResponse == null) return null;

      // Get user's reaction and saved state
      final userId = _supabase.auth.currentUser?.id;
      String? userReaction;
      bool isSaved = false;

      if (userId != null) {
        final reactionResponse = await _supabase
            .from('post_reactions')
            .select('reaction_type')
            .eq('post_id', postId)
            .eq('user_id', userId)
            .maybeSingle();
        userReaction = reactionResponse?['reaction_type'] as String?;

        final savedResponse = await _supabase
            .from('saved_posts')
            .select('id')
            .eq('post_id', postId)
            .eq('user_id', userId)
            .maybeSingle();
        isSaved = savedResponse != null;
      }

      // Merge user state into post data
      final postData = Map<String, dynamic>.from(postResponse);
      postData['user_reaction'] = userReaction;
      postData['is_saved'] = isSaved;

      final post = Post.fromFeedJson(postData);

      // Get images
      final imagesResponse = await _supabase
          .from('post_images')
          .select()
          .eq('post_id', postId)
          .order('display_order');

      final images = (imagesResponse as List<dynamic>)
          .map((json) => PostImage.fromJson(json as Map<String, dynamic>))
          .toList();

      return post.copyWith(images: images);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch post: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }

  /// Gets the number of posts by a user
  Future<int> getPostCount(String userId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select()
          .eq('author_id', userId)
          .neq('status', 'removed');

      return (response as List).length;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get post count: ${e.message}');
    }
  }

  /// Gets user's own posts
  Future<List<Post>> getUserPosts(String userId) async {
    try {
      final response = await _supabase
          .from('feed_posts_view')
          .select()
          .eq('author_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Post.fromFeedJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user posts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  /// Gets comments made by a specific user
  Future<List<PostComment>> getUserComments(String userId) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('''
            *,
            profiles:author_id (
              username,
              first_name,
              last_name,
              avatar_url
            ),
            posts:post_id (
              id,
              title,
              body
            )
          ''')
          .eq('author_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>).map((json) {
        final profile = json['profiles'] as Map<String, dynamic>?;
        final post = json['posts'] as Map<String, dynamic>?;
        final data = Map<String, dynamic>.from(json);

        // Map database column names to model field names
        data['user_id'] = data['author_id'];
        data['content'] = data['body'];

        if (profile != null) {
          final username = profile['username'] as String?;
          final firstName = profile['first_name'] as String?;
          final lastName = profile['last_name'] as String?;
          final fullName = [firstName, lastName]
              .where((s) => s != null && s.isNotEmpty)
              .join(' ');
          data['author_name'] = fullName.isNotEmpty ? fullName : username;
          data['author_username'] = username;
          data['author_avatar_url'] = profile['avatar_url'];
        }

        // Include post info for context
        if (post != null) {
          data['post_title'] = post['title'];
          data['post_body'] = post['body'];
        }

        return PostComment.fromJson(data);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user comments: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch user comments: $e');
    }
  }

  /// Gets posts that a specific user has reacted to (liked)
  Future<List<Post>> getUserLikedPosts(String userId) async {
    try {
      final response = await _supabase
          .from('post_reactions')
          .select('post_id, posts:feed_posts_view!inner(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Post.fromFeedJson(json['posts'] as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch liked posts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch liked posts: $e');
    }
  }

  /// Gets user's saved posts
  Future<List<Post>> getSavedPosts() async {
    try {
      final response = await _supabase
          .from('saved_posts')
          .select('post_id, posts:feed_posts_view!inner(*)')
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Post.fromFeedJson(json['posts'] as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch saved posts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch saved posts: $e');
    }
  }

  // ============================================================
  // Post CRUD
  // ============================================================

  /// Creates a new post with optional type-specific details
  /// Note: Images should be uploaded separately using uploadPostImages()
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
    String? groupId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to create a post');
      }

      // Insert main post
      final postResponse = await _supabase
          .from('posts')
          .insert({
            'author_id': userId,
            'category': category.dbValue,
            'post_type': postType.dbValue,
            if (title != null) 'title': title,
            'body': content,
            'status': 'active',
            if (groupId != null) 'group_id': groupId,
          })
          .select()
          .single();

      final postId = postResponse['id'] as String;

      // Insert type-specific details
      if (marketplaceDetails != null) {
        await _supabase.from('marketplace_details').insert({
          'post_id': postId,
          ...marketplaceDetails.toInsertJson(),
        });
      }

      if (eventDetails != null) {
        await _supabase.from('event_details').insert({
          'post_id': postId,
          ...eventDetails.toInsertJson(),
        });
      }

      if (alertDetails != null) {
        await _supabase.from('alert_details').insert({
          'post_id': postId,
          ...alertDetails.toInsertJson(),
        });
      }

      if (lostFoundDetails != null) {
        await _supabase.from('lost_found_details').insert({
          'post_id': postId,
          ...lostFoundDetails.toInsertJson(),
        });
      }

      if (jobDetails != null) {
        await _supabase.from('job_details').insert({
          'post_id': postId,
          ...jobDetails.toInsertJson(),
        });
      }

      if (recommendationDetails != null) {
        await _supabase.from('recommendation_details').insert({
          'post_id': postId,
          ...recommendationDetails.toInsertJson(),
        });
      }

      // Fetch and return the created post
      final createdPost = await getPostById(postId);
      return createdPost!;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create post: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Updates an existing post
  /// Returns the updated [Post]
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
      // Update main post fields
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (content != null) updates['body'] = content;
      if (status != null) updates['status'] = status;
      if (locationText != null) updates['location_text'] = locationText;

      // Update resolved_at timestamp when marking as resolved
      if (status == 'resolved') {
        updates['resolved_at'] = DateTime.now().toIso8601String();
      }

      if (updates.isNotEmpty) {
        await _supabase
            .from('posts')
            .update(updates)
            .eq('id', postId);
      }

      // Update category-specific details
      if (marketplaceDetails != null) {
        await _supabase
            .from('marketplace_details')
            .update(marketplaceDetails.toInsertJson())
            .eq('post_id', postId);
      }

      if (eventDetails != null) {
        await _supabase
            .from('event_details')
            .update(eventDetails.toInsertJson())
            .eq('post_id', postId);
      }

      if (alertDetails != null) {
        await _supabase
            .from('alert_details')
            .update(alertDetails.toInsertJson())
            .eq('post_id', postId);
      }

      if (lostFoundDetails != null) {
        await _supabase
            .from('lost_found_details')
            .update(lostFoundDetails.toInsertJson())
            .eq('post_id', postId);
      }

      if (jobDetails != null) {
        await _supabase
            .from('job_details')
            .update(jobDetails.toInsertJson())
            .eq('post_id', postId);
      }

      if (recommendationDetails != null) {
        await _supabase
            .from('recommendation_details')
            .update(recommendationDetails.toInsertJson())
            .eq('post_id', postId);
      }

      // Return the updated post
      final updatedPost = await getPostById(postId);
      return updatedPost!;
    } on PostgrestException catch (e) {
      throw Exception('Failed to update post: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  /// Updates post status (convenience method)
  Future<Post> updatePostStatus({
    required String postId,
    required String status,
  }) async {
    return updatePost(postId: postId, status: status);
  }

  /// Deletes a post (soft delete by setting status to 'removed')
  Future<void> deletePost(String postId) async {
    try {
      await _supabase
          .from('posts')
          .update({'status': 'removed'})
          .eq('id', postId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete post: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // ============================================================
  // Reactions
  // ============================================================

  /// Toggles a reaction on a post (add if not exists, remove if exists)
  Future<bool> toggleReaction({
    required String postId,
    required String reactionType,
  }) async {
    try {
      final response = await _supabase.rpc(
        'toggle_reaction',
        params: {
          'p_post_id': postId,
          'p_reaction_type': reactionType,
        },
      );

      return response as bool;
    } on PostgrestException catch (e) {
      throw Exception('Failed to toggle reaction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to toggle reaction: $e');
    }
  }

  /// Gets reaction counts for a post
  Future<Map<String, int>> getReactionCounts(String postId) async {
    try {
      final response = await _supabase
          .from('post_reactions')
          .select('reaction_type')
          .eq('post_id', postId);

      final counts = <String, int>{
        'like': 0,
        'love': 0,
        'helpful': 0,
        'thanks': 0,
      };

      for (final row in response as List<dynamic>) {
        final type = row['reaction_type'] as String;
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch reactions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch reactions: $e');
    }
  }

  /// Gets current user's reaction on a post
  Future<String?> getUserReaction(String postId) async {
    try {
      final response = await _supabase
          .from('post_reactions')
          .select('reaction_type')
          .eq('post_id', postId)
          .maybeSingle();

      return response?['reaction_type'] as String?;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user reaction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch user reaction: $e');
    }
  }

  // ============================================================
  // Comments
  // ============================================================

  /// Gets comments for a post
  Future<List<PostComment>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('''
            *,
            profiles:author_id (
              username,
              first_name,
              last_name,
              avatar_url
            )
          ''')
          .eq('post_id', postId)
          .order('created_at');

      return (response as List<dynamic>).map((json) {
        final profile = json['profiles'] as Map<String, dynamic>?;
        final data = Map<String, dynamic>.from(json);

        // Map database column names to model field names
        data['user_id'] = data['author_id'];
        data['content'] = data['body'];

        if (profile != null) {
          final username = profile['username'] as String?;
          final firstName = profile['first_name'] as String?;
          final lastName = profile['last_name'] as String?;
          final fullName = [firstName, lastName]
              .where((s) => s != null && s.isNotEmpty)
              .join(' ');
          data['author_name'] = fullName.isNotEmpty ? fullName : username;
          data['author_username'] = username;
          data['author_avatar_url'] = profile['avatar_url'];
        }

        return PostComment.fromJson(data);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch comments: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  /// Adds a comment to a post
  Future<PostComment> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be logged in to add a comment');
      }

      final response = await _supabase
          .from('post_comments')
          .insert({
            'post_id': postId,
            'author_id': userId,
            'body': content, // Database column is 'body', not 'content'
            'parent_id': parentId,
          })
          .select('''
            *,
            profiles:author_id (
              username,
              first_name,
              last_name,
              avatar_url
            )
          ''')
          .single();

      // Map database column names to model field names
      final profile = response['profiles'] as Map<String, dynamic>?;
      final data = Map<String, dynamic>.from(response);
      data['user_id'] = data['author_id'];
      data['content'] = data['body'];

      if (profile != null) {
        final username = profile['username'] as String?;
        final firstName = profile['first_name'] as String?;
        final lastName = profile['last_name'] as String?;
        final fullName = [firstName, lastName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
        data['author_name'] = fullName.isNotEmpty ? fullName : username;
        data['author_username'] = username;
        data['author_avatar_url'] = profile['avatar_url'];
      }

      return PostComment.fromJson(data);
    } on PostgrestException catch (e) {
      throw Exception('Failed to add comment: ${e.message}');
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Deletes a comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _supabase
          .from('post_comments')
          .delete()
          .eq('id', commentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete comment: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // ============================================================
  // Saves / Bookmarks
  // ============================================================

  /// Toggles save status on a post
  Future<bool> toggleSave(String postId) async {
    try {
      final response = await _supabase.rpc(
        'toggle_save_post',
        params: {'p_post_id': postId},
      );

      return response as bool;
    } on PostgrestException catch (e) {
      throw Exception('Failed to toggle save: ${e.message}');
    } catch (e) {
      throw Exception('Failed to toggle save: $e');
    }
  }

  /// Checks if current user has saved a post
  Future<bool> isPostSaved(String postId) async {
    try {
      final response = await _supabase
          .from('saved_posts')
          .select('id')
          .eq('post_id', postId)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check saved status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check saved status: $e');
    }
  }

  // ============================================================
  // Event RSVPs
  // ============================================================

  /// Toggles RSVP status for an event
  Future<String?> toggleRsvp({
    required String postId,
    required String status,
  }) async {
    try {
      final response = await _supabase.rpc(
        'toggle_rsvp',
        params: {
          'p_post_id': postId,
          'p_status': status,
        },
      );

      return response as String?;
    } on PostgrestException catch (e) {
      throw Exception('Failed to toggle RSVP: ${e.message}');
    } catch (e) {
      throw Exception('Failed to toggle RSVP: $e');
    }
  }

  /// Gets RSVP counts for an event
  Future<Map<String, int>> getRsvpCounts(String postId) async {
    try {
      final response = await _supabase
          .from('event_rsvps')
          .select('status')
          .eq('post_id', postId);

      final counts = <String, int>{
        'going': 0,
        'interested': 0,
      };

      for (final row in response as List<dynamic>) {
        final status = row['status'] as String;
        if (status == 'going' || status == 'interested') {
          counts[status] = (counts[status] ?? 0) + 1;
        }
      }

      return counts;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch RSVP counts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch RSVP counts: $e');
    }
  }

  /// Gets current user's RSVP status
  Future<String?> getUserRsvpStatus(String postId) async {
    try {
      final response = await _supabase
          .from('event_rsvps')
          .select('status')
          .eq('post_id', postId)
          .maybeSingle();

      return response?['status'] as String?;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch RSVP status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch RSVP status: $e');
    }
  }

  /// Gets list of attendees for an event
  Future<List<EventRsvp>> getEventAttendees(String postId) async {
    try {
      final response = await _supabase
          .from('event_rsvps')
          .select('''
            *,
            profiles:user_id (
              first_name,
              last_name,
              avatar_url
            )
          ''')
          .eq('post_id', postId)
          .inFilter('status', ['going', 'interested'])
          .order('created_at');

      return (response as List<dynamic>).map((json) {
        final profile = json['profiles'] as Map<String, dynamic>?;
        final data = Map<String, dynamic>.from(json);

        if (profile != null) {
          final firstName = profile['first_name'] as String?;
          final lastName = profile['last_name'] as String?;
          data['user_name'] = [firstName, lastName]
              .where((s) => s != null && s.isNotEmpty)
              .join(' ');
          data['user_avatar_url'] = profile['avatar_url'];
        }

        return EventRsvp.fromJson(data);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch attendees: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch attendees: $e');
    }
  }

  // ============================================================
  // Reports
  // ============================================================

  /// Reports a post for moderation
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    try {
      await _supabase.from('post_reports').insert({
        'post_id': postId,
        'reason': reason,
        'details': details,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to report post: ${e.message}');
    } catch (e) {
      throw Exception('Failed to report post: $e');
    }
  }

  // ============================================================
  // Image Upload
  // ============================================================

  /// Allowed MIME types for post images
  static const _allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];

  /// Maximum file size in bytes (5MB)
  static const _maxFileSizeBytes = 5 * 1024 * 1024;

  /// Maximum image width for resizing
  static const _maxImageWidth = 1200;

  /// Validates an image file before upload
  /// Throws [ImageValidationException] if validation fails
  Future<void> validateImage(File file) async {
    final bytes = await file.readAsBytes();

    // Check MIME type from file header bytes
    final mimeType = lookupMimeType('', headerBytes: bytes);
    if (mimeType == null || !_allowedMimeTypes.contains(mimeType)) {
      throw ImageValidationException(
        'Invalid image type. Allowed: JPEG, PNG, WebP',
      );
    }

    // Check file size
    if (bytes.length > _maxFileSizeBytes) {
      throw ImageValidationException(
        'Image too large. Maximum size is 5MB',
      );
    }
  }

  /// Resizes an image if it exceeds the maximum width
  /// Returns the resized bytes or original if no resize needed
  Future<Uint8List> _resizeImageIfNeeded(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null || image.width <= _maxImageWidth) {
      return bytes;
    }

    final resized = img.copyResize(image, width: _maxImageWidth);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  /// Gets image dimensions from bytes
  Map<String, int>? _getImageDimensions(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    return {'width': image.width, 'height': image.height};
  }

  /// Uploads an image to Cloudflare R2 and creates a post_images record
  /// Returns the created [PostImage]
  Future<PostImage> uploadPostImage({
    required String postId,
    required File file,
    int displayOrder = 0,
    bool isPrimary = false,
    String? altText,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to upload images');
      }

      // Validate the image
      await validateImage(file);

      // Read and process the image
      final originalBytes = await file.readAsBytes();
      final processedBytes = await _resizeImageIfNeeded(originalBytes);
      final dimensions = _getImageDimensions(processedBytes);

      // Determine content type
      final mimeType = lookupMimeType('', headerBytes: processedBytes);
      final contentType = mimeType ?? 'image/jpeg';

      // Get presigned URL from R2 via Edge Function
      final r2Service = R2StorageService();
      final presigned = await r2Service.getPresignedUploadUrl(
        postId: postId,
        contentType: contentType,
      );

      // Upload directly to R2
      await r2Service.uploadToR2(
        presignedUrl: presigned.presignedUrl,
        bytes: processedBytes,
        contentType: contentType,
      );

      // Use the public URL and storage path from presigned response
      final url = presigned.publicUrl;
      final storagePath = presigned.storagePath;

      // Create the database record
      final response = await _supabase.from('post_images').insert({
        'post_id': postId,
        'storage_path': storagePath,
        'url': url,
        'alt_text': altText,
        'display_order': displayOrder,
        'is_primary': isPrimary,
        'width': dimensions?['width'],
        'height': dimensions?['height'],
        'file_size': processedBytes.length,
      }).select().single();

      return PostImage.fromJson(response);
    } on StorageException catch (e) {
      throw Exception('Failed to upload image: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Failed to save image record: ${e.message}');
    } catch (e) {
      if (e is ImageValidationException) rethrow;
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Uploads multiple images for a post
  /// Returns list of created [PostImage]s
  Future<List<PostImage>> uploadPostImages({
    required String postId,
    required List<File> files,
  }) async {
    final images = <PostImage>[];

    for (var i = 0; i < files.length; i++) {
      final image = await uploadPostImage(
        postId: postId,
        file: files[i],
        displayOrder: i,
        isPrimary: i == 0, // First image is primary
      );
      images.add(image);
    }

    return images;
  }

  /// Gets all images for a post
  Future<List<PostImage>> getPostImages(String postId) async {
    try {
      final response = await _supabase
          .from('post_images')
          .select()
          .eq('post_id', postId)
          .order('display_order');

      return (response as List<dynamic>)
          .map((json) => PostImage.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch images: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch images: $e');
    }
  }

  /// Deletes a post image (both storage and database record)
  Future<void> deletePostImage(String imageId) async {
    try {
      // Get the image record first
      final response = await _supabase
          .from('post_images')
          .select('storage_path')
          .eq('id', imageId)
          .single();

      final storagePath = response['storage_path'] as String;

      // Delete from R2 storage
      final r2Service = R2StorageService();
      await r2Service.deleteFromR2(storagePath: storagePath);

      // Delete the database record
      await _supabase.from('post_images').delete().eq('id', imageId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete image record: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Reorders images for a post
  Future<void> reorderPostImages(
    String postId,
    List<String> orderedImageIds,
  ) async {
    try {
      for (var i = 0; i < orderedImageIds.length; i++) {
        await _supabase.from('post_images').update({
          'display_order': i,
          'is_primary': i == 0,
        }).eq('id', orderedImageIds[i]);
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to reorder images: ${e.message}');
    } catch (e) {
      throw Exception('Failed to reorder images: $e');
    }
  }

  // ============================================================
  // Video Upload
  // ============================================================

  /// Allowed video MIME types
  static const _allowedVideoMimeTypes = [
    'video/mp4',
    'video/quicktime',
    'video/x-m4v',
  ];

  /// Maximum video file size in bytes (200MB - Cloudflare Stream direct upload limit)
  static const _maxVideoFileSizeBytes = 200 * 1024 * 1024;

  /// Maximum video duration in seconds (5 minutes)
  static const _maxVideoDurationSeconds = 300;

  /// Exception thrown when video validation fails
  /// Validates a video file before upload
  /// Throws [VideoValidationException] if validation fails
  Future<void> validateVideo(File file, {int? durationSeconds}) async {
    // Check file size
    final fileSize = await file.length();
    if (fileSize > _maxVideoFileSizeBytes) {
      throw VideoValidationException(
        'Video too large. Maximum size is 200MB',
      );
    }

    // Check MIME type from file header bytes
    final headerBytes = await file.openRead(0, 16).fold<List<int>>(
      [],
      (prev, chunk) => prev..addAll(chunk),
    );
    final mimeType = lookupMimeType(file.path, headerBytes: headerBytes);
    if (mimeType == null || !_allowedVideoMimeTypes.contains(mimeType)) {
      throw VideoValidationException(
        'Invalid video type. Allowed: MP4, MOV',
      );
    }

    // Check duration if provided
    if (durationSeconds != null && durationSeconds > _maxVideoDurationSeconds) {
      throw VideoValidationException(
        'Video too long. Maximum duration is 5 minutes',
      );
    }
  }

  /// Uploads a video to Cloudflare Stream and creates a post_videos record
  /// Returns the created [PostVideo]
  Future<PostVideo> uploadPostVideo({
    required String postId,
    required File file,
    int? durationSeconds,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to upload videos');
      }

      // Validate the video
      await validateVideo(file, durationSeconds: durationSeconds);

      // Get direct upload URL from Cloudflare Stream
      final streamService = CloudflareStreamService();
      final uploadUrl = await streamService.createDirectUpload();

      // Upload the video to Stream
      await streamService.uploadVideoToStream(
        uploadUrl: uploadUrl.uploadUrl,
        videoFile: file,
      );

      // Get file size
      final fileSize = await file.length();

      // Create the database record with 'processing' status
      final response = await _supabase.from('post_videos').insert({
        'post_id': postId,
        'stream_video_uid': uploadUrl.videoUid,
        'status': 'processing',
        'file_size': fileSize,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      }).select().single();

      return PostVideo.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to save video record: ${e.message}');
    } catch (e) {
      if (e is VideoValidationException) rethrow;
      throw Exception('Failed to upload video: $e');
    }
  }

  /// Gets the video for a post
  Future<PostVideo?> getPostVideo(String postId) async {
    try {
      final response = await _supabase
          .from('post_videos')
          .select()
          .eq('post_id', postId)
          .maybeSingle();

      if (response == null) return null;
      return PostVideo.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch video: ${e.message}');
    }
  }

  /// Polls Cloudflare Stream for video processing status and updates the DB
  /// Returns the updated [PostVideo]
  Future<PostVideo> pollVideoStatus(String postId, String videoUid) async {
    try {
      final streamService = CloudflareStreamService();
      final info = await streamService.getVideoStatus(videoUid);

      // Update the database record with the latest status
      final response = await _supabase.from('post_videos').update({
        'status': info.status,
        if (info.thumbnailUrl != null) 'thumbnail_url': info.thumbnailUrl,
        if (info.playbackUrl != null) 'playback_url': info.playbackUrl,
        if (info.duration != null) 'duration_seconds': info.duration,
        if (info.width != null) 'width': info.width,
        if (info.height != null) 'height': info.height,
      }).eq('post_id', postId).select().single();

      return PostVideo.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update video status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to poll video status: $e');
    }
  }

  /// Deletes a post video (both from Stream and database)
  Future<void> deletePostVideo(String videoId, String streamVideoUid) async {
    try {
      // Delete from Cloudflare Stream
      final streamService = CloudflareStreamService();
      await streamService.deleteVideo(streamVideoUid);

      // Delete the database record
      await _supabase.from('post_videos').delete().eq('id', videoId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete video record: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }

  // ============================================================
  // Real-time Subscriptions (Broadcast)
  // ============================================================

  /// Subscribes to new posts in the feed via Broadcast
  RealtimeChannel subscribeToNewPosts({
    required void Function(String postId, String? authorId) onNewPost,
  }) {
    return _supabase
        .channel(
          'feed:global:posts',
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
              debugPrint('Error parsing new post broadcast: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribes to comments on a specific post via Broadcast
  RealtimeChannel subscribeToComments({
    required String postId,
    required void Function(String commentId) onNewComment,
  }) {
    return _supabase
        .channel(
          'feed:$postId:comments',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: 'INSERT',
          callback: (payload) {
            try {
              final commentId = payload['id'] as String;
              onNewComment(commentId);
            } catch (e) {
              debugPrint('Error parsing comment broadcast: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribes to active alerts (for urgent banner) via Broadcast
  RealtimeChannel subscribeToAlerts({
    required void Function() onAlertChange,
  }) {
    return _supabase
        .channel(
          'feed:global:alerts',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: '*',
          callback: (_) {
            onAlertChange();
          },
        )
        .subscribe();
  }

  /// Subscribes to reaction changes on all posts via Broadcast
  RealtimeChannel subscribeToReactions({
    required void Function(String postId, String userId, int reactionCount)
        onReactionChange,
  }) {
    return _supabase
        .channel(
          'feed:global:reactions',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: '*',
          callback: (payload) {
            try {
              final postId = payload['post_id'] as String;
              final userId = payload['user_id'] as String;
              final reactionCount = payload['reaction_count'] as int;
              onReactionChange(postId, userId, reactionCount);
            } catch (e) {
              debugPrint('Error parsing reaction broadcast: $e');
            }
          },
        )
        .subscribe();
  }

  /// Unsubscribes from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
