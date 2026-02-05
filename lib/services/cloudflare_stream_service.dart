import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a direct upload URL from Cloudflare Stream
class StreamUploadUrl {
  final String uploadUrl;
  final String videoUid;

  StreamUploadUrl({
    required this.uploadUrl,
    required this.videoUid,
  });

  factory StreamUploadUrl.fromJson(Map<String, dynamic> json) {
    return StreamUploadUrl(
      uploadUrl: json['uploadUrl'] as String,
      videoUid: json['videoUid'] as String,
    );
  }
}

/// Represents the status/info of a video in Cloudflare Stream
class StreamVideoInfo {
  final String videoUid;
  final String status; // 'processing', 'ready', 'error'
  final String? thumbnailUrl;
  final String? playbackUrl;
  final int? duration;
  final int? width;
  final int? height;

  StreamVideoInfo({
    required this.videoUid,
    required this.status,
    this.thumbnailUrl,
    this.playbackUrl,
    this.duration,
    this.width,
    this.height,
  });

  factory StreamVideoInfo.fromJson(Map<String, dynamic> json) {
    return StreamVideoInfo(
      videoUid: json['videoUid'] as String,
      status: json['status'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      playbackUrl: json['playbackUrl'] as String?,
      duration: json['duration'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  bool get isReady => status == 'ready';
  bool get isProcessing => status == 'processing';
  bool get isError => status == 'error';
}

/// Service for interacting with Cloudflare Stream via Supabase Edge Functions
class CloudflareStreamService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a Direct Creator Upload URL for uploading a video to Stream
  Future<StreamUploadUrl> createDirectUpload() async {
    final response = await _supabase.functions.invoke(
      'stream-upload',
      body: {
        'action': 'create-upload',
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Failed to create upload URL';
      throw Exception(error);
    }

    return StreamUploadUrl.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get the processing status of a video
  Future<StreamVideoInfo> getVideoStatus(String videoUid) async {
    final response = await _supabase.functions.invoke(
      'stream-upload',
      body: {
        'action': 'get-status',
        'videoUid': videoUid,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Failed to get video status';
      throw Exception(error);
    }

    return StreamVideoInfo.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a video from Cloudflare Stream
  Future<void> deleteVideo(String videoUid) async {
    final response = await _supabase.functions.invoke(
      'stream-upload',
      body: {
        'action': 'delete',
        'videoUid': videoUid,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Failed to delete video';
      throw Exception(error);
    }
  }

  /// Upload a video file to Cloudflare Stream using a direct upload URL
  Future<void> uploadVideoToStream({
    required String uploadUrl,
    required File videoFile,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.files.add(
      await http.MultipartFile.fromPath('file', videoFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to upload video to Stream: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
