import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RealtimeStatus { connected, connecting, disconnected }

/// Tracks the Supabase Realtime connection status.
/// Updated by [PresenceManager] from the always-on presence channel.
final realtimeStatusProvider = StateProvider<RealtimeStatus>(
  (ref) => RealtimeStatus.connecting,
);
