import 'user_profile.dart';

/// Represents a direct message between two users
class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime? readAt;
  final DateTime createdAt;

  /// The sender's profile (populated from join)
  final UserProfile? sender;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.readAt,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String,
      content: json['content'] as String,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      sender: json['sender'] != null
          ? UserProfile.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? content,
    DateTime? readAt,
    DateTime? createdAt,
    UserProfile? sender,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
    );
  }

  /// Check if this message has been read
  bool get isRead => readAt != null;

  /// Check if this message was sent by the given user
  bool isSentBy(String userId) => senderId == userId;

  /// Check if this message was received by the given user
  bool isReceivedBy(String userId) => recipientId == userId;
}

/// Represents a conversation thread with another user
class Conversation {
  final UserProfile otherUser;
  final Message lastMessage;
  final int unreadCount;

  Conversation({
    required this.otherUser,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      otherUser: UserProfile.fromJson(json['other_user'] as Map<String, dynamic>),
      lastMessage: Message.fromJson(json['last_message'] as Map<String, dynamic>),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  /// Check if there are unread messages
  bool get hasUnread => unreadCount > 0;
}
