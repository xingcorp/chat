import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/data/dtos/chat_object_dto.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';
import 'package:injectable/injectable.dart';

/// **Storage Remote Data Source Interface**
///
/// Handles file upload/download operations for chat attachments.
/// Implements 2-step upload process matching Angular frontend.
///
/// **Matching Angular:** upload-file.service.ts
///
/// **Upload Flow:**
/// 1. Call storageGeneratePresignedUrls → get presignedUrl, path, url
/// 2. PUT file binary to presignedUrl with Content-Type header
/// 3. Use url in chatMessageAdd (urls field)
abstract class IChatObjectRemoteDataSource {
  /// Generate pre-signed upload URLs for files
  ///
  /// **Matching Angular:** storageGeneratePresignedUrls in upload-file.service.ts
  ///
  /// [files] - List of files with fileName and fileType (MIME type)
  /// Returns upload data with presignedUrl for upload and url for message
  Future<StorageUploadResponseDto> generateUploadLinks({
    required List<GeneratePresignedUrlParams> files,
  });

  /// Upload file binary to presigned URL
  ///
  /// **Matching Angular:** uploadMessageFileS3Observable in upload-file.service.ts
  ///
  /// [presignedUrl] - Pre-signed URL for direct upload
  /// [filePath] - Local file path
  /// [contentType] - MIME type for Content-Type header
  /// [onProgress] - Upload progress callback
  Future<void> uploadFile({
    required String presignedUrl,
    required String filePath,
    required String contentType,
    ProgressCallback? onProgress,
  });

  /// Upload bytes directly to presigned URL (for web platform)
  ///
  /// [presignedUrl] - Pre-signed URL for direct upload
  /// [bytes] - File bytes to upload
  /// [contentType] - MIME type for Content-Type header
  /// [onProgress] - Upload progress callback (0.0 to 1.0)
  Future<void> uploadBytes({
    required String presignedUrl,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  });

  /// Get download URL for uploaded file
  Future<ChatObjectGetUrlResponseDto> getObjectUrl(String path);
}

/// **Storage Remote Data Source Implementation**
///
/// Uses GraphQL for API calls and Dio for file uploads.
/// Matches Angular frontend upload-file.service.ts implementation.
@LazySingleton(as: IChatObjectRemoteDataSource)
class ChatObjectRemoteDataSource implements IChatObjectRemoteDataSource {
  final GraphQLClientWrapper _client;
  final Dio _dio;

  ChatObjectRemoteDataSource(
    this._client,
    @Named('uploadClient') this._dio,
  );

  @override
  Future<StorageUploadResponseDto> generateUploadLinks({
    required List<GeneratePresignedUrlParams> files,
  }) async {
    // Build arguments matching Angular: { arguments: { files: [...] } }
    final args = UploadFileArgs(files: files);

    final result = await _client.mutate(
      ChatMutations.generateUploadLink,
      variables: {'arguments': args.toJson()},
    );

    final data = result['storageGeneratePresignedUrls'];
    if (data == null) {
      throw Exception('No upload links returned from server');
    }

    return StorageUploadResponseDto.fromJson(data);
  }

  @override
  Future<void> uploadFile({
    required String presignedUrl,
    required String filePath,
    required String contentType,
    ProgressCallback? onProgress,
  }) async {
    try {
      // Read file as bytes - matching Angular httpClient.put(url, file, {headers})
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Upload raw bytes directly, matching Angular's httpClient.put(url, file).
      await _dio.put(
        presignedUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  @override
  Future<void> uploadBytes({
    required String presignedUrl,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Upload raw bytes directly - for web/platform flows without File access.
      await _dio.put(
        presignedUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );
    } catch (e) {
      throw Exception('Failed to upload bytes: $e');
    }
  }

  @override
  Future<ChatObjectGetUrlResponseDto> getObjectUrl(String path) async {
    final result = await _client.query(
      ChatMutations.getObjectUrl,
      variables: {'path': path},
    );

    final data = result['chatObjectGetUrl'];
    if (data == null) {
      throw Exception('No URL returned from server');
    }

    return ChatObjectGetUrlResponseDto.fromJson(data);
  }
}
