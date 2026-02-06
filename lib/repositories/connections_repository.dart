import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/connection.dart';
import '../models/invitation.dart';
import '../models/message.dart';
import '../models/message_report.dart';
import '../models/user_profile.dart';

/// Repository for connections, invitations, and messaging operations
class ConnectionsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Gets the current user's ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ============================================================
  // Connections
  // ============================================================

  /// Gets all accepted connections for the current user
  Future<List<Connection>> getConnections() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('connections')
          .select('''
            *,
            requester:requester_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            ),
            recipient:recipient_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .eq('status', 'accepted')
          .or('requester_id.eq.$userId,recipient_id.eq.$userId')
          .order('accepted_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Connection.fromJson(
                json as Map<String, dynamic>,
                currentUserId: userId,
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch connections: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch connections: $e');
    }
  }

  /// Gets pending incoming connection requests for the current user
  Future<List<Connection>> getPendingRequests() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('connections')
          .select('''
            *,
            requester:requester_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            ),
            recipient:recipient_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .eq('status', 'pending')
          .eq('recipient_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Connection.fromJson(
                json as Map<String, dynamic>,
                currentUserId: userId,
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch pending requests: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  /// Gets outgoing connection requests sent by the current user
  Future<List<Connection>> getSentRequests() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('connections')
          .select('''
            *,
            requester:requester_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            ),
            recipient:recipient_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .eq('status', 'pending')
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Connection.fromJson(
                json as Map<String, dynamic>,
                currentUserId: userId,
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch sent requests: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch sent requests: $e');
    }
  }

  /// Sends a connection request to another user
  Future<Connection> sendConnectionRequest(String recipientId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      if (userId == recipientId) {
        throw Exception('Cannot send connection request to yourself');
      }

      final response = await _supabase
          .from('connections')
          .insert({
            'requester_id': userId,
            'recipient_id': recipientId,
            'status': 'pending',
          })
          .select('''
            *,
            requester:requester_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            ),
            recipient:recipient_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .single();

      return Connection.fromJson(response, currentUserId: userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Connection request already exists');
      }
      throw Exception('Failed to send connection request: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send connection request: $e');
    }
  }

  /// Accepts a pending connection request
  Future<Connection> acceptRequest(String connectionId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('connections')
          .update({'status': 'accepted'})
          .eq('id', connectionId)
          .eq('recipient_id', userId) // Only recipient can accept
          .eq('status', 'pending')
          .select('''
            *,
            requester:requester_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            ),
            recipient:recipient_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .single();

      return Connection.fromJson(response, currentUserId: userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to accept request: ${e.message}');
    } catch (e) {
      throw Exception('Failed to accept request: $e');
    }
  }

  /// Rejects a pending connection request
  Future<void> rejectRequest(String connectionId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      await _supabase
          .from('connections')
          .update({'status': 'rejected'})
          .eq('id', connectionId)
          .eq('recipient_id', userId)
          .eq('status', 'pending');
    } on PostgrestException catch (e) {
      throw Exception('Failed to reject request: ${e.message}');
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  /// Removes an existing connection
  Future<void> removeConnection(String connectionId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      await _supabase
          .from('connections')
          .delete()
          .eq('id', connectionId)
          .or('requester_id.eq.$userId,recipient_id.eq.$userId');
    } on PostgrestException catch (e) {
      throw Exception('Failed to remove connection: ${e.message}');
    } catch (e) {
      throw Exception('Failed to remove connection: $e');
    }
  }

  /// Blocks a user
  Future<void> blockUser(String connectionId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      await _supabase
          .from('connections')
          .update({'status': 'blocked'})
          .eq('id', connectionId)
          .or('requester_id.eq.$userId,recipient_id.eq.$userId');
    } on PostgrestException catch (e) {
      throw Exception('Failed to block user: ${e.message}');
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Checks if two users are connected
  Future<Connection?> getConnectionWith(String otherUserId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('connections')
          .select()
          .or('and(requester_id.eq.$userId,recipient_id.eq.$otherUserId),and(requester_id.eq.$otherUserId,recipient_id.eq.$userId)')
          .maybeSingle();

      if (response == null) return null;
      return Connection.fromJson(response, currentUserId: userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to check connection: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check connection: $e');
    }
  }

  // ============================================================
  // Invitations
  // ============================================================

  /// Generates a secure random token for invitations
  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generates a short, human-readable invite code (e.g., ABC-DEF-GHJ)
  /// Uses characters that avoid visual confusion (no I, O, 0, 1)
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final part1 = List.generate(3, (_) => chars[random.nextInt(chars.length)]).join();
    final part2 = List.generate(3, (_) => chars[random.nextInt(chars.length)]).join();
    final part3 = List.generate(3, (_) => chars[random.nextInt(chars.length)]).join();
    return '$part1-$part2-$part3';
  }

  /// Creates an invitation to share via native share (WhatsApp, SMS, Email, etc.)
  /// Returns the invitation with the token/link and code to share
  Future<Invitation> createInvitation({
    required String recipientName,
    String? message,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final token = _generateToken();
      final code = _generateCode();

      final response = await _supabase
          .from('invitations')
          .insert({
            'inviter_id': userId,
            'recipient_name': recipientName,
            if (message != null && message.isNotEmpty) 'message': message,
            'token': token,
            'code': code,
          })
          .select()
          .single();

      return Invitation.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create invitation: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create invitation: $e');
    }
  }

  /// Validates an invite code or token
  /// Returns validation result with inviter info if valid
  /// This works for unauthenticated users (pre-registration)
  Future<InviteValidationResult> validateInviteCode(String code) async {
    try {
      final response = await _supabase.rpc(
        'validate_invite_code',
        params: {'invite_code': code},
      );

      final json = response as Map<String, dynamic>;
      return InviteValidationResult.fromJson(json);
    } on PostgrestException catch (e) {
      throw Exception('Failed to validate invite code: ${e.message}');
    } catch (e) {
      throw Exception('Failed to validate invite code: $e');
    }
  }

  /// Accepts an invitation after successful registration
  /// Creates a connection between inviter and new user
  Future<void> acceptInvitation(String code) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      await _supabase.rpc(
        'accept_invitation',
        params: {
          'invite_code': code,
          'new_user_id': userId,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to accept invitation: ${e.message}');
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  /// Gets all invitations sent by the current user
  Future<List<Invitation>> getMyInvitations() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('invitations')
          .select()
          .eq('inviter_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Invitation.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch invitations: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch invitations: $e');
    }
  }

  /// Cancels a pending invitation
  Future<void> cancelInvitation(String invitationId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      await _supabase
          .from('invitations')
          .delete()
          .eq('id', invitationId)
          .eq('inviter_id', userId)
          .eq('status', 'pending');
    } on PostgrestException catch (e) {
      throw Exception('Failed to cancel invitation: ${e.message}');
    } catch (e) {
      throw Exception('Failed to cancel invitation: $e');
    }
  }

  // ============================================================
  // Messaging
  // ============================================================

  /// Gets conversation threads for the current user
  Future<List<Conversation>> getConversations() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      // Get all messages involving the user, grouped by conversation partner
      final response = await _supabase.rpc(
        'get_conversations',
        params: {'p_user_id': userId},
      );

      // If the RPC doesn't exist yet, fall back to a simpler query
      if (response == null) {
        return _getConversationsFallback(userId);
      }

      return (response as List<dynamic>)
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      // Fallback if RPC doesn't exist
      final userId = _currentUserId;
      if (userId != null) {
        return _getConversationsFallback(userId);
      }
      throw Exception('Failed to fetch conversations: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  /// Fallback method to get conversations without RPC
  Future<List<Conversation>> _getConversationsFallback(String userId) async {
    // Get distinct conversation partners
    final messagesResponse = await _supabase
        .from('messages')
        .select('''
          *,
          sender:sender_id (
            id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
          )
        ''')
        .or('sender_id.eq.$userId,recipient_id.eq.$userId')
        .order('created_at', ascending: false);

    final messages = messagesResponse as List<dynamic>;

    // Group by conversation partner and get latest message + unread count
    final conversationMap = <String, Map<String, dynamic>>{};

    for (final msg in messages) {
      final senderId = msg['sender_id'] as String;
      final recipientId = msg['recipient_id'] as String;
      final partnerId = senderId == userId ? recipientId : senderId;

      if (!conversationMap.containsKey(partnerId)) {
        conversationMap[partnerId] = {
          'last_message': msg,
          'unread_count': 0,
        };
      }

      // Count unread messages (received but not read)
      if (recipientId == userId && msg['read_at'] == null) {
        conversationMap[partnerId]!['unread_count'] =
            (conversationMap[partnerId]!['unread_count'] as int) + 1;
      }
    }

    // Fetch profiles for all partners
    final partnerIds = conversationMap.keys.toList();
    if (partnerIds.isEmpty) return [];

    final profilesResponse = await _supabase
        .from('profiles')
        .select()
        .inFilter('id', partnerIds);

    final profilesMap = <String, UserProfile>{};
    for (final profile in profilesResponse as List<dynamic>) {
      final userProfile = UserProfile.fromJson(profile as Map<String, dynamic>);
      profilesMap[userProfile.id] = userProfile;
    }

    // Build conversation list
    final conversations = <Conversation>[];
    for (final entry in conversationMap.entries) {
      final partnerId = entry.key;
      final data = entry.value;
      final profile = profilesMap[partnerId];

      if (profile != null) {
        conversations.add(Conversation(
          otherUser: profile,
          lastMessage: Message.fromJson(data['last_message'] as Map<String, dynamic>),
          unreadCount: data['unread_count'] as int,
        ));
      }
    }

    // Sort by last message time
    conversations.sort((a, b) =>
        b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt));

    return conversations;
  }

  /// Gets messages in a conversation with another user
  Future<List<Message>> getMessages({
    required String otherUserId,
    String? beforeId,
    int limit = 50,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      var query = _supabase
          .from('messages')
          .select('''
            *,
            sender:sender_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .or('and(sender_id.eq.$userId,recipient_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,recipient_id.eq.$userId)')
          .order('created_at', ascending: false)
          .limit(limit);

      final response = await query;

      return (response as List<dynamic>)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch messages: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  /// Sends a message to another user.
  ///
  /// If [postId] is provided, allows messaging post authors without requiring
  /// a connection (for marketplace, jobs, lost & found inquiries).
  /// Otherwise, users must be connected to message each other.
  Future<Message> sendMessage({
    required String recipientId,
    required String content,
    String? postId,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      if (content.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      final response = await _supabase
          .from('messages')
          .insert({
            'sender_id': userId,
            'recipient_id': recipientId,
            'content': content.trim(),
            if (postId != null) 'post_id': postId,
          })
          .select('''
            *,
            sender:sender_id (
              id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
            )
          ''')
          .single();

      return Message.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception('This user only accepts messages from their contacts');
      }
      throw Exception('Failed to send message: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Marks messages from a user as read
  Future<void> markMessagesAsRead(String senderId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      await _supabase
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('sender_id', senderId)
          .eq('recipient_id', userId)
          .isFilter('read_at', null);
    } on PostgrestException catch (e) {
      throw Exception('Failed to mark messages as read: ${e.message}');
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Gets total unread message count
  Future<int> getUnreadCount() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('recipient_id', userId)
          .isFilter('read_at', null);

      return (response as List<dynamic>).length;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get unread count: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  // ============================================================
  // Real-time Subscriptions (Broadcast)
  // ============================================================

  /// Subscribes to new messages for the current user via Broadcast
  RealtimeChannel subscribeToMessages({
    required void Function(Message message) onNewMessage,
  }) {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _supabase
        .channel(
          'user:$userId:messages',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: 'INSERT',
          callback: (payload) {
            try {
              final message = Message.fromJson(payload);
              onNewMessage(message);
            } catch (e) {
              debugPrint('Error parsing broadcast message: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribes to connection requests for the current user via Broadcast
  RealtimeChannel subscribeToConnectionRequests({
    required void Function(Connection connection) onNewRequest,
  }) {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _supabase
        .channel(
          'user:$userId:connections',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: 'INSERT',
          callback: (payload) async {
            try {
              final connectionId = payload['id'] as String;
              // Fetch full connection with profile data
              final response = await _supabase
                  .from('connections')
                  .select('''
                    *,
                    requester:requester_id (
                      id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
                    ),
                    recipient:recipient_id (
                      id, email, username, first_name, last_name, avatar_url, bio, role, created_at, updated_at
                    )
                  ''')
                  .eq('id', connectionId)
                  .single();

              final connection = Connection.fromJson(response, currentUserId: userId);
              onNewRequest(connection);
            } catch (e) {
              debugPrint('Error handling connection broadcast: $e');
            }
          },
        )
        .subscribe();
  }

  /// Unsubscribes from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  // ============================================================
  // Blocking & Reporting
  // ============================================================

  /// Blocks a user by their user ID.
  /// If a connection exists, updates it to blocked status.
  /// If no connection exists, creates a new blocked connection.
  Future<void> blockUserById(String otherUserId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      if (userId == otherUserId) {
        throw Exception('Cannot block yourself');
      }

      // Check if a connection already exists
      final existing = await getConnectionWith(otherUserId);

      if (existing != null) {
        // Update existing connection to blocked
        await _supabase
            .from('connections')
            .update({'status': 'blocked', 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', existing.id);
      } else {
        // Create a new blocked connection
        await _supabase.from('connections').insert({
          'requester_id': userId,
          'recipient_id': otherUserId,
          'status': 'blocked',
        });
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to block user: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to block user: $e');
    }
  }

  /// Reports a message for spam, harassment, or other violations.
  /// Can only report messages you have received.
  Future<MessageReport> reportMessage({
    required String messageId,
    required MessageReportReason reason,
    String? description,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('message_reports')
          .insert({
            'message_id': messageId,
            'reporter_id': userId,
            'reason': reason.name,
            if (description != null && description.isNotEmpty)
              'description': description,
          })
          .select()
          .single();

      return MessageReport.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation - already reported
        throw Exception('You have already reported this message');
      }
      throw Exception('Failed to report message: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to report message: $e');
    }
  }
}
