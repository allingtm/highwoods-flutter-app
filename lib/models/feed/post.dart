import '../post_category.dart';
import '../post_type.dart';
import '../post_status.dart';
import 'marketplace_details.dart';
import 'event_details.dart';
import 'alert_details.dart';
import 'lost_found_details.dart';
import 'job_details.dart';
import 'recommendation_details.dart';
import 'post_image.dart';

/// Sentinel value to distinguish "not provided" from "explicitly null" in copyWith
class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

class Post {
  final String id;
  final String userId;
  final PostCategory category;
  final PostType postType;
  final String? title;
  final String? content;
  final PostStatus status;
  final int reactionCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Author info (joined from profiles)
  final String? authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final bool authorIsVerified;

  // Images
  final List<PostImage> images;
  final String? primaryImageUrl;

  // Type-specific details (only one will be populated based on category)
  final MarketplaceDetails? marketplaceDetails;
  final EventDetails? eventDetails;
  final AlertDetails? alertDetails;
  final LostFoundDetails? lostFoundDetails;
  final JobDetails? jobDetails;
  final RecommendationDetails? recommendationDetails;

  // User's interaction state (for logged-in users)
  final bool isSaved;
  final String? userReaction;

  Post({
    required this.id,
    required this.userId,
    required this.category,
    required this.postType,
    this.title,
    this.content,
    this.status = PostStatus.active,
    this.reactionCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorUsername,
    this.authorAvatarUrl,
    this.authorIsVerified = false,
    this.images = const [],
    this.primaryImageUrl,
    this.marketplaceDetails,
    this.eventDetails,
    this.alertDetails,
    this.lostFoundDetails,
    this.jobDetails,
    this.recommendationDetails,
    this.isSaved = false,
    this.userReaction,
  });

  /// Creates Post from flattened feed_posts_view data
  factory Post.fromFeedJson(Map<String, dynamic> json) {
    final category = PostCategory.fromString(json['category'] as String);
    final postType = PostType.fromString(json['post_type'] as String);

    // Build author display name from available fields
    final firstName = json['author_first_name'] as String?;
    final lastName = json['author_last_name'] as String?;
    final username = json['author_username'] as String?;
    String? authorName;
    if (firstName != null || lastName != null) {
      authorName = [firstName, lastName].where((s) => s != null).join(' ');
    } else {
      authorName = username;
    }

    return Post(
      id: json['id'] as String,
      userId: json['author_id'] as String,
      category: category,
      postType: postType,
      title: json['title'] as String?,
      content: json['body'] as String?,
      status: PostStatus.fromString(json['status'] as String? ?? 'active'),
      reactionCount: json['reaction_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at'] as String),
      authorName: authorName,
      authorUsername: username,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      authorIsVerified: json['author_role'] == 'admin' || json['author_role'] == 'moderator',
      primaryImageUrl: json['primary_image_url'] as String?,
      // Category-specific details
      marketplaceDetails: category == PostCategory.marketplace
          ? MarketplaceDetails.fromFeedJson(json)
          : null,
      eventDetails: _hasEventData(json)
          ? EventDetails.fromFeedJson(json)
          : null,
      alertDetails: category == PostCategory.safety
          ? AlertDetails.fromFeedJson(json)
          : null,
      lostFoundDetails: category == PostCategory.lostFound
          ? LostFoundDetails.fromFeedJson(json)
          : null,
      jobDetails: category == PostCategory.jobs
          ? JobDetails.fromFeedJson(json)
          : null,
      recommendationDetails: category == PostCategory.recommendations
          ? RecommendationDetails.fromFeedJson(json)
          : null,
      isSaved: json['is_saved'] as bool? ?? false,
      userReaction: json['user_reaction'] as String?,
    );
  }

  /// Creates Post from full post data (with separate detail objects)
  factory Post.fromJson(Map<String, dynamic> json) {
    final category = PostCategory.fromString(json['category'] as String);

    // Parse images if present
    final imagesJson = json['images'] as List<dynamic>?;
    final images = imagesJson
        ?.map((e) => PostImage.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: category,
      postType: PostType.fromString(json['post_type'] as String),
      title: json['title'] as String?,
      content: json['content'] as String?,
      status: PostStatus.fromString(json['status'] as String? ?? 'active'),
      reactionCount: json['reaction_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorName: json['author_name'] as String?,
      authorUsername: json['author_username'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      authorIsVerified: json['author_is_verified'] as bool? ?? false,
      images: images,
      primaryImageUrl: images.isNotEmpty ? images.first.url : null,
      marketplaceDetails: json['marketplace_details'] != null
          ? MarketplaceDetails.fromJson(json['marketplace_details'] as Map<String, dynamic>)
          : null,
      eventDetails: json['event_details'] != null
          ? EventDetails.fromJson(json['event_details'] as Map<String, dynamic>)
          : null,
      alertDetails: json['alert_details'] != null
          ? AlertDetails.fromJson(json['alert_details'] as Map<String, dynamic>)
          : null,
      lostFoundDetails: json['lost_found_details'] != null
          ? LostFoundDetails.fromJson(json['lost_found_details'] as Map<String, dynamic>)
          : null,
      jobDetails: json['job_details'] != null
          ? JobDetails.fromJson(json['job_details'] as Map<String, dynamic>)
          : null,
      recommendationDetails: json['recommendation_details'] != null
          ? RecommendationDetails.fromJson(json['recommendation_details'] as Map<String, dynamic>)
          : null,
      isSaved: json['is_saved'] as bool? ?? false,
      userReaction: json['user_reaction'] as String?,
    );
  }

  static bool _hasEventData(Map<String, dynamic> json) {
    return json['event_date'] != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category.dbValue,
      'post_type': postType.dbValue,
      if (title != null) 'title': title,
      'content': content,
      'status': status.dbValue,
      'reaction_count': reactionCount,
      'comment_count': commentCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// For creating a new post (without id, timestamps, etc.)
  Map<String, dynamic> toInsertJson() {
    return {
      'category': category.dbValue,
      'post_type': postType.dbValue,
      if (title != null) 'title': title,
      'content': content,
      'status': status.dbValue,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    PostCategory? category,
    PostType? postType,
    String? title,
    String? content,
    PostStatus? status,
    int? reactionCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? authorUsername,
    String? authorAvatarUrl,
    bool? authorIsVerified,
    List<PostImage>? images,
    String? primaryImageUrl,
    MarketplaceDetails? marketplaceDetails,
    EventDetails? eventDetails,
    AlertDetails? alertDetails,
    LostFoundDetails? lostFoundDetails,
    JobDetails? jobDetails,
    RecommendationDetails? recommendationDetails,
    bool? isSaved,
    // Use Object? with sentinel to allow explicitly setting to null
    Object? userReaction = _sentinel,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      postType: postType ?? this.postType,
      title: title ?? this.title,
      content: content ?? this.content,
      status: status ?? this.status,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorIsVerified: authorIsVerified ?? this.authorIsVerified,
      images: images ?? this.images,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      marketplaceDetails: marketplaceDetails ?? this.marketplaceDetails,
      eventDetails: eventDetails ?? this.eventDetails,
      alertDetails: alertDetails ?? this.alertDetails,
      lostFoundDetails: lostFoundDetails ?? this.lostFoundDetails,
      jobDetails: jobDetails ?? this.jobDetails,
      recommendationDetails: recommendationDetails ?? this.recommendationDetails,
      isSaved: isSaved ?? this.isSaved,
      // If sentinel, keep existing value; otherwise use the provided value (including null)
      userReaction: userReaction == _sentinel
          ? this.userReaction
          : userReaction as String?,
    );
  }

  // Convenience getters
  bool get hasImages => images.isNotEmpty || primaryImageUrl != null;
  bool get isEvent => eventDetails != null;
  bool get isAlert => alertDetails != null;
  bool get isMarketplace => marketplaceDetails != null;
  bool get isLostFound => lostFoundDetails != null;
  bool get isJob => jobDetails != null;
  bool get isRecommendation => recommendationDetails != null;
  bool get hasUserReacted => userReaction != null;

  /// Returns a short preview of the content (first 100 chars)
  String get contentPreview {
    if (content == null || content!.isEmpty) return '';
    if (content!.length <= 100) return content!;
    return '${content!.substring(0, 100)}...';
  }

  /// Returns time since post was created in human-readable format
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 365) {
      final years = diff.inDays ~/ 365;
      return '${years}y ago';
    } else if (diff.inDays > 30) {
      final months = diff.inDays ~/ 30;
      return '${months}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
