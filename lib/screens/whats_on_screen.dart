import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_tokens.dart';

class WhatsOnScreen extends ConsumerStatefulWidget {
  const WhatsOnScreen({super.key, this.onMenuTap});

  /// Callback to open the side menu drawer
  final VoidCallback? onMenuTap;

  @override
  ConsumerState<WhatsOnScreen> createState() => _WhatsOnScreenState();
}

class _WhatsOnScreenState extends ConsumerState<WhatsOnScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final calendarState = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppBar(
        leading: widget.onMenuTap != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: widget.onMenuTap,
                tooltip: 'Open menu',
              )
            : null,
        title: const Text("What's On"),
      ),
      body: Column(
        children: [
          // Calendar
          _buildCalendar(context, tokens, colorScheme, calendarState),

          // Divider
          Divider(height: 1, color: colorScheme.outlineVariant),

          // Events list for selected date
          Expanded(
            child: _buildEventsList(context, tokens, colorScheme, calendarState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showSuggestEventSheet(context, tokens, colorScheme),
        icon: const Icon(Icons.add),
        label: const Text('Suggest Event'),
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    CalendarState calendarState,
  ) {
    final notifier = ref.read(calendarProvider.notifier);

    return TableCalendar<CalendarEvent>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: calendarState.focusedMonth,
      selectedDayPredicate: (day) {
        return calendarState.selectedDate != null &&
            isSameDay(calendarState.selectedDate!, day);
      },
      calendarFormat: _calendarFormat,
      eventLoader: (day) => notifier.getEventsForDay(day),
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        // Today styling
        todayDecoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
        // Selected day styling
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
        // Event markers
        markerDecoration: BoxDecoration(
          color: colorScheme.tertiary,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerSize: 6,
        markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        // Weekend styling
        weekendTextStyle: TextStyle(color: colorScheme.error),
        // Outside days
        outsideDaysVisible: false,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonDecoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        formatButtonTextStyle: TextStyle(color: colorScheme.onSurface),
        leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
        rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        notifier.selectDate(selectedDay);
        notifier.setFocusedMonth(focusedDay);
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        notifier.setFocusedMonth(focusedDay);
      },
    );
  }

  Widget _buildEventsList(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    CalendarState calendarState,
  ) {
    if (calendarState.isLoading && calendarState.selectedDateEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (calendarState.selectedDate == null) {
      return _buildNoDateSelected(context, tokens, colorScheme);
    }

    final events = calendarState.selectedDateEvents;
    final selectedDate = calendarState.selectedDate!;

    if (events.isEmpty) {
      return _buildNoEvents(context, tokens, colorScheme, selectedDate);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(calendarProvider.notifier).refresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(tokens.spacingLg),
        itemCount: events.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            // Date header
            return Padding(
              padding: EdgeInsets.only(bottom: tokens.spacingMd),
              child: Text(
                _formatDateHeader(selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            );
          }

          final event = events[index - 1];
          return _EventCard(
            event: event,
            tokens: tokens,
            colorScheme: colorScheme,
            onTap: () => context.push('/whatson/event/${event.id}'),
          );
        },
      ),
    );
  }

  Widget _buildNoDateSelected(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: tokens.iconXl,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: tokens.spacingLg),
          Text(
            'Select a date',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spacingSm),
          Text(
            'Tap a date on the calendar to see events',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEvents(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    DateTime date,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: tokens.iconXl,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: tokens.spacingLg),
          Text(
            'No events',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spacingSm),
          Text(
            'Nothing scheduled for ${_formatDateHeader(date)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    }
  }

  void _showSuggestEventSheet(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SuggestEventSheet(
        tokens: tokens,
        colorScheme: colorScheme,
      ),
    );
  }
}

// ============================================================
// Event Card
// ============================================================

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final AppThemeTokens tokens;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.tokens,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: tokens.spacingMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Time column
            Container(
              width: 80,
              padding: EdgeInsets.all(tokens.spacingMd),
              color: event.isFeatured
                  ? colorScheme.tertiaryContainer
                  : colorScheme.surfaceContainerHighest,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (event.startTime != null) ...[
                    Text(
                      event.formattedStartTime!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: event.isFeatured
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Icon(
                      Icons.schedule,
                      size: tokens.iconSm,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: tokens.spacingXs),
                    Text(
                      'All day',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),

            // Event details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(tokens.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured badge
                    if (event.isFeatured) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spacingSm,
                          vertical: tokens.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(tokens.radiusSm),
                        ),
                        child: Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                      SizedBox(height: tokens.spacingSm),
                    ],

                    // Title
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Location
                    if (event.location != null) ...[
                      SizedBox(height: tokens.spacingXs),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: tokens.spacingXs),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Chevron
            Padding(
              padding: EdgeInsets.only(right: tokens.spacingMd),
              child: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Suggest Event Sheet
// ============================================================

class _SuggestEventSheet extends ConsumerStatefulWidget {
  final AppThemeTokens tokens;
  final ColorScheme colorScheme;

  const _SuggestEventSheet({
    required this.tokens,
    required this.colorScheme,
  });

  @override
  ConsumerState<_SuggestEventSheet> createState() => _SuggestEventSheetState();
}

class _SuggestEventSheetState extends ConsumerState<_SuggestEventSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _suggestedDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(widget.tokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Suggest an Event',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              SizedBox(height: widget.tokens.spacingSm),

              Text(
                'Submit your event idea and our team will review it.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.colorScheme.onSurfaceVariant,
                    ),
              ),

              SizedBox(height: widget.tokens.spacingXl),

              // Title (required)
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title *',
                  hintText: 'e.g., Community BBQ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(widget.tokens.radiusMd),
                  ),
                ),
                maxLength: 200,
                textCapitalization: TextCapitalization.words,
              ),

              SizedBox(height: widget.tokens.spacingMd),

              // Description (optional)
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Tell us more about the event...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(widget.tokens.radiusMd),
                  ),
                ),
                maxLines: 3,
                maxLength: 1000,
              ),

              SizedBox(height: widget.tokens.spacingMd),

              // Date picker (optional)
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(widget.tokens.radiusMd),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Suggested Date (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.tokens.radiusMd),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _suggestedDate != null
                        ? _formatDate(_suggestedDate!)
                        : 'Tap to select a date',
                    style: TextStyle(
                      color: _suggestedDate != null
                          ? widget.colorScheme.onSurface
                          : widget.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              SizedBox(height: widget.tokens.spacingMd),

              // Location (optional)
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (optional)',
                  hintText: 'e.g., Community Hall',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(widget.tokens.radiusMd),
                  ),
                ),
                maxLength: 500,
              ),

              SizedBox(height: widget.tokens.spacingLg),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Suggestion'),
                ),
              ),

              SizedBox(height: widget.tokens.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _suggestedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _suggestedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await submitEventSuggestion(
        ref,
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        suggestedDate: _suggestedDate,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Admins have received your event suggestion.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }
}
