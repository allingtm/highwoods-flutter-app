/// Invitation status
enum InvitationStatus {
  pending,
  accepted,
  expired;

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}

/// Represents an invitation to join the app
class Invitation {
  final String id;
  final String inviterId;
  final String email;
  final String? message;
  final String token;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final String? acceptedBy;

  Invitation({
    required this.id,
    required this.inviterId,
    required this.email,
    this.message,
    required this.token,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
    this.acceptedBy,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      inviterId: json['inviter_id'] as String,
      email: json['email'] as String,
      message: json['message'] as String?,
      token: json['token'] as String,
      status: InvitationStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      acceptedBy: json['accepted_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inviter_id': inviterId,
      'email': email,
      if (message != null) 'message': message,
      'token': token,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      if (acceptedAt != null) 'accepted_at': acceptedAt!.toIso8601String(),
      if (acceptedBy != null) 'accepted_by': acceptedBy,
    };
  }

  Invitation copyWith({
    String? id,
    String? inviterId,
    String? email,
    String? message,
    String? token,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    String? acceptedBy,
  }) {
    return Invitation(
      id: id ?? this.id,
      inviterId: inviterId ?? this.inviterId,
      email: email ?? this.email,
      message: message ?? this.message,
      token: token ?? this.token,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      acceptedBy: acceptedBy ?? this.acceptedBy,
    );
  }

  /// Check if this invitation has expired
  bool get isExpired =>
      status == InvitationStatus.expired ||
      DateTime.now().isAfter(expiresAt);

  /// Check if this invitation is still pending and valid
  bool get isPending =>
      status == InvitationStatus.pending &&
      DateTime.now().isBefore(expiresAt);
}
