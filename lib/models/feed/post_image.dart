/// Represents an image attached to a post
class PostImage {
  final String id;
  final String postId;
  final String storagePath;
  final String url;
  final String? altText;
  final int displayOrder;
  final bool isPrimary;
  final int? width;
  final int? height;
  final int? fileSize;
  final DateTime createdAt;

  PostImage({
    required this.id,
    required this.postId,
    required this.storagePath,
    required this.url,
    this.altText,
    this.displayOrder = 0,
    this.isPrimary = false,
    this.width,
    this.height,
    this.fileSize,
    required this.createdAt,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      storagePath: json['storage_path'] as String,
      url: json['url'] as String,
      altText: json['alt_text'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isPrimary: json['is_primary'] as bool? ?? false,
      width: json['width'] as int?,
      height: json['height'] as int?,
      fileSize: json['file_size'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'storage_path': storagePath,
      'url': url,
      'alt_text': altText,
      'display_order': displayOrder,
      'is_primary': isPrimary,
      'width': width,
      'height': height,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'storage_path': storagePath,
      'url': url,
      if (altText != null) 'alt_text': altText,
      'display_order': displayOrder,
      'is_primary': isPrimary,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (fileSize != null) 'file_size': fileSize,
    };
  }

  PostImage copyWith({
    String? id,
    String? postId,
    String? storagePath,
    String? url,
    String? altText,
    int? displayOrder,
    bool? isPrimary,
    int? width,
    int? height,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return PostImage(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      storagePath: storagePath ?? this.storagePath,
      url: url ?? this.url,
      altText: altText ?? this.altText,
      displayOrder: displayOrder ?? this.displayOrder,
      isPrimary: isPrimary ?? this.isPrimary,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
