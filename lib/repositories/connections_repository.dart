import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/connection.dart';
import '../models/invitation.dart';
import '../models/message.dart';
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

  /// Creates an invitation to share via native share (WhatsApp, SMS, Email, etc.)
  /// Returns the invitation with the token/link to share
  Future<Invitation> createInvitation({
    String? message,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final token = _generateToken();

      final response = await _supabase
          .from('invitations')
          .insert({
            'inviter_id': userId,
            if (message != null && message.isNotEmpty) 'message': message,
            'token': token,
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

  /// Sends a message to another user (must be connected)
  Future<Message> sendMessage({
    required String recipientId,
    required String content,
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
        throw Exception('You can only message users you are connected with');
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
  // Real-time Subscriptions
  // ============================================================

  /// Subscribes to new messages for the current user
  RealtimeChannel subscribeToMessages({
    required void Function(Message message) onNewMessage,
  }) {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _supabase
        .channel('messages:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (payload) {
            final message = Message.fromJson(payload.newRecord);
            onNewMessage(message);
          },
        )
        .subscribe();
  }

  /// Subscribes to connection requests for the current user
  RealtimeChannel subscribeToConnectionRequests({
    required void Function(Connection connection) onNewRequest,
  }) {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated');
    }

    return _supabase
        .channel('connections:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'connections',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (payload) async {
            // Fetch full connection with profile data
            final connectionId = payload.newRecord['id'] as String;
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
          },
        )
        .subscribe();
  }

  /// Unsubscribes from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
