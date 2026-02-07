import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/promo.dart';
import '../providers/directory_provider.dart';
import '../theme/app_color_palette.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_tokens.dart';

/// Directory screen showing a feed of promos (read-only, admin managed)
class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key, this.onMenuTap});

  /// Callback to open the side menu drawer
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final promosState = ref.watch(promosProvider);

    return Scaffold(
      appBar: AppBar(
        leading: onMenuTap != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuTap,
                tooltip: 'Open menu',
              )
            : null,
        title: const Text('Directory'),
      ),
      body: Column(
        children: [
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacingLg,
              vertical: tokens.spacingMd,
            ),
            child: Row(
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: promosState.selectedCategory == null,
                  onTap: () => ref.read(promosProvider.notifier).setCategory(null),
                  colorScheme: colorScheme,
                  tokens: tokens,
                ),
                SizedBox(width: tokens.spacingSm),
                ...PromoCategory.values.map((category) => Padding(
                      padding: EdgeInsets.only(right: tokens.spacingSm),
                      child: _CategoryChip(
                        label: category.displayName,
                        icon: category.icon,
                        isSelected: promosState.selectedCategory == category,
                        onTap: () =>
                            ref.read(promosProvider.notifier).setCategory(category),
                        colorScheme: colorScheme,
                        tokens: tokens,
                      ),
                    )),
              ],
            ),
          ),

          // Promos list
          Expanded(
            child: _buildPromosList(context, ref, promosState, tokens, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildPromosList(
    BuildContext context,
    WidgetRef ref,
    PromosState promosState,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    if (promosState.isLoading && promosState.promos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (promosState.error != null && promosState.promos.isEmpty) {
      return _buildError(context, ref, promosState.error!, tokens, colorScheme);
    }

    if (promosState.promos.isEmpty) {
      return _buildEmpty(context, tokens, colorScheme);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(promosProvider.notifier).refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Load more when near bottom
          if (notification is ScrollEndNotification) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent - 200) {
              ref.read(promosProvider.notifier).loadMore();
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
          itemCount: promosState.promos.length + (promosState.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= promosState.promos.length) {
              // Loading indicator at bottom
              return Padding(
                padding: EdgeInsets.all(tokens.spacingLg),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final promo = promosState.promos[index];
            return _PromoCard(
              promo: promo,
              tokens: tokens,
              colorScheme: colorScheme,
              onTap: () => context.push('/directory/promo/${promo.id}'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    String error,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: tokens.iconXl,
              color: colorScheme.error,
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              'Failed to load directory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: tokens.spacingXl),
            FilledButton.icon(
              onPressed: () => ref.read(promosProvider.notifier).load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: tokens.iconXl,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: tokens.spacingLg),
            Text(
              'No listings yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spacingSm),
            Text(
              'Check back soon for local businesses,\nservices, and community offerings',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
// Category Filter Chip
// ============================================================

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final AppThemeTokens tokens;

  const _CategoryChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            )
          : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      showCheckmark: false,
    );
  }
}

// ============================================================
// Promo Card
// ============================================================

class _PromoCard extends StatelessWidget {
  final Promo promo;
  final AppThemeTokens tokens;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _PromoCard({
    required this.promo,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image or video indicator
            if (promo.images.isNotEmpty || promo.videoUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (promo.images.isNotEmpty)
                      Image.network(
                        promo.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: tokens.iconLg,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.play_circle_outline,
                          size: tokens.iconXl,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    // Video indicator overlay
                    if (promo.videoUrl != null)
                      Positioned(
                        right: tokens.spacingSm,
                        bottom: tokens.spacingSm,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spacingSm,
                            vertical: tokens.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(tokens.radiusSm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_circle_filled,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: tokens.spacingXs),
                              const Text(
                                'Video',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            Padding(
              padding: EdgeInsets.all(tokens.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured badge & category
                  Row(
                    children: [
                      if (promo.isFeatured) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spacingSm,
                            vertical: tokens.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(tokens.radiusSm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              SizedBox(width: tokens.spacingXs),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: tokens.spacingSm),
                      ],
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spacingSm,
                          vertical: tokens.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(tokens.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              promo.category.icon,
                              size: 12,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            SizedBox(width: tokens.spacingXs),
                            Text(
                              promo.category.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (promo.externalLink != null) ...[
                        SizedBox(width: tokens.spacingSm),
                        Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: tokens.spacingMd),

                  // Title
                  Text(
                    promo.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: tokens.spacingSm),

                  // Description
                  Text(
                    promo.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: tokens.spacingMd),

                  // Owner & Rating
                  Row(
                    children: [
                      if (promo.owner != null) ...[
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: promo.owner!.avatarUrl != null
                              ? NetworkImage(promo.owner!.avatarUrl!)
                              : null,
                          child: promo.owner!.avatarUrl == null
                              ? Text(
                                  promo.owner!.fullName.isNotEmpty
                                      ? promo.owner!.fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: tokens.spacingSm),
                        Expanded(
                          child: Text(
                            promo.owner!.fullName,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        const Spacer(),
                      if (promo.averageRating != null) ...[
                        Icon(
                          Icons.star,
                          size: tokens.iconSm,
                          color: context.colors.warning,
                        ),
                        SizedBox(width: tokens.spacingXs),
                        Text(
                          promo.averageRating!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (promo.testimonialCount != null) ...[
                          SizedBox(width: tokens.spacingXs),
                          Text(
                            '(${promo.testimonialCount})',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
