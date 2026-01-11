import 'package:flutter/material.dart';

class EventDetails {
  final String id;
  final String postId;
  final DateTime eventDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final String? venueName;
  final String? address;
  final int? maxAttendees;
  final int currentAttendees;
  final bool rsvpRequired;
  final DateTime? rsvpDeadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventDetails({
    required this.id,
    required this.postId,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.venueName,
    this.address,
    this.maxAttendees,
    this.currentAttendees = 0,
    this.rsvpRequired = false,
    this.rsvpDeadline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventDetails.fromJson(Map<String, dynamic> json) {
    return EventDetails(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      startTime: _parseTime(json['start_time'] as String?),
      endTime: _parseTime(json['end_time'] as String?),
      isAllDay: json['is_all_day'] as bool? ?? false,
      venueName: json['venue_name'] as String?,
      address: json['address'] as String?,
      maxAttendees: json['max_attendees'] as int?,
      currentAttendees: json['current_attendees'] as int? ?? 0,
      rsvpRequired: json['rsvp_required'] as bool? ?? false,
      rsvpDeadline: json['rsvp_deadline'] != null
          ? DateTime.parse(json['rsvp_deadline'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Creates from flattened feed view data
  factory EventDetails.fromFeedJson(Map<String, dynamic> json) {
    return EventDetails(
      id: '',
      postId: json['id'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      startTime: _parseTime(json['start_time'] as String?),
      endTime: _parseTime(json['end_time'] as String?),
      isAllDay: false,
      venueName: json['venue_name'] as String?,
      address: null,
      maxAttendees: json['max_attendees'] as int?,
      currentAttendees: json['current_attendees'] as int? ?? 0,
      rsvpRequired: false,
      rsvpDeadline: null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at'] as String),
    );
  }

  static TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'is_all_day': isAllDay,
      'venue_name': venueName,
      'address': address,
      'max_attendees': maxAttendees,
      'current_attendees': currentAttendees,
      'rsvp_required': rsvpRequired,
      'rsvp_deadline': rsvpDeadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'event_date': eventDate.toIso8601String().split('T')[0],
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'is_all_day': isAllDay,
      'venue_name': venueName,
      'address': address,
      'max_attendees': maxAttendees,
      'rsvp_required': rsvpRequired,
      'rsvp_deadline': rsvpDeadline?.toIso8601String(),
    };
  }

  String get timeDisplay {
    if (isAllDay) return 'All day';
    if (startTime == null) return '';
    final start = '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
    if (endTime == null) return start;
    final end = '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  String get attendeesDisplay {
    if (maxAttendees == null) return '$currentAttendees attending';
    return '$currentAttendees / $maxAttendees attending';
  }

  bool get isFull => maxAttendees != null && currentAttendees >= maxAttendees!;
  bool get isRsvpOpen => rsvpDeadline == null || DateTime.now().isBefore(rsvpDeadline!);
}
