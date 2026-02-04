/// Image size presets for different UI contexts
enum ImageSize {
  /// Avatars and small thumbnails (~100px)
  avatar(width: 100, quality: 80),

  /// Feed card thumbnails (~400px)
  thumbnail(width: 400, quality: 80),

  /// Medium images for lists (~600px)
  medium(width: 600, quality: 82),

  /// Full-size images for detail views (~1200px)
  full(width: 1200, quality: 85);

  const ImageSize({required this.width, required this.quality});

  final int width;
  final int quality;
}

/// Service for constructing Cloudflare Image Resizing URLs
class ImageUrlService {
  // CDN domain with Image Resizing enabled
  static const String _cdnBaseUrl = 'https://cdn.highwoods.co.uk';

  // Original R2 public URL (for backward compatibility)
  static const String _r2PublicUrl =
      'https://pub-b231fcd02fbf463f8956d39a9b1a3e38.r2.dev';

  /// Generates a Cloudflare Image Resizing URL for the given image
  ///
  /// Converts URLs like:
  /// - `https://pub-xxx.r2.dev/user/post/image.jpg`
  /// - `https://cdn.highwoods.co.uk/user/post/image.jpg`
  ///
  /// To:
  /// - `https://cdn.highwoods.co.uk/cdn-cgi/image/width=400,quality=80,format=auto/user/post/image.jpg`
  static String getResizedUrl(String originalUrl, ImageSize size) {
    final path = _extractPath(originalUrl);
    if (path == null) return originalUrl; // Fallback to original if can't parse

    final params = _buildParams(size);
    return '$_cdnBaseUrl/cdn-cgi/image/$params/$path';
  }

  /// Extracts the path portion from an R2 or CDN URL
  static String? _extractPath(String url) {
    // Handle R2 public URL
    if (url.startsWith(_r2PublicUrl)) {
      final path = url.substring(_r2PublicUrl.length);
      return path.startsWith('/') ? path.substring(1) : path;
    }

    // Handle CDN URL (with or without transformation)
    if (url.startsWith(_cdnBaseUrl)) {
      // Check if it's already a transformed URL
      final transformRegex = RegExp(r'/cdn-cgi/image/[^/]+/(.+)$');
      final match = transformRegex.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }

      // Plain CDN URL without transformation
      final path = url.substring(_cdnBaseUrl.length);
      return path.startsWith('/') ? path.substring(1) : path;
    }

    return null;
  }

  /// Builds the transformation parameters string
  static String _buildParams(ImageSize size) {
    return [
      'width=${size.width}',
      'quality=${size.quality}',
      'format=auto', // Auto-selects WebP/AVIF based on browser support
      'fit=cover', // Maintain aspect ratio, crop if needed
    ].join(',');
  }
}
