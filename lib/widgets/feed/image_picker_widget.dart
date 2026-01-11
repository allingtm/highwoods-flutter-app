import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme_tokens.dart';
import '../../theme/app_typography.dart';

/// Represents an image selected for upload (not yet uploaded)
class SelectedImage {
  final File file;
  final String localPath;
  bool isUploading;
  double uploadProgress;
  String? errorMessage;

  SelectedImage({
    required this.file,
    required this.localPath,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.errorMessage,
  });
}

/// Widget for selecting and managing images for a post
/// Supports camera, gallery, drag to reorder, and delete
class ImagePickerWidget extends StatefulWidget {
  /// Maximum number of images allowed
  final int maxImages;

  /// Currently selected images
  final List<SelectedImage> images;

  /// Called when images change (add, remove, reorder)
  final ValueChanged<List<SelectedImage>> onImagesChanged;

  /// Optional callback for validation errors
  final ValueChanged<String>? onError;

  const ImagePickerWidget({
    super.key,
    this.maxImages = 5,
    required this.images,
    required this.onImagesChanged,
    this.onError,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _showImageSourceSheet() async {
    if (widget.images.length >= widget.maxImages) {
      widget.onError?.call('Maximum ${widget.maxImages} images allowed');
      return;
    }

    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusXl),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Photo',
                style: AppTypography.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spacingLg),
              _SourceOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              SizedBox(height: tokens.spacingSm),
              _SourceOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: tokens.spacingSm),
              _SourceOption(
                icon: Icons.photo_library,
                label: 'Choose Multiple',
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _addImage(File(pickedFile.path));
      }
    } on PlatformException catch (e) {
      widget.onError?.call('Failed to pick image: ${e.message}');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final remaining = widget.maxImages - widget.images.length;
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        limit: remaining,
      );

      for (final file in pickedFiles) {
        if (widget.images.length < widget.maxImages) {
          _addImage(File(file.path));
        }
      }
    } on PlatformException catch (e) {
      widget.onError?.call('Failed to pick images: ${e.message}');
    }
  }

  void _addImage(File file) {
    final newImage = SelectedImage(
      file: file,
      localPath: file.path,
    );

    final updatedImages = [...widget.images, newImage];
    widget.onImagesChanged(updatedImages);
  }

  void _removeImage(int index) {
    HapticFeedback.lightImpact();
    final updatedImages = [...widget.images];
    updatedImages.removeAt(index);
    widget.onImagesChanged(updatedImages);
  }

  void _onReorder(int oldIndex, int newIndex) {
    HapticFeedback.mediumImpact();
    final updatedImages = [...widget.images];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = updatedImages.removeAt(oldIndex);
    updatedImages.insert(newIndex, item);
    widget.onImagesChanged(updatedImages);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Text(
              'Photos',
              style: AppTypography.labelLarge,
            ),
            const Spacer(),
            Text(
              '${widget.images.length}/${widget.maxImages}',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacingSm),

        // Image grid or add button
        if (widget.images.isEmpty)
          _EmptyState(onTap: _showImageSourceSheet)
        else
          Column(
            children: [
              // Draggable image grid
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: widget.images.length,
                onReorder: _onReorder,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final scale = Curves.easeInOut.transform(animation.value);
                      return Transform.scale(
                        scale: 1.0 + (0.05 * scale),
                        child: child,
                      );
                    },
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  return _ImageThumbnail(
                    key: ValueKey(widget.images[index].localPath),
                    image: widget.images[index],
                    index: index,
                    isPrimary: index == 0,
                    onRemove: () => _removeImage(index),
                  );
                },
              ),
              SizedBox(height: tokens.spacingSm),

              // Add more button
              if (widget.images.length < widget.maxImages)
                OutlinedButton.icon(
                  onPressed: _showImageSourceSheet,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add More Photos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
            ],
          ),

        // Helper text
        SizedBox(height: tokens.spacingXs),
        Text(
          'First image will be the cover photo. Drag to reorder.',
          style: AppTypography.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Empty state widget with add button
class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyState({required this.onTap});

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
                Icons.add_photo_alternate_outlined,
                size: tokens.iconLg,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: tokens.spacingXs),
              Text(
                'Add Photos',
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

/// Image source option in bottom sheet
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

/// Individual image thumbnail with delete and primary badge
class _ImageThumbnail extends StatelessWidget {
  final SelectedImage image;
  final int index;
  final bool isPrimary;
  final VoidCallback onRemove;

  const _ImageThumbnail({
    super.key,
    required this.image,
    required this.index,
    required this.isPrimary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacingSm),
      child: Row(
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: EdgeInsets.all(tokens.spacingSm),
              child: Icon(
                Icons.drag_handle,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusSm),
            child: Stack(
              children: [
                Image.file(
                  image.file,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),

                // Upload progress overlay
                if (image.isUploading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: image.uploadProgress > 0
                              ? image.uploadProgress
                              : null,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),

                // Error overlay
                if (image.errorMessage != null)
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

                // Primary badge
                if (isPrimary)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacingXs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(tokens.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 10,
                            color: colorScheme.onPrimary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Cover',
                            style: AppTypography.caption.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(width: tokens.spacingSm),

          // Image info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image ${index + 1}',
                  style: AppTypography.labelSmall,
                ),
                if (image.errorMessage != null)
                  Text(
                    image.errorMessage!,
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            color: colorScheme.error,
            tooltip: 'Remove image',
          ),
        ],
      ),
    );
  }
}
