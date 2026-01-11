enum RsvpStatus {
  going,
  interested,
  notGoing;

  String get displayName {
    switch (this) {
      case RsvpStatus.going:
        return 'Going';
      case RsvpStatus.interested:
        return 'Interested';
      case RsvpStatus.notGoing:
        return 'Not Going';
    }
  }

  String get dbValue => name;

  static RsvpStatus fromString(String value) {
    switch (value) {
      case 'going':
        return RsvpStatus.going;
      case 'interested':
        return RsvpStatus.interested;
      case 'notGoing':
        return RsvpStatus.notGoing;
      default:
        return RsvpStatus.interested;
    }
  }
}

class EventRsvp {
  final String id;
  final String postId;
  final String userId;
  final RsvpStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined from profiles
  final String? userName;
  final String? userAvatarUrl;

  EventRsvp({
    required this.id,
    required this.postId,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
  });

  factory EventRsvp.fromJson(Map<String, dynamic> json) {
    return EventRsvp(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      status: RsvpStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'status': status.dbValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// RSVP summary for event posts
class RsvpSummary {
  final int goingCount;
  final int interestedCount;
  final RsvpStatus? userStatus;

  RsvpSummary({
    this.goingCount = 0,
    this.interestedCount = 0,
    this.userStatus,
  });

  int get totalCount => goingCount + interestedCount;

  bool get hasUserRsvped => userStatus != null;

  factory RsvpSummary.fromJson(Map<String, dynamic> json, {String? userStatusStr}) {
    return RsvpSummary(
      goingCount: json['going_count'] as int? ?? 0,
      interestedCount: json['interested_count'] as int? ?? 0,
      userStatus: userStatusStr != null
          ? RsvpStatus.fromString(userStatusStr)
          : null,
    );
  }
}
