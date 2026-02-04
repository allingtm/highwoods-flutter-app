/// Reasons for reporting a message
enum MessageReportReason {
  spam,
  harassment,
  inappropriate,
  scam,
  other;

  String get displayName {
    switch (this) {
      case MessageReportReason.spam:
        return 'Spam';
      case MessageReportReason.harassment:
        return 'Harassment';
      case MessageReportReason.inappropriate:
        return 'Inappropriate content';
      case MessageReportReason.scam:
        return 'Scam';
      case MessageReportReason.other:
        return 'Other';
    }
  }

  static MessageReportReason fromString(String value) {
    return MessageReportReason.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageReportReason.other,
    );
  }
}

/// Status of a message report
enum MessageReportStatus {
  pending,
  reviewed,
  actioned,
  dismissed;

  static MessageReportStatus fromString(String value) {
    return MessageReportStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageReportStatus.pending,
    );
  }
}

/// Represents a report against a message
class MessageReport {
  final String id;
  final String messageId;
  final String reporterId;
  final MessageReportReason reason;
  final String? description;
  final MessageReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? actionTaken;
  final DateTime createdAt;

  MessageReport({
    required this.id,
    required this.messageId,
    required this.reporterId,
    required this.reason,
    this.description,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.actionTaken,
    required this.createdAt,
  });

  factory MessageReport.fromJson(Map<String, dynamic> json) {
    return MessageReport(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      reporterId: json['reporter_id'] as String,
      reason: MessageReportReason.fromString(json['reason'] as String),
      description: json['description'] as String?,
      status: MessageReportStatus.fromString(json['status'] as String),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      actionTaken: json['action_taken'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'reporter_id': reporterId,
      'reason': reason.name,
      if (description != null) 'description': description,
      'status': status.name,
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (actionTaken != null) 'action_taken': actionTaken,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
