import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../models/dashboard/dashboard_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';

/// Monthly personal summary card with share/screenshot functionality.
class PersonalWrappedCard extends StatelessWidget {
  const PersonalWrappedCard({super.key, required this.wrapped});

  final PersonalWrapped wrapped;

  @override
  Widget build(BuildContext context) {
    if (!wrapped.hasActivity) return const SizedBox.shrink();

    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
      child: _WrappedContent(
        wrapped: wrapped,
        colorScheme: colorScheme,
        tokens: tokens,
        textTheme: Theme.of(context).textTheme,
      ),
    );
  }
}

class _WrappedContent extends StatefulWidget {
  const _WrappedContent({
    required this.wrapped,
    required this.colorScheme,
    required this.tokens,
    required this.textTheme,
  });

  final PersonalWrapped wrapped;
  final ColorScheme colorScheme;
  final AppThemeTokens tokens;
  final TextTheme textTheme;

  @override
  State<_WrappedContent> createState() => _WrappedContentState();
}

class _WrappedContentState extends State<_WrappedContent> {
  final _repaintKey = GlobalKey();

  Future<void> _shareWrapped() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // For now, show a snackbar. Full share_plus integration can be added later.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Screenshot captured! Share feature coming soon.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture screenshot')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.wrapped;
    final cs = widget.colorScheme;
    final tokens = widget.tokens;
    final textTheme = widget.textTheme;

    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(tokens.spacingXl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusXl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your ${w.monthName} in Highwoods',
              style: textTheme.titleLarge?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.spacingLg),

            // Stat circles row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCircle(value: '${w.posts}', label: 'Posts', color: cs.onPrimary),
                _StatCircle(value: '${w.comments}', label: 'Comments', color: cs.onPrimary),
                _StatCircle(value: '${w.reactionsReceived}', label: 'Reactions', color: cs.onPrimary),
                _StatCircle(value: '${w.eventsAttended}', label: 'Events', color: cs.onPrimary),
              ],
            ),
            SizedBox(height: tokens.spacingLg),

            // Engagement percentile
            if (w.engagementPercentile != null) ...[
              Text(
                'Top ${100 - w.engagementPercentile!}% of engaged residents',
                style: textTheme.labelLarge?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: tokens.spacingLg),
            ],

            // Footer
            Row(
              children: [
                Text(
                  'Highwoods',
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onPrimary.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _shareWrapped,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ios_share,
                        size: 16,
                        color: cs.onPrimary.withValues(alpha: 0.8),
                      ),
                      SizedBox(width: tokens.spacingXs),
                      Text(
                        'Share',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Stat Circle
// ============================================================

class _StatCircle extends StatelessWidget {
  const _StatCircle({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
