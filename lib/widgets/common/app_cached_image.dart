import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/image_url_service.dart';

/// A cached image widget with Cloudflare Image Resizing support
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.size = ImageSize.thumbnail,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  final String imageUrl;
  final ImageSize size;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resizedUrl = ImageUrlService.getResizedUrl(imageUrl, size);
    final theme = Theme.of(context);

    return CachedNetworkImage(
      imageUrl: resizedUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) =>
          placeholder ?? _defaultPlaceholder(context, theme),
      errorWidget: (context, url, error) =>
          errorWidget ?? _defaultError(context, theme),
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheWidth: size.width, // Memory cache optimization
    );
  }

  Widget _defaultPlaceholder(BuildContext context, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultError(BuildContext context, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
