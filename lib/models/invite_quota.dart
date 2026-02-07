/// Represents the user's invitation quota/limit state
class InviteQuota {
  final int limit;
  final int used;
  final int remaining;
  final int acceptedCount;
  final bool isAtCap;

  const InviteQuota({
    required this.limit,
    required this.used,
    required this.remaining,
    required this.acceptedCount,
    required this.isAtCap,
  });

  factory InviteQuota.fromJson(Map<String, dynamic> json) {
    return InviteQuota(
      limit: json['limit'] as int,
      used: json['used'] as int,
      remaining: json['remaining'] as int,
      acceptedCount: json['accepted_count'] as int,
      isAtCap: json['is_at_cap'] as bool,
    );
  }

  /// Whether the user has any invitations remaining
  bool get hasRemaining => remaining > 0;

  /// Whether the user is waiting for accepts to unlock more
  bool get waitingForAccepts => !hasRemaining && !isAtCap;

  /// User-facing status message
  String get statusMessage {
    if (isAtCap && !hasRemaining) {
      return 'You\'ve reached the maximum invitation limit. Contact an admin for more.';
    }
    if (!hasRemaining) {
      return 'All invites used. When someone accepts, you\'ll earn 5 more.';
    }
    return '$remaining of $limit invitations remaining';
  }
}
