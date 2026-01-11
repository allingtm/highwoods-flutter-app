import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/calendar_event.dart';
import '../../providers/calendar_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_theme_tokens.dart';

/// Screen displaying full details of a calendar event
class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      body: eventAsync.when(
        data: (event) => _buildContent(context, event, tokens),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, error.toString()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CalendarEvent event, AppThemeTokens tokens) {
    return CustomScrollView(
      slivers: [
        // App bar with image
        SliverAppBar(
          expandedHeight: event.imageUrl != null ? 250 : 0,
          pinned: true,
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          flexibleSpace: event.imageUrl != null
              ? FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: event.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.brandPrimary.withValues(alpha: 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.brandPrimary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      // Gradient overlay for better readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(tokens.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured badge
                if (event.isFeatured) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacingMd,
                      vertical: tokens.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(tokens.radiusSm),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        SizedBox(width: tokens.spacingXs),
                        Text(
                          'Featured Event',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.spacingMd),
                ],

                // Title
                Text(
                  event.title,
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: tokens.spacingXl),

                // Date & Time card
                _buildInfoCard(
                  context,
                  tokens,
                  icon: Icons.calendar_today,
                  title: 'Date & Time',
                  children: [
                    Text(
                      event.formattedDate,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (event.timeRange != null) ...[
                      SizedBox(height: tokens.spacingXs),
                      Text(
                        event.timeRange!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    if (event.isToday) ...[
                      SizedBox(height: tokens.spacingSm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spacingSm,
                          vertical: tokens.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(tokens.radiusSm),
                        ),
                        child: Text(
                          'Today',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Location card
                if (event.location != null) ...[
                  SizedBox(height: tokens.spacingMd),
                  _buildInfoCard(
                    context,
                    tokens,
                    icon: Icons.location_on,
                    title: 'Location',
                    children: [
                      Text(
                        event.location!,
                        style: AppTypography.bodyLarge,
                      ),
                    ],
                  ),
                ],

                // Description
                if (event.description != null) ...[
                  SizedBox(height: tokens.spacingXl),
                  Text(
                    'About this event',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: tokens.spacingMd),
                  Text(
                    event.description!,
                    style: AppTypography.bodyMedium.copyWith(
                      height: 1.6,
                    ),
                  ),
                ],

                // Past event notice
                if (event.isPast) ...[
                  SizedBox(height: tokens.spacingXl),
                  Container(
                    padding: EdgeInsets.all(tokens.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryText.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: AppColors.secondaryText,
                          size: 20,
                        ),
                        SizedBox(width: tokens.spacingMd),
                        Expanded(
                          child: Text(
                            'This event has already taken place.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Bottom spacing
                SizedBox(height: tokens.spacing2xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    AppThemeTokens tokens, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(tokens.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(tokens.radiusSm),
            ),
            child: Icon(
              icon,
              color: AppColors.brandPrimary,
              size: 20,
            ),
          ),
          SizedBox(width: tokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                SizedBox(height: tokens.spacingXs),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load event',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
