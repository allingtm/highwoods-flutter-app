import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_color_palette.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final welcomeBackground = context.colors.background;

    return Scaffold(
      backgroundColor: welcomeBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Static logo at top - 20% of screen height
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.20,
              child: Center(
                child: Image.asset(
                  'assets/images/highwoods-app-logo.png',
                  width: 200,
                ),
              ),
            ),
            // Swipeable pages taking up remaining space
            Expanded(
              flex: 1,
              child: IntroductionScreen(
                pages: [
                  _buildPage(
                    context,
                    icon: Icons.people_outline,
                    title: 'Connect',
                    description:
                        'Meet and connect with your neighbours in Highwoods and the surrounding areas',
                    iconAnimation: (child) => FadeInDown(child: child),
                    graphicPlaceholder: 'connect',
                  ),
                  _buildPage(
                    context,
                    icon: Icons.share_outlined,
                    title: 'Share',
                    description:
                        'Share recommendations, local tips, and discover what\'s happening in your neighbourhood',
                    iconAnimation: (child) => FadeInDown(child: child),
                    graphicPlaceholder: 'share',
                  ),
                  _buildPage(
                    context,
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Community',
                    description:
                        'Build a stronger, more connected community together with your fellow residents',
                    iconAnimation: (child) => FadeInDown(child: child),
                    graphicPlaceholder: 'community',
                  ),
                ],
                onDone: () => context.go('/login'),
                onSkip: () => context.go('/login'),
                showSkipButton: true,
                skip: Text(
                  'Skip',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                next: Container(
                  padding: EdgeInsets.all(tokens.spacingSm),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: colorScheme.onPrimary,
                  ),
                ),
                done: Container(
                  padding: EdgeInsets.all(tokens.spacingSm),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: colorScheme.onPrimary,
                  ),
                ),
                showBackButton: true,
                back: Container(
                  padding: EdgeInsets.all(tokens.spacingSm),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: colorScheme.onSurface,
                  ),
                ),
                dotsDecorator: DotsDecorator(
                  size: const Size(10, 10),
                  activeSize: const Size(22, 10),
                  activeColor: colorScheme.primary,
                  color: colorScheme.outline.withValues(alpha: 0.4),
                  activeShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                globalBackgroundColor: welcomeBackground,
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PageViewModel _buildPage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Widget Function(Widget child) iconAnimation,
    required String graphicPlaceholder,
  }) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PageViewModel(
      titleWidget: FadeIn(
        delay: const Duration(milliseconds: 300),
        child: Row(
          children: [
            iconAnimation(
              Container(
                padding: EdgeInsets.all(tokens.spacingSm),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
            ),
            SizedBox(width: tokens.spacingMd),
            Text(
              title,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      bodyWidget: _StableTypewriter(
        text: description,
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      image: FadeInUp(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacingXl),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: tokens.spacingSm),
                    Text(
                      '$graphicPlaceholder graphic',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      decoration: PageDecoration(
        imagePadding: EdgeInsets.only(bottom: tokens.spacingLg),
        bodyPadding: EdgeInsets.symmetric(horizontal: tokens.spacingXl),
        titlePadding: EdgeInsets.only(
          left: tokens.spacingXl,
          right: tokens.spacingXl,
          top: tokens.spacingMd,
          bottom: tokens.spacingMd,
        ),
      ),
    );
  }
}

/// Typewriter effect that pre-computes line breaks to prevent word jumping.
/// Each line is rendered as a separate non-wrapping widget.
class _StableTypewriter extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _StableTypewriter({
    required this.text,
    this.style,
  });

  @override
  State<_StableTypewriter> createState() => _StableTypewriterState();
}

class _StableTypewriterState extends State<_StableTypewriter> {
  int _charIndex = 0;
  Timer? _timer;
  bool _showCursor = false;
  Timer? _cursorTimer;
  List<String> _lines = [];
  double? _maxWidth;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Delay before starting to type
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _started = true;
        });
        _startTyping();
        _startCursorBlink();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    void typeNextChar() {
      if (!mounted) return;
      if (_charIndex < widget.text.length) {
        // Show cursor, then type character, then briefly hide cursor
        setState(() {
          _showCursor = true;
        });
        // After a brief moment, type the character
        _timer = Timer(const Duration(milliseconds: 40), () {
          if (!mounted) return;
          setState(() {
            _charIndex++;
            _showCursor = false;
          });
          // Then show cursor again and schedule next char
          _cursorTimer = Timer(const Duration(milliseconds: 27), () {
            if (!mounted) return;
            setState(() {
              _showCursor = true;
            });
            typeNextChar();
          });
        });
      } else {
        // Typing complete, hide cursor
        setState(() {
          _showCursor = false;
        });
      }
    }

    typeNextChar();
  }

  void _startCursorBlink() {
    // Cursor blinking is now handled by _startTyping
  }

  /// Get the next character to be typed
  String? _getNextChar() {
    if (_charIndex >= widget.text.length) return null;
    return widget.text[_charIndex];
  }

  /// Pre-compute line breaks by measuring each word
  /// The cursor can appear after any character, so we need to ensure
  /// that any partial line + cursor fits within maxWidth
  List<String> _computeLines(
      double maxWidth, TextStyle? style, double textScaler) {
    final words = widget.text.split(' ');
    final lines = <String>[];
    var currentLine = '';

    double measureText(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.linear(textScaler),
      )..layout();
      return painter.width;
    }

    // Measure cursor width plus safety margin
    final cursorWidth = measureText('|W');

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final testLine = currentLine.isEmpty ? word : '$currentLine $word';
      // The cursor could appear at the end of this line, so account for it
      final testWidth = measureText(testLine) + cursorWidth;

      if (testWidth <= maxWidth) {
        currentLine = testLine;
      } else {
        // Word doesn't fit - start new line
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
        }
        currentLine = word;
      }
    }

    // Add remaining text
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Recompute lines if width changed
        final textScaler = MediaQuery.textScalerOf(context).scale(1.0);
        if (_maxWidth != constraints.maxWidth) {
          _maxWidth = constraints.maxWidth;
          _lines = _computeLines(constraints.maxWidth, widget.style, textScaler);
        }

        // Calculate how many characters to show on each line
        var remainingChars = _charIndex;
        final lineContents = <String>[];
        int? cursorLineIndex;
        int? cursorPositionInLine;

        for (var i = 0; i < _lines.length; i++) {
          final line = _lines[i];
          // Account for space between lines (except first line)
          final charsNeededForLine = i == 0 ? line.length : line.length + 1;

          if (remainingChars <= 0) {
            lineContents.add('');
          } else if (remainingChars >= charsNeededForLine) {
            lineContents.add(line);
            remainingChars -= charsNeededForLine;
          } else {
            // Partial line - cursor is here
            // For lines after first, first char consumed is the space
            if (i > 0 && remainingChars == 1) {
              // Only the space is typed, line appears empty
              lineContents.add('');
              cursorLineIndex = i;
              cursorPositionInLine = 0;
            } else {
              final charsToShow = i == 0 ? remainingChars : remainingChars - 1;
              lineContents.add(line.substring(0, charsToShow));
              cursorLineIndex = i;
              cursorPositionInLine = charsToShow;
            }
            remainingChars = 0;
          }
        }

        // If we've shown all chars but cursor line not set, cursor is at end
        if (cursorLineIndex == null && _charIndex < widget.text.length) {
          cursorLineIndex = lineContents.length - 1;
          cursorPositionInLine = lineContents.last.length;
        }

        final isTyping = _charIndex < widget.text.length && _started;

        // Only show lines that have content or are currently being typed
        final linesToShow = <Widget>[];
        for (var index = 0; index < _lines.length; index++) {
          final content =
              index < lineContents.length ? lineContents[index] : '';
          final showCursorOnThisLine = isTyping && cursorLineIndex == index;

          // Skip lines that haven't started yet (empty and cursor not on them)
          if (content.isEmpty && !showCursorOnThisLine) {
            continue;
          }

          linesToShow.add(
            SizedBox(
              width: constraints.maxWidth,
              child: Text.rich(
                TextSpan(
                  style: widget.style,
                  children: [
                    TextSpan(text: content),
                    if (showCursorOnThisLine)
                      TextSpan(
                        text: _getNextChar() ?? ' ',
                        style: TextStyle(
                          color: _showCursor
                              ? Theme.of(context).colorScheme.onPrimary
                              : Colors.transparent,
                          backgroundColor: _showCursor
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                  ],
                ),
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: linesToShow,
        );
      },
    );
  }
}
