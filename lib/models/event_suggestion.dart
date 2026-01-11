/// Represents an event suggestion submitted by a user
class EventSuggestion {
  final String id;
  final String suggesterId;
  final String title;
  final String? description;
  final DateTime? suggestedDate;
  final String? location;
  final DateTime createdAt;

  EventSuggestion({
    required this.id,
    required this.suggesterId,
    required this.title,
    this.description,
    this.suggestedDate,
    this.location,
    required this.createdAt,
  });

  factory EventSuggestion.fromJson(Map<String, dynamic> json) {
    return EventSuggestion(
      id: json['id'] as String,
      suggesterId: json['suggester_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      suggestedDate: json['suggested_date'] != null
          ? DateTime.parse(json['suggested_date'] as String)
          : null,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'suggester_id': suggesterId,
      'title': title,
      if (description != null) 'description': description,
      if (suggestedDate != null)
        'suggested_date': suggestedDate!.toIso8601String().split('T').first,
      if (location != null) 'location': location,
    };
  }
}
