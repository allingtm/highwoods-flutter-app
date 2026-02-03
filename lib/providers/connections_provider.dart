import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/connection.dart';
import '../models/invitation.dart';
import '../models/message.dart';
import '../repositories/connections_repository.dart';

// ============================================================
// Repository Provider
// ============================================================

final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  return ConnectionsRepository();
});

// ============================================================
// Connections Provider
// ============================================================

/// Provider for user's accepted connections (friends)
class ConnectionsNotifier extends StateNotifier<AsyncValue<List<Connection>>> {
  ConnectionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final ConnectionsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final connections = await _repository.getConnections();
      state = AsyncValue.data(connections);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    try {
      final connections = await _repository.getConnections();
      state = AsyncValue.data(connections);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Remove a connection from the local state
  void removeConnection(String connectionId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.where((c) => c.id != connectionId).toList(),
    );
  }

  /// Add a new connection to local state
  void addConnection(Connection connection) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([connection, ...current]);
  }
}

final connectionsProvider =
    StateNotifierProvider<ConnectionsNotifier, AsyncValue<List<Connection>>>((ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return ConnectionsNotifier(repository);
});

// ============================================================
// Pending Requests Provider
// ============================================================

/// Provider for incoming connection requests
class PendingRequestsNotifier extends StateNotifier<AsyncValue<List<Connection>>> {
  PendingRequestsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final ConnectionsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final requests = await _repository.getPendingRequests();
      state = AsyncValue.data(requests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    try {
      final requests = await _repository.getPendingRequests();
      state = AsyncValue.data(requests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Remove a request from local state (after accept/reject)
  void removeRequest(String connectionId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.where((c) => c.id != connectionId).toList(),
    );
  }

  /// Add a new request to local state (from real-time)
  void addRequest(Connection request) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([request, ...current]);
  }
}

final pendingRequestsProvider =
    StateNotifierProvider<PendingRequestsNotifier, AsyncValue<List<Connection>>>((ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return PendingRequestsNotifier(repository);
});

/// Count of pending requests (for badge display)
final pendingRequestsCountProvider = Provider<int>((ref) {
  final requests = ref.watch(pendingRequestsProvider);
  return requests.valueOrNull?.length ?? 0;
});

// ============================================================
// Invitations Provider
// ============================================================

/// Provider for user's sent invitations
class InvitationsNotifier extends StateNotifier<AsyncValue<List<Invitation>>> {
  InvitationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final ConnectionsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final invitations = await _repository.getMyInvitations();
      state = AsyncValue.data(invitations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    try {
      final invitations = await _repository.getMyInvitations();
      state = AsyncValue.data(invitations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add a new invitation to local state
  void addInvitation(Invitation invitation) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([invitation, ...current]);
  }

  /// Remove an invitation from local state
  void removeInvitation(String invitationId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.where((i) => i.id != invitationId).toList(),
    );
  }
}

final invitationsProvider =
    StateNotifierProvider<InvitationsNotifier, AsyncValue<List<Invitation>>>((ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return InvitationsNotifier(repository);
});

// ============================================================
// Conversations Provider
// ============================================================

/// Provider for message conversations
class ConversationsNotifier extends StateNotifier<AsyncValue<List<Conversation>>> {
  ConversationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final ConnectionsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final conversations = await _repository.getConversations();
      state = AsyncValue.data(conversations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    try {
      final conversations = await _repository.getConversations();
      state = AsyncValue.data(conversations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update conversation when new message arrives
  void updateConversation(Message message) {
    final current = state.valueOrNull ?? [];
    final updatedConversations = current.map((c) {
      if (c.otherUser.id == message.senderId ||
          c.otherUser.id == message.recipientId) {
        return Conversation(
          otherUser: c.otherUser,
          lastMessage: message,
          unreadCount: message.isRead ? c.unreadCount : c.unreadCount + 1,
        );
      }
      return c;
    }).toList();

    // Sort by latest message
    updatedConversations.sort((a, b) =>
        b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt));

    state = AsyncValue.data(updatedConversations);
  }

  /// Mark conversation as read
  void markAsRead(String otherUserId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((c) {
        if (c.otherUser.id == otherUserId) {
          return Conversation(
            otherUser: c.otherUser,
            lastMessage: c.lastMessage,
            unreadCount: 0,
          );
        }
        return c;
      }).toList(),
    );
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<List<Conversation>>>((ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return ConversationsNotifier(repository);
});

/// Total unread message count (for badge display)
final unreadMessagesCountProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider);
  return conversations.valueOrNull?.fold<int>(
        0,
        (sum, conv) => sum + conv.unreadCount,
      ) ??
      0;
});

// ============================================================
// Messages Provider (per conversation)
// ============================================================

/// Provider for messages in a specific conversation
final messagesProvider = FutureProvider.family<List<Message>, String>(
  (ref, otherUserId) async {
    final repository = ref.watch(connectionsRepositoryProvider);
    return repository.getMessages(otherUserId: otherUserId);
  },
);

// ============================================================
// Connection Actions
// ============================================================

/// Send a connection request
Future<Connection> sendConnectionRequest(
  WidgetRef ref,
  String recipientId,
) async {
  final repository = ref.read(connectionsRepositoryProvider);
  final connection = await repository.sendConnectionRequest(recipientId);
  return connection;
}

/// Accept a connection request
Future<Connection> acceptConnectionRequest(
  WidgetRef ref,
  String connectionId,
) async {
  final repository = ref.read(connectionsRepositoryProvider);
  final connection = await repository.acceptRequest(connectionId);

  // Update local state
  ref.read(pendingRequestsProvider.notifier).removeRequest(connectionId);
  ref.read(connectionsProvider.notifier).addConnection(connection);

  return connection;
}

/// Reject a connection request
Future<void> rejectConnectionRequest(
  WidgetRef ref,
  String connectionId,
) async {
  final repository = ref.read(connectionsRepositoryProvider);
  await repository.rejectRequest(connectionId);

  // Update local state
  ref.read(pendingRequestsProvider.notifier).removeRequest(connectionId);
}

/// Remove a connection
Future<void> removeConnection(
  WidgetRef ref,
  String connectionId,
) async {
  final repository = ref.read(connectionsRepositoryProvider);
  await repository.removeConnection(connectionId);

  // Update local state
  ref.read(connectionsProvider.notifier).removeConnection(connectionId);
}

/// Create an invitation to share via native share
Future<Invitation> createInvitation(
  WidgetRef ref, {
  String? message,
}) async {
  final repository = ref.read(connectionsRepositoryProvider);
  final invitation = await repository.createInvitation(
    message: message,
  );

  // Update local state
  ref.read(invitationsProvider.notifier).addInvitation(invitation);

  return invitation;
}

/// Cancel an invitation
Future<void> cancelInvitation(
  WidgetRef ref,
  String invitationId,
) async {
  final repository = ref.read(connectionsRepositoryProvider);
  await repository.cancelInvitation(invitationId);

  // Update local state
  ref.read(invitationsProvider.notifier).removeInvitation(invitationId);
}

/// Send a message
///
/// If [postId] is provided, allows messaging post authors without requiring
/// a connection (for marketplace, jobs, lost & found inquiries).
Future<Message> sendMessage(
  WidgetRef ref, {
  required String recipientId,
  required String content,
  String? postId,
}) async {
  final repository = ref.read(connectionsRepositoryProvider);
  final message = await repository.sendMessage(
    recipientId: recipientId,
    content: content,
    postId: postId,
  );

  // Update conversations
  ref.read(conversationsProvider.notifier).updateConversation(message);

  return message;
}

/// Mark messages as read
Future<void> markMessagesAsRead(
  WidgetRef ref,
  String senderId,
) async {
  final repository = ref.read(connectionsRepositoryProvider);
  await repository.markMessagesAsRead(senderId);

  // Update local state
  ref.read(conversationsProvider.notifier).markAsRead(senderId);
}

// ============================================================
// Real-time Subscriptions
// ============================================================

/// Provider that manages real-time subscriptions for connections
final connectionsRealtimeProvider = Provider<ConnectionsRealtimeManager>((ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  final manager = ConnectionsRealtimeManager(ref, repository);

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

class ConnectionsRealtimeManager {
  ConnectionsRealtimeManager(this._ref, this._repository);

  final Ref _ref;
  final ConnectionsRepository _repository;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _connectionsChannel;

  void subscribeToMessages() {
    _messagesChannel = _repository.subscribeToMessages(
      onNewMessage: (message) {
        _ref.read(conversationsProvider.notifier).updateConversation(message);
      },
    );
  }

  void subscribeToConnectionRequests() {
    _connectionsChannel = _repository.subscribeToConnectionRequests(
      onNewRequest: (connection) {
        _ref.read(pendingRequestsProvider.notifier).addRequest(connection);
      },
    );
  }

  void subscribeAll() {
    subscribeToMessages();
    subscribeToConnectionRequests();
  }

  Future<void> dispose() async {
    if (_messagesChannel != null) {
      await _repository.unsubscribe(_messagesChannel!);
    }
    if (_connectionsChannel != null) {
      await _repository.unsubscribe(_connectionsChannel!);
    }
  }
}
