import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_event.dart';
import '../repositories/calendar_repository.dart';

// ============================================================
// Repository Provider
// ============================================================

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});

// ============================================================
// Calendar Events Providers
// ============================================================

/// State for calendar view
class CalendarState {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Map<DateTime, List<CalendarEvent>> eventsByDate;
  final List<CalendarEvent> selectedDateEvents;
  final bool isLoading;
  final String? error;

  const CalendarState({
    required this.focusedMonth,
    this.selectedDate,
    this.eventsByDate = const {},
    this.selectedDateEvents = const [],
    this.isLoading = false,
    this.error,
  });

  CalendarState copyWith({
    DateTime? focusedMonth,
    DateTime? selectedDate,
    Map<DateTime, List<CalendarEvent>>? eventsByDate,
    List<CalendarEvent>? selectedDateEvents,
    bool? isLoading,
    String? error,
    bool clearSelectedDate = false,
  }) {
    return CalendarState(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      eventsByDate: eventsByDate ?? this.eventsByDate,
      selectedDateEvents: selectedDateEvents ?? this.selectedDateEvents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for calendar state
class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier(this._repository)
      : super(CalendarState(
          focusedMonth: DateTime.now(),
          selectedDate: DateTime.now(),
        )) {
    _loadCurrentMonth();
  }

  final CalendarRepository _repository;

  Future<void> _loadCurrentMonth() async {
    await loadMonth(state.focusedMonth.year, state.focusedMonth.month);
    // Also load events for today
    if (state.selectedDate != null) {
      await _loadEventsForDate(state.selectedDate!);
    }
  }

  /// Load events for a specific month
  Future<void> loadMonth(int year, int month) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await _repository.getEventsForMonth(year, month);

      // Group events by date
      final eventsByDate = <DateTime, List<CalendarEvent>>{};
      for (final event in events) {
        final dateKey = DateTime(
          event.eventDate.year,
          event.eventDate.month,
          event.eventDate.day,
        );
        eventsByDate.putIfAbsent(dateKey, () => []).add(event);
      }

      state = state.copyWith(
        eventsByDate: eventsByDate,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Change focused month
  Future<void> setFocusedMonth(DateTime month) async {
    state = state.copyWith(focusedMonth: month);
    await loadMonth(month.year, month.month);
  }

  /// Select a date
  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(selectedDate: date);
    await _loadEventsForDate(date);
  }

  /// Load events for a specific date
  Future<void> _loadEventsForDate(DateTime date) async {
    final dateKey = DateTime(date.year, date.month, date.day);

    // Check if we already have events for this date
    if (state.eventsByDate.containsKey(dateKey)) {
      state = state.copyWith(
        selectedDateEvents: state.eventsByDate[dateKey] ?? [],
      );
    } else {
      // Fetch from server
      try {
        final events = await _repository.getEventsForDate(date);
        state = state.copyWith(selectedDateEvents: events);
      } catch (e) {
        state = state.copyWith(selectedDateEvents: []);
      }
    }
  }

  /// Refresh current month
  Future<void> refresh() async {
    await loadMonth(state.focusedMonth.year, state.focusedMonth.month);
    if (state.selectedDate != null) {
      await _loadEventsForDate(state.selectedDate!);
    }
  }

  /// Get events for a specific date (for calendar markers)
  List<CalendarEvent> getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return state.eventsByDate[dateKey] ?? [];
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  final repository = ref.watch(calendarRepositoryProvider);
  return CalendarNotifier(repository);
});

/// Provider for upcoming events (for quick access/preview)
final upcomingEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.getUpcomingEvents(limit: 5);
});

/// Provider for a single event detail
final eventDetailProvider = FutureProvider.family<CalendarEvent, String>(
  (ref, eventId) async {
    final repository = ref.watch(calendarRepositoryProvider);
    return repository.getEvent(eventId);
  },
);

// ============================================================
// Event Suggestion Action
// ============================================================

/// Submit an event suggestion
Future<void> submitEventSuggestion(
  WidgetRef ref, {
  required String title,
  String? description,
  DateTime? suggestedDate,
  String? location,
}) async {
  final repository = ref.read(calendarRepositoryProvider);
  await repository.submitSuggestion(
    title: title,
    description: description,
    suggestedDate: suggestedDate,
    location: location,
  );
}
