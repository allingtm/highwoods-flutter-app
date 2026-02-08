import 'group.dart';

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final GroupMemberRole role;
  final DateTime? acceptedTermsAt;
  final DateTime joinedAt;

  // Joined profile data
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = GroupMemberRole.member,
    this.acceptedTermsAt,
    required this.joinedAt,
    this.username,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    // Handle joined profile data (from select with profile join)
    final profile = json['profile'] as Map<String, dynamic>?;

    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: GroupMemberRole.fromString(json['role'] as String? ?? 'member'),
      acceptedTermsAt: json['accepted_terms_at'] != null
          ? DateTime.parse(json['accepted_terms_at'] as String)
          : null,
      joinedAt: DateTime.parse(json['joined_at'] as String),
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

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    GroupMemberRole? role,
    DateTime? acceptedTermsAt,
    DateTime? joinedAt,
    String? username,
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      acceptedTermsAt: acceptedTermsAt ?? this.acceptedTermsAt,
      joinedAt: joinedAt ?? this.joinedAt,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
