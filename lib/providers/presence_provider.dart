import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'realtime_status_provider.dart';

// ============================================================
// Online Users State
// ============================================================

/// Set of currently online user IDs
final onlineUsersProvider = StateProvider<Set<String>>((ref) => {});

/// Check if a specific user is online
final isUserOnlineProvider = Provider.family<bool, String>((ref, userId) {
  final onlineUsers = ref.watch(onlineUsersProvider);
  return onlineUsers.contains(userId);
});

// ============================================================
// Presence Manager
// ============================================================

class PresenceManager {
  PresenceManager(this._ref);

  final Ref _ref;
  RealtimeChannel? _channel;
  bool _isTracking = false;
  bool _hasConnected = false;

  void startTracking() {
    if (_isTracking) return;

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    _isTracking = true;

    _channel = client.channel(
      'presence:app',
      opts: RealtimeChannelConfig(key: userId, private: true),
    );

    _channel!.onPresenceSync((_) {
      final state = _channel!.presenceState();
      final onlineIds = <String>{};
      for (final entry in state) {
        onlineIds.add(entry.key);
      }
      _ref.read(onlineUsersProvider.notifier).state = onlineIds;
    }).subscribe((status, error) async {
      // Update global connection status from this always-on channel
      switch (status) {
        case RealtimeSubscribeStatus.subscribed:
          _hasConnected = true;
          _ref.read(realtimeStatusProvider.notifier).state =
              RealtimeStatus.connected;
          try {
            await _channel!.track({
              'user_id': userId,
              'online_at': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            debugPrint('Error tracking presence: $e');
          }
          break;
        case RealtimeSubscribeStatus.channelError:
        case RealtimeSubscribeStatus.timedOut:
          // Only show "disconnected" if we were previously connected.
          // Transient errors during initial connection (e.g. tenant waking up)
          // should not flash the banner.
          if (_hasConnected) {
            _ref.read(realtimeStatusProvider.notifier).state =
                RealtimeStatus.disconnected;
          }
          break;
        default:
          break;
      }
    });
  }

  Future<void> dispose() async {
    _isTracking = false;
    if (_channel != null) {
      try {
        await _channel!.untrack();
      } catch (e) {
        debugPrint('Error untracking presence: $e');
      }
      await Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
    _ref.read(onlineUsersProvider.notifier).state = {};
  }
}

final presenceProvider = Provider<PresenceManager>((ref) {
  final manager = PresenceManager(ref);
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});
