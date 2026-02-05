import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme_tokens.dart';
import '../../theme/app_typography.dart';
import 'image_picker_widget.dart';

/// The type of media the user wants to attach
enum MediaType { photos, video }

/// Represents a video selected for upload (not yet uploaded)
class SelectedVideo {
  final File file;
  final String localPath;
  final int? durationSeconds;
  bool isUploading;
  double uploadProgress;
  String? errorMessage;

  SelectedVideo({
    required this.file,
    required this.localPath,
    this.durationSeconds,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.errorMessage,
  });
}

/// Widget for selecting media (photos or video) for a post.
/// Enforces mutual exclusivity: photos OR video, not both.
class MediaPickerWidget extends StatefulWidget {
  /// Maximum number of images allowed
  final int maxImages;

  /// Currently selected images
  final List<SelectedImage> images;

  /// Currently selected video (if any)
  final SelectedVideo? video;

  /// Called when images change
  final ValueChanged<List<SelectedImage>> onImagesChanged;

  /// Called when video changes
  final ValueChanged<SelectedVideo?> onVideoChanged;

  /// Optional callback for validation errors
  final ValueChanged<String>? onError;

  const MediaPickerWidget({
    super.key,
    this.maxImages = 5,
    required this.images,
    required this.video,
    required this.onImagesChanged,
    required this.onVideoChanged,
    this.onError,
  });

  @override
  State<MediaPickerWidget> createState() => _MediaPickerWidgetState();
}

class _MediaPickerWidgetState extends State<MediaPickerWidget> {
  final ImagePicker _picker = ImagePicker();

  MediaType get _currentMediaType {
    if (widget.video != null) return MediaType.video;
    if (widget.images.isNotEmpty) return MediaType.photos;
    return MediaType.photos; // default
  }

  bool get _hasMedia => widget.images.isNotEmpty || widget.video != null;

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final selectedVideo = SelectedVideo(
          file: file,
          localPath: pickedFile.path,
        );

        // Clear any images when selecting video
        if (widget.images.isNotEmpty) {
          widget.onImagesChanged([]);
        }
        widget.onVideoChanged(selectedVideo);
      }
    } on PlatformException catch (e) {
      widget.onError?.call('Failed to pick video: ${e.message}');
    }
  }

  void _removeVideo() {
    HapticFeedback.lightImpact();
    widget.onVideoChanged(null);
  }

  void _showVideoSourceSheet() async {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusXl),
        ),
      ),
      builder: (context) => HeroMode(
        enabled: false,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(tokens.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Video',
                  style: AppTypography.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spacingLg),
                _SourceOption(
                  icon: Icons.videocam_outlined,
                  label: 'Record Video',
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo(ImageSource.camera);
                  },
                ),
                SizedBox(height: tokens.spacingSm),
                _SourceOption(
                  icon: Icons.video_library_outlined,
                  label: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _switchToPhotos() {
    if (widget.video != null) {
      widget.onVideoChanged(null);
    }
  }

  void _switchToVideo() {
    if (widget.images.isNotEmpty) {
      widget.onImagesChanged([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with media type toggle
        Row(
          children: [
            Text(
              'Media',
              style: AppTypography.labelLarge,
            ),
            const Spacer(),
            // Media type toggle chips
            _MediaTypeToggle(
              currentType: _currentMediaType,
              hasMedia: _hasMedia,
              onPhotosSelected: _switchToPhotos,
              onVideoSelected: _switchToVideo,
            ),
          ],
        ),
        SizedBox(height: tokens.spacingSm),

        // Show appropriate picker based on mode
        if (_currentMediaType == MediaType.photos)
          ImagePickerWidget(
            maxImages: widget.maxImages,
            images: widget.images,
            onImagesChanged: widget.onImagesChanged,
            onError: widget.onError,
          )
        else
          _buildVideoPicker(tokens, colorScheme),

        // Helper text
        SizedBox(height: tokens.spacingXs),
        Text(
          _currentMediaType == MediaType.photos
              ? 'First image will be the cover photo. Drag to reorder.'
              : 'Maximum 5 minutes. MP4 or MOV format.',
          style: AppTypography.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPicker(AppThemeTokens tokens, ColorScheme colorScheme) {
    if (widget.video == null) {
      return _VideoEmptyState(onTap: _showVideoSourceSheet);
    }

    return _VideoPreview(
      video: widget.video!,
      onRemove: _removeVideo,
    );
  }
}

/// Toggle between Photos and Video media types
class _MediaTypeToggle extends StatelessWidget {
  final MediaType currentType;
  final bool hasMedia;
  final VoidCallback onPhotosSelected;
  final VoidCallback onVideoSelected;

  const _MediaTypeToggle({
    required this.currentType,
    required this.hasMedia,
    required this.onPhotosSelected,
    required this.onVideoSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleChip(
          label: 'Photos',
          icon: Icons.photo_outlined,
          isSelected: currentType == MediaType.photos,
          onTap: onPhotosSelected,
        ),
        SizedBox(width: tokens.spacingXs),
        _ToggleChip(
          label: 'Video',
          icon: Icons.videocam_outlined,
          isSelected: currentType == MediaType.video,
          onTap: onVideoSelected,
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacingSm,
          vertical: tokens.spacingXs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: tokens.spacingXs),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state for video picker
class _VideoEmptyState extends StatelessWidget {
  final VoidCallback onTap;

  const _VideoEmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.video_call_outlined,
                size: tokens.iconLg,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: tokens.spacingXs),
              Text(
                'Add Video',
                style: AppTypography.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preview of a selected video with remove button
class _VideoPreview extends StatelessWidget {
  final SelectedVideo video;
  final VoidCallback onRemove;

  const _VideoPreview({
    required this.video,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Video thumbnail placeholder
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          child: Container(
            width: 120,
            height: 80,
            color: colorScheme.surfaceContainerHighest,
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.videocam_rounded,
                    size: 32,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                // Upload progress overlay
                if (video.isUploading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: video.uploadProgress > 0
                              ? video.uploadProgress
                              : null,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                // Error overlay
                if (video.errorMessage != null)
                  Positioned.fill(
                    child: Container(
                      color: colorScheme.error.withValues(alpha: 0.8),
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        SizedBox(width: tokens.spacingSm),

        // Video info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Video selected',
                style: AppTypography.labelSmall,
              ),
              if (video.durationSeconds != null)
                Text(
                  _formatDuration(video.durationSeconds!),
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              if (video.errorMessage != null)
                Text(
                  video.errorMessage!,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),

        // Remove button
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close),
          color: colorScheme.error,
          tooltip: 'Remove video',
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// Video source option in bottom sheet (reuses pattern from ImagePickerWidget)
class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(label, style: AppTypography.bodyMedium),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      tileColor: colorScheme.surfaceContainerHighest,
    );
  }
}
