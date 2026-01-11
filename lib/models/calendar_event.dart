import 'package:flutter/material.dart';

/// Represents a calendar event (admin-managed)
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? location;
  final String? imageUrl;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.location,
    this.imageUrl,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      startTime: json['start_time'] != null
          ? _parseTime(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? _parseTime(json['end_time'] as String)
          : null,
      location: json['location'] as String?,
      imageUrl: json['image_url'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Parse time string (HH:MM:SS) to TimeOfDay
  static TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Format time for display (e.g., "2:30 PM")
  String? get formattedStartTime {
    if (startTime == null) return null;
    return _formatTimeOfDay(startTime!);
  }

  String? get formattedEndTime {
    if (endTime == null) return null;
    return _formatTimeOfDay(endTime!);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Get formatted time range (e.g., "2:30 PM - 4:00 PM")
  String? get timeRange {
    if (startTime == null && endTime == null) return null;
    if (startTime != null && endTime != null) {
      return '${formattedStartTime!} - ${formattedEndTime!}';
    }
    return formattedStartTime ?? formattedEndTime;
  }

  /// Get formatted date (e.g., "Saturday, 15 January 2025")
  String get formattedDate {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];

    final weekday = weekdays[eventDate.weekday - 1];
    final month = months[eventDate.month - 1];
    return '$weekday, ${eventDate.day} $month ${eventDate.year}';
  }

  /// Get short formatted date (e.g., "15 Jan")
  String get shortDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${eventDate.day} ${months[eventDate.month - 1]}';
  }

  /// Check if event is today
  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }

  /// Check if event is in the past
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eventDay.isBefore(today);
  }
}
