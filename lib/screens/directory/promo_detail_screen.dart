import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/promo.dart';
import '../../models/testimonial.dart';
import '../../providers/directory_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_tokens.dart';

class PromoDetailScreen extends ConsumerStatefulWidget {
  final String promoId;

  const PromoDetailScreen({super.key, required this.promoId});

  @override
  ConsumerState<PromoDetailScreen> createState() => _PromoDetailScreenState();
}

class _PromoDetailScreenState extends ConsumerState<PromoDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final promoAsync = ref.watch(promoDetailProvider(widget.promoId));

    return Scaffold(
      body: promoAsync.when(
        data: (promo) => _buildContent(context, tokens, colorScheme, promo),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, tokens, colorScheme, error),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    Object error,
  ) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: tokens.iconXl, color: colorScheme.error),
            SizedBox(height: tokens.spacingLg),
            const Text('Failed to load promo'),
            SizedBox(height: tokens.spacingSm),
            TextButton(
              onPressed: () => ref.invalidate(promoDetailProvider(widget.promoId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    Promo promo,
  ) {
    return CustomScrollView(
      slivers: [
        // App bar with image
        SliverAppBar(
          expandedHeight: (promo.images.isNotEmpty || promo.videoUrl != null) ? 250 : 0,
          pinned: true,
          flexibleSpace: (promo.images.isNotEmpty || promo.videoUrl != null)
              ? FlexibleSpaceBar(
                  background: _buildHeroMedia(context, tokens, colorScheme, promo),
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                // TODO: Share promo
              },
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(tokens.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & featured badges
                Wrap(
                  spacing: tokens.spacingSm,
                  runSpacing: tokens.spacingSm,
                  children: [
                    if (promo.isFeatured)
                      _buildBadge(
                        context,
                        tokens,
                        colorScheme,
                        Icons.star,
                        'Featured',
                        colorScheme.tertiaryContainer,
                        colorScheme.onTertiaryContainer,
                      ),
                    _buildBadge(
                      context,
                      tokens,
                      colorScheme,
                      promo.category.icon,
                      promo.category.displayName,
                      colorScheme.secondaryContainer,
                      colorScheme.onSecondaryContainer,
                    ),
                    if (promo.videoUrl != null)
                      _buildBadge(
                        context,
                        tokens,
                        colorScheme,
                        Icons.play_circle_outline,
                        'Video',
                        colorScheme.primaryContainer,
                        colorScheme.onPrimaryContainer,
                      ),
                  ],
                ),

                SizedBox(height: tokens.spacingLg),

                // Title
                Text(
                  promo.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                SizedBox(height: tokens.spacingMd),

                // Rating
                if (promo.averageRating != null)
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        final rating = promo.averageRating!;
                        if (index < rating.floor()) {
                          return Icon(Icons.star,
                              color: Colors.amber, size: tokens.iconSm);
                        } else if (index < rating) {
                          return Icon(Icons.star_half,
                              color: Colors.amber, size: tokens.iconSm);
                        } else {
                          return Icon(Icons.star_border,
                              color: Colors.amber, size: tokens.iconSm);
                        }
                      }),
                      SizedBox(width: tokens.spacingSm),
                      Text(
                        '${promo.averageRating!.toStringAsFixed(1)} (${promo.testimonialCount ?? 0} reviews)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),

                SizedBox(height: tokens.spacingXl),

                // External link button (prominent CTA)
                if (promo.externalLink != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _launchUrl(promo.externalLink!),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Visit Website'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: tokens.spacingMd,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spacingXl),
                ],

                // Video button (if video exists)
                if (promo.videoUrl != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _launchUrl(promo.videoUrl!),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Watch Video'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: tokens.spacingMd,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spacingXl),
                ],

                // Description
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: tokens.spacingSm),
                Text(
                  promo.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                SizedBox(height: tokens.spacingXl),

                // Contact info
                if (promo.contactInfo.isNotEmpty) ...[
                  Text(
                    'Contact',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: tokens.spacingMd),
                  _buildContactCard(context, tokens, colorScheme, promo.contactInfo),
                  SizedBox(height: tokens.spacingXl),
                ],

                // Image gallery (if multiple images)
                if (promo.images.length > 1) ...[
                  Text(
                    'Gallery',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: tokens.spacingMd),
                  _buildImageGallery(context, tokens, colorScheme, promo.images),
                  SizedBox(height: tokens.spacingXl),
                ],

                // Owner
                if (promo.owner != null) ...[
                  Text(
                    'Posted by',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: tokens.spacingMd),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
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
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(promo.owner!.fullName),
                      subtitle: promo.owner!.bio != null
                          ? Text(
                              promo.owner!.bio!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to profile
                      },
                    ),
                  ),
                  SizedBox(height: tokens.spacingXl),
                ],

                // Testimonials section
                _TestimonialsSection(
                  promoId: widget.promoId,
                  tokens: tokens,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMedia(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    Promo promo,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        if (promo.images.isNotEmpty)
          Image.network(
            promo.images.first,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.image_not_supported_outlined,
                size: tokens.iconXl,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Container(
            color: colorScheme.surfaceContainerHighest,
          ),

        // Video play overlay
        if (promo.videoUrl != null)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _launchUrl(promo.videoUrl!),
                    borderRadius: BorderRadius.circular(tokens.radiusXl),
                    child: Container(
                      padding: EdgeInsets.all(tokens.spacingLg),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: tokens.iconXl,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadge(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingMd,
        vertical: tokens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          SizedBox(width: tokens.spacingSm),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    PromoContactInfo contact,
  ) {
    return Card(
      child: Column(
        children: [
          if (contact.phone != null)
            ListTile(
              leading: Icon(Icons.phone_outlined, color: colorScheme.primary),
              title: Text(contact.phone!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _launchUrl('tel:${contact.phone}'),
            ),
          if (contact.email != null)
            ListTile(
              leading: Icon(Icons.email_outlined, color: colorScheme.primary),
              title: Text(contact.email!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _launchUrl('mailto:${contact.email}'),
            ),
          if (contact.website != null)
            ListTile(
              leading: Icon(Icons.language_outlined, color: colorScheme.primary),
              title: Text(contact.website!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _launchUrl(contact.website!),
            ),
          if (contact.address != null)
            ListTile(
              leading: Icon(Icons.location_on_outlined, color: colorScheme.primary),
              title: Text(contact.address!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _launchUrl(
                  'https://maps.google.com/?q=${Uri.encodeComponent(contact.address!)}'),
            ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme colorScheme,
    List<String> images,
  ) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: tokens.spacingSm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: InkWell(
                onTap: () => _showImageViewer(context, images, index),
                child: Image.network(
                  images[index],
                  width: 160,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 160,
                    height: 120,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageViewer(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('${initialIndex + 1} / ${images.length}'),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    // Ensure URL has a scheme
    String urlToLaunch = url;
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('tel:') &&
        !url.startsWith('mailto:')) {
      urlToLaunch = 'https://$url';
    }

    final uri = Uri.parse(urlToLaunch);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    }
  }
}

// ============================================================
// Testimonials Section
// ============================================================

class _TestimonialsSection extends ConsumerWidget {
  final String promoId;
  final AppThemeTokens tokens;
  final ColorScheme colorScheme;

  const _TestimonialsSection({
    required this.promoId,
    required this.tokens,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testimonialsAsync = ref.watch(testimonialsByPromoProvider(promoId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddTestimonialSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Write Review'),
            ),
          ],
        ),
        SizedBox(height: tokens.spacingMd),
        testimonialsAsync.when(
          data: (testimonials) {
            if (testimonials.isEmpty) {
              return _buildEmptyTestimonials(context);
            }
            return Column(
              children: testimonials
                  .map((t) => _TestimonialCard(
                        testimonial: t,
                        tokens: tokens,
                        colorScheme: colorScheme,
                      ))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Failed to load reviews: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTestimonials(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: tokens.iconLg,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              SizedBox(height: tokens.spacingMd),
              Text(
                'No reviews yet',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: tokens.spacingSm),
              Text(
                'Be the first to share your experience',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTestimonialSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddTestimonialSheet(
        promoId: promoId,
        tokens: tokens,
        colorScheme: colorScheme,
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;
  final AppThemeTokens tokens;
  final ColorScheme colorScheme;

  const _TestimonialCard({
    required this.testimonial,
    required this.tokens,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: tokens.spacingMd),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (testimonial.author != null) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: testimonial.author!.avatarUrl != null
                        ? NetworkImage(testimonial.author!.avatarUrl!)
                        : null,
                    child: testimonial.author!.avatarUrl == null
                        ? Text(
                            testimonial.author!.fullName.isNotEmpty
                                ? testimonial.author!.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: tokens.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testimonial.author!.fullName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          _formatDate(testimonial.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Star rating
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < testimonial.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spacingMd),
            Text(
              testimonial.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ============================================================
// Add Testimonial Sheet
// ============================================================

class _AddTestimonialSheet extends ConsumerStatefulWidget {
  final String promoId;
  final AppThemeTokens tokens;
  final ColorScheme colorScheme;

  const _AddTestimonialSheet({
    required this.promoId,
    required this.tokens,
    required this.colorScheme,
  });

  @override
  ConsumerState<_AddTestimonialSheet> createState() => _AddTestimonialSheetState();
}

class _AddTestimonialSheetState extends ConsumerState<_AddTestimonialSheet> {
  int _rating = 5;
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
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
              Row(
                children: [
                  Text(
                    'Write a Review',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: widget.tokens.spacingXl),

              // Star rating
              Text(
                'Your Rating',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: widget.tokens.spacingSm),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  );
                }),
              ),

              SizedBox(height: widget.tokens.spacingLg),

              // Review content
              Text(
                'Your Review',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: widget.tokens.spacingSm),
              TextField(
                controller: _contentController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(widget.tokens.radiusMd),
                  ),
                ),
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
                      : const Text('Submit Review'),
                ),
              ),

              SizedBox(height: widget.tokens.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await createTestimonial(
        ref,
        promoId: widget.promoId,
        rating: _rating,
        content: content,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted! It will appear after approval.'),
          ),
        );
        // Refresh testimonials
        ref.invalidate(testimonialsByPromoProvider(widget.promoId));
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
