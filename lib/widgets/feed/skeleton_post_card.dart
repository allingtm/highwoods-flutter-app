import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Skeleton loading placeholder for post cards
class SkeletonPostCard extends StatefulWidget {
  const SkeletonPostCard({
    super.key,
    this.hasImage = true,
  });

  final bool hasImage;

  @override
  State<SkeletonPostCard> createState() => _SkeletonPostCardState();
}

class _SkeletonPostCardState extends State<SkeletonPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: tokens.spacingLg,
        vertical: tokens.spacingSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              if (widget.hasImage)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _SkeletonBox(animation: _animation),
                ),

              Padding(
                padding: EdgeInsets.all(tokens.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        _SkeletonCircle(
                          size: 36,
                          animation: _animation,
                        ),
                        SizedBox(width: tokens.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SkeletonBox(
                                width: 120,
                                height: 14,
                                animation: _animation,
                              ),
                              SizedBox(height: tokens.spacingXs),
                              _SkeletonBox(
                                width: 60,
                                height: 10,
                                animation: _animation,
                              ),
                            ],
                          ),
                        ),
                        _SkeletonBox(
                          width: 80,
                          height: 24,
                          animation: _animation,
                          borderRadius: tokens.radiusSm,
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.spacingMd),

                    // Title
                    _SkeletonBox(
                      width: double.infinity,
                      height: 20,
                      animation: _animation,
                    ),
                    SizedBox(height: tokens.spacingSm),
                    _SkeletonBox(
                      width: 200,
                      height: 20,
                      animation: _animation,
                    ),

                    SizedBox(height: tokens.spacingMd),

                    // Content lines
                    _SkeletonBox(
                      width: double.infinity,
                      height: 14,
                      animation: _animation,
                    ),
                    SizedBox(height: tokens.spacingXs),
                    _SkeletonBox(
                      width: double.infinity,
                      height: 14,
                      animation: _animation,
                    ),
                    SizedBox(height: tokens.spacingXs),
                    _SkeletonBox(
                      width: 150,
                      height: 14,
                      animation: _animation,
                    ),

                    SizedBox(height: tokens.spacingLg),

                    // Actions row
                    Row(
                      children: [
                        _SkeletonBox(
                          width: 50,
                          height: 24,
                          animation: _animation,
                          borderRadius: tokens.radiusMd,
                        ),
                        SizedBox(width: tokens.spacingMd),
                        _SkeletonBox(
                          width: 50,
                          height: 24,
                          animation: _animation,
                          borderRadius: tokens.radiusMd,
                        ),
                        const Spacer(),
                        _SkeletonBox(
                          width: 24,
                          height: 24,
                          animation: _animation,
                          borderRadius: tokens.radiusMd,
                        ),
                        SizedBox(width: tokens.spacingSm),
                        _SkeletonBox(
                          width: 24,
                          height: 24,
                          animation: _animation,
                          borderRadius: tokens.radiusMd,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    this.height,
    required this.animation,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final Animation<double> animation;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surface;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? tokens.radiusSm),
        gradient: LinearGradient(
          begin: Alignment(animation.value - 1, 0),
          end: Alignment(animation.value + 1, 0),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({
    required this.size,
    required this.animation,
  });

  final double size;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surface;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment(animation.value - 1, 0),
          end: Alignment(animation.value + 1, 0),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Skeleton loading for the filter pills
class SkeletonFilterPills extends StatefulWidget {
  const SkeletonFilterPills({super.key});

  @override
  State<SkeletonFilterPills> createState() => _SkeletonFilterPillsState();
}

class _SkeletonFilterPillsState extends State<SkeletonFilterPills>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
            children: [
              _SkeletonBox(width: 60, height: 32, animation: _animation, borderRadius: tokens.radiusXl),
              SizedBox(width: tokens.spacingSm),
              _SkeletonBox(width: 90, height: 32, animation: _animation, borderRadius: tokens.radiusXl),
              SizedBox(width: tokens.spacingSm),
              _SkeletonBox(width: 100, height: 32, animation: _animation, borderRadius: tokens.radiusXl),
              SizedBox(width: tokens.spacingSm),
              _SkeletonBox(width: 70, height: 32, animation: _animation, borderRadius: tokens.radiusXl),
              SizedBox(width: tokens.spacingSm),
              _SkeletonBox(width: 80, height: 32, animation: _animation, borderRadius: tokens.radiusXl),
            ],
          );
        },
      ),
    );
  }
}
