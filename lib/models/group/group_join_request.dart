enum JoinRequestStatus {
  pending,
  approved,
  rejected;

  String get dbValue => name;

  static JoinRequestStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return JoinRequestStatus.approved;
      case 'rejected':
        return JoinRequestStatus.rejected;
      default:
        return JoinRequestStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case JoinRequestStatus.pending:
        return 'Pending';
      case JoinRequestStatus.approved:
        return 'Approved';
      case JoinRequestStatus.rejected:
        return 'Rejected';
    }
  }
}

class GroupJoinRequest {
  final String id;
  final String groupId;
  final String userId;
  final JoinRequestStatus status;
  final String? message;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  // Joined profile data
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;

  GroupJoinRequest({
    required this.id,
    required this.groupId,
    required this.userId,
    this.status = JoinRequestStatus.pending,
    this.message,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.username,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  factory GroupJoinRequest.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;

    return GroupJoinRequest(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      status: JoinRequestStatus.fromString(json['status'] as String? ?? 'pending'),
      message: json['message'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      username: profile?['username'] as String? ?? json['username'] as String?,
      firstName: profile?['first_name'] as String? ?? json['first_name'] as String?,
      lastName: profile?['last_name'] as String? ?? json['last_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String? ?? json['avatar_url'] as String?,
    );
  }

  String get displayName {
    if (firstName != null || lastName != null) {
      return [firstName, lastName].where((s) => s != null).join(' ');
    }
    return username ?? 'Unknown';
  }

  bool get isPending => status == JoinRequestStatus.pending;
}
