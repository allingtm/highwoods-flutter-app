/// Status of a video being processed by Cloudflare Stream
enum VideoStatus {
  processing,
  ready,
  error;

  static VideoStatus fromString(String value) {
    switch (value) {
      case 'ready':
        return VideoStatus.ready;
      case 'error':
        return VideoStatus.error;
      default:
        return VideoStatus.processing;
    }
  }

  String get dbValue => name;
}

/// Represents a video attached to a post (stored in Cloudflare Stream)
class PostVideo {
  final String id;
  final String postId;
  final String streamVideoUid;
  final String? thumbnailUrl;
  final String? playbackUrl;
  final int? durationSeconds;
  final VideoStatus status;
  final int? fileSize;
  final int? width;
  final int? height;
  final DateTime createdAt;

  PostVideo({
    required this.id,
    required this.postId,
    required this.streamVideoUid,
    this.thumbnailUrl,
    this.playbackUrl,
    this.durationSeconds,
    this.status = VideoStatus.processing,
    this.fileSize,
    this.width,
    this.height,
    required this.createdAt,
  });

  factory PostVideo.fromJson(Map<String, dynamic> json) {
    return PostVideo(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      streamVideoUid: json['stream_video_uid'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      playbackUrl: json['playback_url'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      status: VideoStatus.fromString(json['status'] as String? ?? 'processing'),
      fileSize: (json['file_size'] as num?)?.toInt(),
      width: json['width'] as int?,
      height: json['height'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'stream_video_uid': streamVideoUid,
      'thumbnail_url': thumbnailUrl,
      'playback_url': playbackUrl,
      'duration_seconds': durationSeconds,
      'status': status.dbValue,
      'file_size': fileSize,
      'width': width,
      'height': height,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'post_id': postId,
      'stream_video_uid': streamVideoUid,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (playbackUrl != null) 'playback_url': playbackUrl,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      'status': status.dbValue,
      if (fileSize != null) 'file_size': fileSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  PostVideo copyWith({
    String? id,
    String? postId,
    String? streamVideoUid,
    String? thumbnailUrl,
    String? playbackUrl,
    int? durationSeconds,
    VideoStatus? status,
    int? fileSize,
    int? width,
    int? height,
    DateTime? createdAt,
  }) {
    return PostVideo(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      streamVideoUid: streamVideoUid ?? this.streamVideoUid,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      playbackUrl: playbackUrl ?? this.playbackUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
