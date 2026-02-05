import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../theme/app_theme_tokens.dart';

/// Video player widget for post detail view.
/// Uses Chewie for controls on top of video_player.
/// Initializes lazily — shows a thumbnail/play button until tapped.
class PostVideoPlayer extends StatefulWidget {
  /// HLS playback URL from Cloudflare Stream
  final String playbackUrl;

  /// Optional thumbnail URL to show before playing
  final String? thumbnailUrl;

  const PostVideoPlayer({
    super.key,
    required this.playbackUrl,
    this.thumbnailUrl,
  });

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
    });

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.playbackUrl),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControlsOnInitialize: true,
        allowFullScreen: true,
        allowMuting: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error playing video',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: AspectRatio(
        aspectRatio: _videoController?.value.isInitialized == true
            ? _videoController!.value.aspectRatio
            : 16 / 9,
        child: _isInitialized && _chewieController != null
            ? Chewie(controller: _chewieController!)
            : _buildPreview(tokens, colorScheme),
      ),
    );
  }

  Widget _buildPreview(AppThemeTokens tokens, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _hasError ? null : _initializePlayer,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail image
            if (widget.thumbnailUrl != null)
              Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),

            // Play button or error overlay
            Center(
              child: _hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _initializePlayer,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
