enum GroupVisibility {
  public_,
  requestToJoin,
  private_;

  String get dbValue {
    switch (this) {
      case GroupVisibility.public_:
        return 'public';
      case GroupVisibility.requestToJoin:
        return 'request_to_join';
      case GroupVisibility.private_:
        return 'private';
    }
  }

  static GroupVisibility fromString(String value) {
    switch (value) {
      case 'public':
        return GroupVisibility.public_;
      case 'request_to_join':
        return GroupVisibility.requestToJoin;
      case 'private':
        return GroupVisibility.private_;
      default:
        return GroupVisibility.public_;
    }
  }

  String get displayName {
    switch (this) {
      case GroupVisibility.public_:
        return 'Public';
      case GroupVisibility.requestToJoin:
        return 'Request to Join';
      case GroupVisibility.private_:
        return 'Private';
    }
  }
}

enum GroupMemberRole {
  member,
  moderator,
  admin;

  String get dbValue => name;

  static GroupMemberRole fromString(String value) {
    switch (value) {
      case 'admin':
        return GroupMemberRole.admin;
      case 'moderator':
        return GroupMemberRole.moderator;
      default:
        return GroupMemberRole.member;
    }
  }

  String get displayName {
    switch (this) {
      case GroupMemberRole.member:
        return 'Member';
      case GroupMemberRole.moderator:
        return 'Moderator';
      case GroupMemberRole.admin:
        return 'Admin';
    }
  }

  bool get canModerate => this == admin || this == moderator;
  bool get canManageRoles => this == admin;
}

class Group {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final String? coverImageUrl;
  final GroupVisibility visibility;
  final String createdBy;
  final int memberCount;
  final int postCount;
  final bool isArchived;
  final String? termsText;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Membership info (from RPC join)
  final GroupMemberRole? currentUserRole;
  final bool isMember;
  final bool hasPendingRequest;

  Group({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    this.coverImageUrl,
    this.visibility = GroupVisibility.public_,
    required this.createdBy,
    this.memberCount = 0,
    this.postCount = 0,
    this.isArchived = false,
    this.termsText,
    required this.createdAt,
    required this.updatedAt,
    this.currentUserRole,
    this.isMember = false,
    this.hasPendingRequest = false,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    final roleStr = json['current_user_role'] as String?;
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      visibility: GroupVisibility.fromString(json['visibility'] as String? ?? 'public'),
      createdBy: json['created_by'] as String,
      memberCount: json['member_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      termsText: json['terms_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      currentUserRole: roleStr != null ? GroupMemberRole.fromString(roleStr) : null,
      isMember: json['is_member'] as bool? ?? false,
      hasPendingRequest: json['has_pending_request'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon_url': iconUrl,
      'cover_image_url': coverImageUrl,
      'visibility': visibility.dbValue,
      'created_by': createdBy,
      'member_count': memberCount,
      'post_count': postCount,
      'is_archived': isArchived,
      'terms_text': termsText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? iconUrl,
    String? coverImageUrl,
    GroupVisibility? visibility,
    String? createdBy,
    int? memberCount,
    int? postCount,
    bool? isArchived,
    String? termsText,
    DateTime? createdAt,
    DateTime? updatedAt,
    GroupMemberRole? currentUserRole,
    bool? isMember,
    bool? hasPendingRequest,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      visibility: visibility ?? this.visibility,
      createdBy: createdBy ?? this.createdBy,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount ?? this.postCount,
      isArchived: isArchived ?? this.isArchived,
      termsText: termsText ?? this.termsText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      isMember: isMember ?? this.isMember,
      hasPendingRequest: hasPendingRequest ?? this.hasPendingRequest,
    );
  }

  bool get isPublic => visibility == GroupVisibility.public_;
  bool get isRequestToJoin => visibility == GroupVisibility.requestToJoin;
  bool get isPrivate => visibility == GroupVisibility.private_;
  bool get canCurrentUserModerate => currentUserRole?.canModerate ?? false;
  bool get canCurrentUserManageRoles => currentUserRole?.canManageRoles ?? false;
}
