enum AlertPriority {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case AlertPriority.low:
        return 'Low';
      case AlertPriority.medium:
        return 'Medium';
      case AlertPriority.high:
        return 'High';
      case AlertPriority.critical:
        return 'Critical';
    }
  }

  String get dbValue => name;

  static AlertPriority fromString(String value) {
    switch (value) {
      case 'low':
        return AlertPriority.low;
      case 'medium':
        return AlertPriority.medium;
      case 'high':
        return AlertPriority.high;
      case 'critical':
        return AlertPriority.critical;
      default:
        return AlertPriority.medium;
    }
  }
}

class AlertDetails {
  final String id;
  final String postId;
  final AlertPriority priority;
  final bool isSticky;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime? stickyUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  AlertDetails({
    required this.id,
    required this.postId,
    this.priority = AlertPriority.medium,
    this.isSticky = false,
    this.verifiedBy,
    this.verifiedAt,
    this.stickyUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlertDetails.fromJson(Map<String, dynamic> json) {
    return AlertDetails(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      priority: AlertPriority.fromString(json['priority'] as String? ?? 'medium'),
      isSticky: json['is_sticky'] as bool? ?? false,
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      stickyUntil: json['sticky_until'] != null
          ? DateTime.parse(json['sticky_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Creates from flattened feed view data
  factory AlertDetails.fromFeedJson(Map<String, dynamic> json) {
    return AlertDetails(
      id: '',
      postId: json['id'] as String,
      priority: AlertPriority.fromString(json['alert_priority'] as String? ?? 'medium'),
      isSticky: json['alert_is_sticky'] as bool? ?? false,
      verifiedBy: null,
      verifiedAt: json['alert_verified_at'] != null
          ? DateTime.parse(json['alert_verified_at'] as String)
          : null,
      stickyUntil: null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'priority': priority.dbValue,
      'is_sticky': isSticky,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'sticky_until': stickyUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'priority': priority.dbValue,
      'is_sticky': isSticky,
      'sticky_until': stickyUntil?.toIso8601String(),
    };
  }

  bool get isVerified => verifiedAt != null;
  bool get isStickyActive =>
      isSticky && (stickyUntil == null || DateTime.now().isBefore(stickyUntil!));
}
