import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a presigned upload URL response from the Edge Function
class PresignedUpload {
  final String presignedUrl;
  final String publicUrl;
  final String storagePath;
  final String contentType;

  PresignedUpload({
    required this.presignedUrl,
    required this.publicUrl,
    required this.storagePath,
    required this.contentType,
  });

  factory PresignedUpload.fromJson(Map<String, dynamic> json) {
    return PresignedUpload(
      presignedUrl: json['presignedUrl'] as String,
      publicUrl: json['publicUrl'] as String,
      storagePath: json['storagePath'] as String,
      contentType: json['contentType'] as String? ?? 'image/jpeg',
    );
  }
}

/// Represents a presigned delete URL response from the Edge Function
class PresignedDelete {
  final String presignedUrl;
  final String storagePath;

  PresignedDelete({
    required this.presignedUrl,
    required this.storagePath,
  });

  factory PresignedDelete.fromJson(Map<String, dynamic> json) {
    return PresignedDelete(
      presignedUrl: json['presignedUrl'] as String,
      storagePath: json['storagePath'] as String,
    );
  }
}

/// Service for interacting with Cloudflare R2 storage via Supabase Edge Functions
class R2StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _httpClient = SentryHttpClient(client: http.Client());

  /// Get a presigned URL for uploading a single file to R2
  Future<PresignedUpload> getPresignedUploadUrl({
    required String postId,
    required String contentType,
  }) async {
    final response = await _supabase.functions.invoke(
      'r2-presign',
      body: {
        'action': 'upload',
        'postId': postId,
        'contentType': contentType,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Failed to get presigned URL';
      throw Exception(error);
    }

    final files = response.data['files'] as List<dynamic>;
    if (files.isEmpty) {
      throw Exception('No presigned URL returned');
    }

    final firstFile = files.first as Map<String, dynamic>;
    if (firstFile.containsKey('error')) {
      throw Exception(firstFile['error']);
    }

    return PresignedUpload.fromJson(firstFile);
  }

  /// Get presigned URLs for uploading multiple files to R2
  Future<List<PresignedUpload>> getPresignedUploadUrls({
    required String postId,
    required List<String> contentTypes,
  }) async {
    final files = contentTypes.map((ct) => {
      'postId': postId,
      'contentType': ct,
    }).toList();

    final response = await _supabase.functions.invoke(
      'r2-presign',
      body: {
        'action': 'upload',
        'files': files,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Failed to get presigned URLs';
      throw Exception(error);
    }

    final responseFiles = response.data['files'] as List<dynamic>;
    return responseFiles
        .map((f) => f as Map<String, dynamic>)
        .where((f) => !f.containsKey('error'))
        .map((f) => PresignedUpload.fromJson(f))
        .toList();
  }

  /// Upload bytes directly to R2 using a presigned URL
  Future<void> uploadToR2({
    required String presignedUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final response = await _httpClient.put(
      Uri.parse(presignedUrl),
      headers: {
        'Content-Type': contentType,
        'Content-Length': bytes.length.toString(),
      },
      body: bytes,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload to R2: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get a presigned URL for deleting a file from R2
  Future<PresignedDelete> getPresignedDeleteUrl({
    required String storagePath,
  }) async {
    final response = await _supabase.functions.invoke(
      'r2-presign',
      body: {
        'action': 'delete',
        'storagePath': storagePath,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Failed to get delete URL';
      throw Exception(error);
    }

    final files = response.data['files'] as List<dynamic>;
    if (files.isEmpty) {
      throw Exception('No presigned delete URL returned');
    }

    final firstFile = files.first as Map<String, dynamic>;
    if (firstFile.containsKey('error')) {
      throw Exception(firstFile['error']);
    }

    return PresignedDelete.fromJson(firstFile);
  }

  /// Delete a file from R2 using a presigned URL
  Future<void> deleteFromR2({
    required String storagePath,
  }) async {
    final presigned = await getPresignedDeleteUrl(storagePath: storagePath);

    final response = await _httpClient.delete(Uri.parse(presigned.presignedUrl));

    // R2 returns 204 for successful deletes
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete from R2: ${response.statusCode}');
    }
  }
}
