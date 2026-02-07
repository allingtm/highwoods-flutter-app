import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard/dashboard_models.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_color_palette.dart';
import '../../theme/app_theme.dart';

/// Daily mood check-in card with animated result bar.
class DashboardCheckIn extends ConsumerStatefulWidget {
  const DashboardCheckIn({
    super.key,
    required this.currentMood,
    required this.moodToday,
  });

  /// The user's already-submitted mood for today (null if not yet checked in).
  final String? currentMood;

  /// Today's community mood counts.
  final MoodCounts moodToday;

  @override
  ConsumerState<DashboardCheckIn> createState() => _DashboardCheckInState();
}

class _DashboardCheckInState extends ConsumerState<DashboardCheckIn> {
  String? _selectedMood;
  MoodCounts? _latestCounts;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.currentMood;
    if (widget.currentMood != null) {
      _latestCounts = widget.moodToday;
    }
  }

  @override
  void didUpdateWidget(DashboardCheckIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMood != widget.currentMood && widget.currentMood != null) {
      _selectedMood = widget.currentMood;
      _latestCounts = widget.moodToday;
    }
  }

  Future<void> _onMoodSelected(String mood) async {
    if (_submitting) return;
    setState(() {
      _selectedMood = mood;
      _submitting = true;
    });

    try {
      final counts = await ref
          .read(dashboardRepositoryProvider)
          .submitMoodCheckin(mood);
      if (mounted) {
        setState(() {
          _latestCounts = counts;
          _submitting = false;
        });
        // Refresh both stats providers
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(userDashboardStatsProvider);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: tokens.spacingLg,
        vertical: tokens.spacingSm,
      ),
      padding: EdgeInsets.all(tokens.spacingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How's Highwoods today?",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
          ),
          SizedBox(height: tokens.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MoodButton(
                emoji: '🔥',
                label: 'Buzzing',
                mood: 'buzzing',
                accentColor: colors.success,
                isSelected: _selectedMood == 'buzzing',
                onTap: () => _onMoodSelected('buzzing'),
              ),
              _MoodButton(
                emoji: '👍',
                label: 'Ticking Along',
                mood: 'ticking_along',
                accentColor: colors.warning,
                isSelected: _selectedMood == 'ticking_along',
                onTap: () => _onMoodSelected('ticking_along'),
              ),
              _MoodButton(
                emoji: '😴',
                label: 'Quiet',
                mood: 'quiet',
                accentColor: colors.secondary,
                isSelected: _selectedMood == 'quiet',
                onTap: () => _onMoodSelected('quiet'),
              ),
            ],
          ),
          // Results bar after check-in
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: _latestCounts != null
                ? _MoodResultBar(counts: _latestCounts!)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Mood Button
// ============================================================

class _MoodButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String mood;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.mood,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : colorScheme.outline,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 12)]
                    : null,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? accentColor
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Mood Result Bar
// ============================================================

class _MoodResultBar extends StatelessWidget {
  final MoodCounts counts;

  const _MoodResultBar({required this.counts});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = context.colors;
    final total = counts.total;

    if (total == 0) return const SizedBox.shrink();

    final buzzingFrac = counts.buzzing / total;
    final tickingFrac = counts.tickingAlong / total;
    final quietFrac = counts.quiet / total;

    return Padding(
      padding: EdgeInsets.only(top: tokens.spacingLg),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusSm),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (buzzingFrac > 0)
                    Expanded(
                      flex: (buzzingFrac * 100).round(),
                      child: Container(color: colors.success),
                    ),
                  if (tickingFrac > 0)
                    Expanded(
                      flex: (tickingFrac * 100).round(),
                      child: Container(color: colors.warning),
                    ),
                  if (quietFrac > 0)
                    Expanded(
                      flex: (quietFrac * 100).round(),
                      child: Container(color: colors.secondary),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: tokens.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CountLabel(
                emoji: '🔥',
                count: counts.buzzing,
                color: colors.success,
              ),
              _CountLabel(
                emoji: '👍',
                count: counts.tickingAlong,
                color: colors.warning,
              ),
              _CountLabel(
                emoji: '😴',
                count: counts.quiet,
                color: colors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountLabel extends StatelessWidget {
  final String emoji;
  final int count;
  final Color color;

  const _CountLabel({
    required this.emoji,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}
