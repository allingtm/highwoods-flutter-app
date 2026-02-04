import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/image_url_service.dart';

/// A cached avatar widget with Cloudflare Image Resizing support
class AppCachedAvatar extends StatelessWidget {
  const AppCachedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.fallbackInitials,
  });

  final String? imageUrl;
  final double radius;
  final String? fallbackInitials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageUrl == null) {
      return _buildFallbackAvatar(theme);
    }

    final resizedUrl = ImageUrlService.getResizedUrl(imageUrl!, ImageSize.avatar);

    return CachedNetworkImage(
      imageUrl: resizedUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      errorWidget: (context, url, error) => _buildFallbackAvatar(theme),
      memCacheWidth: ImageSize.avatar.width,
    );
  }

  Widget _buildFallbackAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        _getInitials(fallbackInitials),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
