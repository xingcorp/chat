import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

/// **ENTERPRISE MEDIA REPOSITORY INTERFACE**
///
/// Unified interface for media operations with comprehensive error handling
/// and performance optimization for enterprise-grade media management.
///
/// **Error Handling**: All methods return Either<Failure, T> for consistent error management
/// **Performance**: Optimized for enterprise media standards
/// **Architecture**: Clean Architecture with SOLID principles
abstract class IMediaRepository {
  /// **Upload media file to server - ONLINE-FIRST STRATEGY**
  ///
  /// **Strategy**: executeOnlineFirst (server upload required)
  /// **Performance**: <5s for typical files (enterprise standard)
  /// **Use Case**: Message attachments, profile pictures, media sharing
  Future<Either<Failure, MediaUploadResult>> uploadMedia({
    required String messageId,
    required String chatId,
    required File file,
    void Function(double progress)? onProgress,
  });

  /// **Download media file from server - ONLINE-FIRST WITH CACHE**
  ///
  /// **Strategy**: executeOfflineFirst (cached media priority)
  /// **Performance**: <100ms for cached media, <5s for downloads
  /// **Use Case**: Media viewing, attachment downloads
  Future<Either<Failure, File?>> downloadMedia({
    required String url,
    String? messageId,
    bool useCache = true,
    void Function(double progress)? onProgress,
  });

  /// **Get cached media file - OFFLINE-FIRST STRATEGY**
  ///
  /// **Strategy**: executeOfflineFirst (cache-only operation)
  /// **Performance**: <50ms for cached media retrieval
  /// **Use Case**: Quick media access, thumbnail loading
  Future<Either<Failure, File?>> getCachedMedia(String url, {String? key});

  /// **Cache media file locally - OFFLINE OPERATION**
  ///
  /// **Strategy**: Local storage operation
  /// **Performance**: <200ms for typical files
  /// **Use Case**: Preloading, offline availability
  Future<Either<Failure, bool>> cacheMedia(String key, File file);

  /// **Cache media bytes locally - OFFLINE OPERATION**
  ///
  /// **Strategy**: Local storage operation
  /// **Performance**: <200ms for typical data
  /// **Use Case**: In-memory to disk caching
  Future<Either<Failure, bool>> cacheMediaBytes(String key, Uint8List bytes);

  /// **Get media bytes from cache - OFFLINE-FIRST STRATEGY**
  ///
  /// **Strategy**: executeOfflineFirst (memory → disk → error)
  /// **Performance**: <50ms for memory cache, <100ms for disk cache
  /// **Use Case**: Image processing, thumbnail generation
  Future<Either<Failure, Uint8List?>> getMediaBytes(String url, {String? key});

  /// **Compress image file - OFFLINE OPERATION**
  ///
  /// **Strategy**: Local processing with isolate support
  /// **Performance**: <1s for typical images
  /// **Use Case**: Upload optimization, storage efficiency
  Future<Either<Failure, File?>> compressImage(File file, {int quality = 80});

  /// **Generate thumbnail for media - OFFLINE OPERATION**
  ///
  /// **Strategy**: Local processing with isolate support
  /// **Performance**: <500ms for thumbnail generation
  /// **Use Case**: Chat previews, gallery thumbnails
  Future<Either<Failure, File?>> generateThumbnail(File file, {int size = 200});

  /// **Prefetch media thumbnails - BACKGROUND OPERATION**
  ///
  /// **Strategy**: Background processing with queue management
  /// **Performance**: Non-blocking, background execution
  /// **Use Case**: Chat message preloading, smooth scrolling
  Future<Either<Failure, bool>> prefetchThumbnails(List<String> urls);

  /// **Delete cached media - OFFLINE OPERATION**
  ///
  /// **Strategy**: Local cache cleanup
  /// **Performance**: <100ms for cache deletion
  /// **Use Case**: Storage management, cache cleanup
  Future<Either<Failure, bool>> deleteCachedMedia(String key);

  /// **Clear all cached media - OFFLINE OPERATION**
  ///
  /// **Strategy**: Bulk cache cleanup
  /// **Performance**: <1s for complete cache clear
  /// **Use Case**: Storage cleanup, reset functionality
  Future<Either<Failure, bool>> clearMediaCache();

  /// **Get media cache size - OFFLINE OPERATION**
  ///
  /// **Strategy**: Local storage analysis
  /// **Performance**: <100ms for size calculation
  /// **Use Case**: Storage monitoring, cache management
  Future<Either<Failure, int>> getCacheSize();

  /// **Get media metadata - OFFLINE-FIRST STRATEGY**
  ///
  /// **Strategy**: executeOfflineFirst (cached metadata priority)
  /// **Performance**: <50ms for cached metadata
  /// **Use Case**: Media information display, validation
  Future<Either<Failure, MediaMetadata?>> getMediaMetadata(String url);

  /// **Validate media file - OFFLINE OPERATION**
  ///
  /// **Strategy**: Local file validation
  /// **Performance**: <200ms for file validation
  /// **Use Case**: Upload validation, file integrity check
  Future<Either<Failure, MediaValidationResult>> validateMedia(File file);

  /// **Get temporary URL for media - ONLINE-FIRST STRATEGY**
  ///
  /// **Strategy**: executeOnlineFirst (server URL generation)
  /// **Performance**: <1s for URL generation
  /// **Use Case**: Secure media access, temporary sharing
  Future<Either<Failure, String>> getTemporaryUrl(
    String mediaId, {
    int expiryMinutes = 60,
  });

  /// **Delete media from server - ONLINE-FIRST STRATEGY**
  ///
  /// **Strategy**: executeOnlineFirst (server deletion required)
  /// **Performance**: <2s for deletion process
  /// **Use Case**: Media cleanup, privacy management
  Future<Either<Failure, bool>> deleteMedia(String mediaId);
}

/// **Media Upload Result**
class MediaUploadResult {
  final String id;
  final String url;
  final int size;
  final DateTime createdAt;
  final String? thumbnailUrl;

  const MediaUploadResult({
    required this.id,
    required this.url,
    required this.size,
    required this.createdAt,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'size': size,
      'created_at': createdAt.toIso8601String(),
      'thumbnail_url': thumbnailUrl,
    };
  }

  factory MediaUploadResult.fromJson(Map<String, dynamic> json) {
    return MediaUploadResult(
      id: json['id'] as String,
      url: json['url'] as String,
      size: json['size'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}

/// **Media Metadata**
class MediaMetadata {
  final String fileName;
  final int fileSize;
  final String mimeType;
  final int? width;
  final int? height;
  final int? duration; // for video/audio in seconds

  const MediaMetadata({
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    this.width,
    this.height,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'width': width,
      'height': height,
      'duration': duration,
    };
  }

  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int,
      mimeType: json['mime_type'] as String,
      width: json['width'] as int?,
      height: json['height'] as int?,
      duration: json['duration'] as int?,
    );
  }
}

/// **Media Validation Result**
class MediaValidationResult {
  final bool isValid;
  final String? errorMessage;
  final MediaMetadata? metadata;

  const MediaValidationResult({
    required this.isValid,
    this.errorMessage,
    this.metadata,
  });

  factory MediaValidationResult.valid(MediaMetadata metadata) {
    return MediaValidationResult(
      isValid: true,
      metadata: metadata,
    );
  }

  factory MediaValidationResult.invalid(String errorMessage) {
    return MediaValidationResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}
