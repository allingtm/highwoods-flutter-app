enum ReactionType {
  like,
  love,
  helpful,
  thanks;

  String get displayName {
    switch (this) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.love:
        return 'Love';
      case ReactionType.helpful:
        return 'Helpful';
      case ReactionType.thanks:
        return 'Thanks';
    }
  }

  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.helpful:
        return '💡';
      case ReactionType.thanks:
        return '🙏';
    }
  }

  String get dbValue => name;

  static ReactionType fromString(String value) {
    switch (value) {
      case 'like':
        return ReactionType.like;
      case 'love':
        return ReactionType.love;
      case 'helpful':
        return ReactionType.helpful;
      case 'thanks':
        return ReactionType.thanks;
      default:
        return ReactionType.like;
    }
  }
}

class PostReaction {
  final String id;
  final String postId;
  final String userId;
  final ReactionType reactionType;
  final DateTime createdAt;

  PostReaction({
    required this.id,
    required this.postId,
    required this.userId,
    required this.reactionType,
    required this.createdAt,
  });

  factory PostReaction.fromJson(Map<String, dynamic> json) {
    return PostReaction(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      reactionType: ReactionType.fromString(json['reaction_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'reaction_type': reactionType.dbValue,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Aggregated reaction counts for display
class ReactionSummary {
  final int likeCount;
  final int loveCount;
  final int helpfulCount;
  final int thanksCount;
  final ReactionType? userReaction;

  ReactionSummary({
    this.likeCount = 0,
    this.loveCount = 0,
    this.helpfulCount = 0,
    this.thanksCount = 0,
    this.userReaction,
  });

  int get totalCount => likeCount + loveCount + helpfulCount + thanksCount;

  bool get hasUserReacted => userReaction != null;

  factory ReactionSummary.fromJson(Map<String, dynamic> json, {String? userReactionType}) {
    return ReactionSummary(
      likeCount: json['like_count'] as int? ?? 0,
      loveCount: json['love_count'] as int? ?? 0,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      thanksCount: json['thanks_count'] as int? ?? 0,
      userReaction: userReactionType != null
          ? ReactionType.fromString(userReactionType)
          : null,
    );
  }
}
