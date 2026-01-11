import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/calendar_event.dart';
import '../models/event_suggestion.dart';

/// Repository for calendar events (read-only) and event suggestions
class CalendarRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Gets the current user's ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ============================================================
  // Calendar Events (Read-only - admin managed)
  // ============================================================

  /// Gets events for a specific month
  Future<List<CalendarEvent>> getEventsForMonth(int year, int month) async {
    try {
      // Get first and last day of month
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0);

      final response = await _supabase
          .from('calendar_events')
          .select()
          .gte('event_date', firstDay.toIso8601String().split('T').first)
          .lte('event_date', lastDay.toIso8601String().split('T').first)
          .order('event_date')
          .order('start_time');

      return (response as List<dynamic>)
          .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch events: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  /// Gets events for a specific date
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;

      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('event_date', dateStr)
          .order('start_time');

      return (response as List<dynamic>)
          .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch events: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  /// Gets upcoming events (from today onwards)
  Future<List<CalendarEvent>> getUpcomingEvents({int limit = 10}) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;

      final response = await _supabase
          .from('calendar_events')
          .select()
          .gte('event_date', today)
          .order('event_date')
          .order('start_time')
          .limit(limit);

      return (response as List<dynamic>)
          .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch upcoming events: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch upcoming events: $e');
    }
  }

  /// Gets a single event by ID
  Future<CalendarEvent> getEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('id', eventId)
          .single();

      return CalendarEvent.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch event: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  // ============================================================
  // Event Suggestions (Users can submit)
  // ============================================================

  /// Submits an event suggestion
  Future<EventSuggestion> submitSuggestion({
    required String title,
    String? description,
    DateTime? suggestedDate,
    String? location,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('event_suggestions')
          .insert({
            'suggester_id': userId,
            'title': title,
            if (description != null) 'description': description,
            if (suggestedDate != null)
              'suggested_date': suggestedDate.toIso8601String().split('T').first,
            if (location != null) 'location': location,
          })
          .select()
          .single();

      return EventSuggestion.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit suggestion: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit suggestion: $e');
    }
  }

  /// Gets the current user's suggestions
  Future<List<EventSuggestion>> getMySuggestions() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('event_suggestions')
          .select()
          .eq('suggester_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => EventSuggestion.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch suggestions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch suggestions: $e');
    }
  }
}
