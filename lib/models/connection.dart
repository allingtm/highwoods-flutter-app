import 'user_profile.dart';

/// Connection status between two users
enum ConnectionStatus {
  pending,
  accepted,
  rejected,
  blocked;

  static ConnectionStatus fromString(String value) {
    return ConnectionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConnectionStatus.pending,
    );
  }
}

/// Represents a connection between two users
class Connection {
  final String id;
  final String requesterId;
  final String recipientId;
  final ConnectionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;

  /// The other user in this connection (populated from join)
  final UserProfile? otherUser;

  Connection({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.otherUser,
  });

  factory Connection.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Determine which profile is the "other" user
    UserProfile? otherUser;
    if (json['requester'] != null && json['recipient'] != null) {
      final requesterId = json['requester_id'] as String;
      if (currentUserId != null && requesterId == currentUserId) {
        otherUser = UserProfile.fromJson(json['recipient'] as Map<String, dynamic>);
      } else {
        otherUser = UserProfile.fromJson(json['requester'] as Map<String, dynamic>);
      }
    }

    return Connection(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      recipientId: json['recipient_id'] as String,
      status: ConnectionStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      otherUser: otherUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'recipient_id': recipientId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (acceptedAt != null) 'accepted_at': acceptedAt!.toIso8601String(),
    };
  }

  Connection copyWith({
    String? id,
    String? requesterId,
    String? recipientId,
    ConnectionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    UserProfile? otherUser,
  }) {
    return Connection(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      recipientId: recipientId ?? this.recipientId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      otherUser: otherUser ?? this.otherUser,
    );
  }

  /// Check if this is a pending incoming request for the given user
  bool isIncomingRequest(String userId) {
    return status == ConnectionStatus.pending && recipientId == userId;
  }

  /// Check if this is a pending outgoing request from the given user
  bool isOutgoingRequest(String userId) {
    return status == ConnectionStatus.pending && requesterId == userId;
  }

  /// Check if this connection is active (accepted)
  bool get isAccepted => status == ConnectionStatus.accepted;
}
