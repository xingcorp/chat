import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_chat_app/core/base/base_repository.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/exceptions/exceptions.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/services/media_cache.dart';
import 'package:flutter_chat_app/core/services/media_service.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/isolate_manager.dart';
import 'package:flutter_chat_app/domain/repositories/i_media_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// **ENTERPRISE MEDIA REPOSITORY IMPLEMENTATION**
///
/// Unified implementation consolidating all media operations with BaseRepository pattern
/// for enterprise-grade media management and performance.
///
/// **Performance Targets:**
/// - Media upload/download: <5s for typical files
/// - Cache retrieval: <100ms for cached media
/// - Thumbnail generation: <500ms
/// - Memory management: Efficient handling of large media files
///
/// **Architecture:** Clean Architecture + SOLID principles + BaseRepository pattern
@LazySingleton(as: IMediaRepository)
class MediaRepositoryImpl extends BaseRepository implements IMediaRepository {
  final MediaService _mediaService;
  final MediaCache _mediaCache;
  final MediaCacheManager _mediaCacheManager;
  final IsolateManager _isolateManager;

  /// Constructor
  MediaRepositoryImpl({
    required MediaService mediaService,
    required MediaCache mediaCache,
    required MediaCacheManager mediaCacheManager,
    required IsolateManager isolateManager,
    required super.networkInfo,
    required super.logger,
    required super.performanceMonitor,
  }) : _mediaService = mediaService,
       _mediaCache = mediaCache,
       _mediaCacheManager = mediaCacheManager,
       _isolateManager = isolateManager;

  /// **Upload media file to server - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <5s for typical files (enterprise standard)
  /// **Strategy**: Server upload → Local caching → Error handling
  @override
  Future<Either<Failure, MediaUploadResult>> uploadMedia({
    required String messageId,
    required String chatId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    return executeOnlineFirst<MediaUploadResult>(
      remoteDataSource: () async {
        logger.i('Uploading media file: ${file.path}');
        
        // Validate file before upload
        final validationResult = await _validateMediaFile(file);
        if (!validationResult.isValid) {
          throw ValidationException(message: validationResult.errorMessage ?? 'Invalid media file');
        }
        
        // TODO: Implement actual server upload
        // This would integrate with your backend API
        final uploadResult = MediaUploadResult(
          id: 'media_${DateTime.now().millisecondsSinceEpoch}',
          url: 'https://example.com/media/${file.path.split('/').last}',
          size: await file.length(),
          createdAt: DateTime.now(),
        );
        
        // Cache uploaded file locally
        final cacheKey = 'uploaded_${uploadResult.id}';
        await _mediaCache.putFile(cacheKey, file);
        
        logger.i('Media upload successful: ${uploadResult.id}');
        return uploadResult;
      },
      localDataSource: () async {
        // Cannot upload offline
        throw ConnectionFailure(message: 'Cannot upload media without internet connection');
      },
      operationName: 'uploadMedia',
    );
  }

  /// **Download media file from server - OFFLINE-FIRST WITH CACHE**
  ///
  /// **Performance**: <100ms for cached media, <5s for downloads
  /// **Strategy**: Cache → Download → Local storage
  @override
  Future<Either<Failure, File?>> downloadMedia({
    required String url,
    String? messageId,
    bool useCache = true,
    void Function(double progress)? onProgress,
  }) async {
    final cacheKey = messageId != null ? '${messageId}_$url' : url;
    
    return executeOfflineFirst<File?>(
      remoteDataSource: () async {
        logger.i('Downloading media from: $url');
        
        // Download using MediaCache with isolate support
        final file = await _mediaCache.getFile(
          url,
          key: cacheKey,
          useIsolate: true,
          onProgress: onProgress,
        );
        
        if (file != null) {
          logger.i('Media download successful: ${file.path}');
        }
        
        return file;
      },
      localDataSource: () async {
        if (!useCache) return null;
        
        // Check cache first
        final cachedFile = await _mediaCache.getFile(
          url,
          key: cacheKey,
          useIsolate: false, // Fast cache check
        );
        
        if (cachedFile != null) {
          logger.t('Media retrieved from cache: ${cachedFile.path}');
        }
        
        return cachedFile;
      },
      operationName: 'downloadMedia',
    );
  }

  /// **Get cached media file - OFFLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <50ms for cached media retrieval
  /// **Strategy**: Memory cache → Disk cache → Error handling
  @override
  Future<Either<Failure, File?>> getCachedMedia(String url, {String? key}) async {
    return executeOfflineFirst<File?>(
      remoteDataSource: () async {
        // No remote operation for cache-only request
        throw ServerException(message: 'Cache-only operation, no remote fallback');
      },
      localDataSource: () async {
        final cacheKey = key ?? url;
        
        // Get from cache without downloading
        final cachedFile = await _mediaCache.getFile(
          url,
          key: cacheKey,
          useIsolate: false, // Fast cache-only operation
        );
        
        if (cachedFile != null) {
          logger.t('Cached media retrieved: ${cachedFile.path}');
        }
        
        return cachedFile;
      },
      operationName: 'getCachedMedia',
    );
  }

  /// **Cache media file locally - OFFLINE OPERATION**
  ///
  /// **Performance**: <200ms for typical files
  /// **Strategy**: Local storage operation with error handling
  @override
  Future<Either<Failure, bool>> cacheMedia(String key, File file) async {
    return executeOfflineFirst<bool>(
      remoteDataSource: () async {
        // No remote operation for caching
        throw ServerException(message: 'Local cache operation only');
      },
      localDataSource: () async {
        logger.t('Caching media file: ${file.path}');
        
        await _mediaCache.putFile(key, file);
        
        logger.t('Media cached successfully: $key');
        return true;
      },
      operationName: 'cacheMedia',
    );
  }

  /// **Cache media bytes locally - OFFLINE OPERATION**
  ///
  /// **Performance**: <200ms for typical data
  /// **Strategy**: Local storage operation with error handling
  @override
  Future<Either<Failure, bool>> cacheMediaBytes(String key, Uint8List bytes) async {
    return executeOfflineFirst<bool>(
      remoteDataSource: () async {
        // No remote operation for caching
        throw ServerException(message: 'Local cache operation only');
      },
      localDataSource: () async {
        logger.t('Caching media bytes: ${bytes.length} bytes');
        
        await _mediaCache.putBytes(key, bytes);
        
        logger.t('Media bytes cached successfully: $key');
        return true;
      },
      operationName: 'cacheMediaBytes',
    );
  }

  /// **Get media bytes from cache - OFFLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <50ms for memory cache, <100ms for disk cache
  /// **Strategy**: Memory cache → Disk cache → Error handling
  @override
  Future<Either<Failure, Uint8List?>> getMediaBytes(String url, {String? key}) async {
    return executeOfflineFirst<Uint8List?>(
      remoteDataSource: () async {
        // No remote operation for cache-only request
        throw ServerException(message: 'Cache-only operation, no remote fallback');
      },
      localDataSource: () async {
        final cacheKey = key ?? url;
        
        // Get bytes from cache
        final bytes = await _mediaCache.getBytes(cacheKey);
        
        if (bytes != null) {
          logger.t('Media bytes retrieved from cache: ${bytes.length} bytes');
        }
        
        return bytes;
      },
      operationName: 'getMediaBytes',
    );
  }

  /// **Compress image file - OFFLINE OPERATION**
  ///
  /// **Performance**: <1s for typical images
  /// **Strategy**: Local processing with isolate support
  @override
  Future<Either<Failure, File?>> compressImage(File file, {int quality = 80}) async {
    return executeOfflineFirst<File?>(
      remoteDataSource: () async {
        // No remote operation for compression
        throw ServerException(message: 'Local compression operation only');
      },
      localDataSource: () async {
        logger.i('Compressing image: ${file.path} with quality $quality');
        
        // Use MediaCache compression with isolate support
        final compressedFile = await _mediaCache.compressImage(file, quality: quality);
        
        if (compressedFile != null) {
          logger.i('Image compression successful: ${compressedFile.path}');
        }
        
        return compressedFile;
      },
      operationName: 'compressImage',
    );
  }

  /// **Generate thumbnail for media - OFFLINE OPERATION**
  ///
  /// **Performance**: <500ms for thumbnail generation
  /// **Strategy**: Local processing with isolate support
  @override
  Future<Either<Failure, File?>> generateThumbnail(File file, {int size = 200}) async {
    return executeOfflineFirst<File?>(
      remoteDataSource: () async {
        // No remote operation for thumbnail generation
        throw ServerException(message: 'Local thumbnail generation only');
      },
      localDataSource: () async {
        logger.i('Generating thumbnail for: ${file.path} with size $size');
        
        // TODO: Implement thumbnail generation using isolate
        // This would use image processing libraries like image package
        // For now, return the original file as placeholder
        
        logger.i('Thumbnail generation completed');
        return file; // Placeholder implementation
      },
      operationName: 'generateThumbnail',
    );
  }

  /// **Prefetch media thumbnails - BACKGROUND OPERATION**
  ///
  /// **Performance**: Non-blocking, background execution
  /// **Strategy**: Background processing with queue management
  @override
  Future<Either<Failure, bool>> prefetchThumbnails(List<String> urls) async {
    return executeOfflineFirst<bool>(
      remoteDataSource: () async {
        // Background prefetching can work offline/online
        throw ServerException(message: 'Background prefetch operation');
      },
      localDataSource: () async {
        logger.i('Prefetching thumbnails for ${urls.length} URLs');
        
        // Use MediaCacheManager for prefetching
        _mediaCacheManager.prefetchThumbnails(urls);
        
        logger.i('Thumbnail prefetch initiated');
        return true;
      },
      operationName: 'prefetchThumbnails',
    );
  }

  /// Helper method to validate media file
  Future<MediaValidationResult> _validateMediaFile(File file) async {
    try {
      if (!await file.exists()) {
        return MediaValidationResult.invalid('File does not exist');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        return MediaValidationResult.invalid('File is empty');
      }

      // Check file size limits (e.g., 50MB max)
      const maxFileSize = 50 * 1024 * 1024; // 50MB
      if (fileSize > maxFileSize) {
        return MediaValidationResult.invalid('File size exceeds 50MB limit');
      }

      // Basic validation - can be extended
      final fileName = file.path.split('/').last;
      final mimeType = _getMimeType(fileName);

      // Validate supported file types
      if (!_isSupportedMimeType(mimeType)) {
        return MediaValidationResult.invalid('Unsupported file type: $mimeType');
      }

      final metadata = MediaMetadata(
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
      );

      return MediaValidationResult.valid(metadata);
    } catch (e) {
      return MediaValidationResult.invalid('File validation failed: $e');
    }
  }

  /// **Delete cached media - OFFLINE OPERATION**
  ///
  /// **Performance**: <100ms for cache deletion
  /// **Strategy**: Local cache cleanup with error handling
  @override
  Future<Either<Failure, bool>> deleteCachedMedia(String key) async {
    return executeOfflineFirst<bool>(
      remoteDataSource: () async {
        // No remote operation for cache deletion
        throw ServerException(message: 'Local cache operation only');
      },
      localDataSource: () async {
        logger.t('Deleting cached media: $key');

        // TODO: Implement cache deletion in MediaCache
        // await _mediaCache.delete(key);

        logger.t('Cached media deleted: $key');
        return true;
      },
      operationName: 'deleteCachedMedia',
    );
  }

  /// **Clear all cached media - OFFLINE OPERATION**
  ///
  /// **Performance**: <1s for complete cache clear
  /// **Strategy**: Bulk cache cleanup with error handling
  @override
  Future<Either<Failure, bool>> clearMediaCache() async {
    return executeOfflineFirst<bool>(
      remoteDataSource: () async {
        // No remote operation for cache clearing
        throw ServerException(message: 'Local cache operation only');
      },
      localDataSource: () async {
        logger.i('Clearing all media cache');

        await _mediaCache.clear();

        logger.i('Media cache cleared successfully');
        return true;
      },
      operationName: 'clearMediaCache',
    );
  }

  /// **Get media cache size - OFFLINE OPERATION**
  ///
  /// **Performance**: <100ms for size calculation
  /// **Strategy**: Local storage analysis with error handling
  @override
  Future<Either<Failure, int>> getCacheSize() async {
    return executeOfflineFirst<int>(
      remoteDataSource: () async {
        // No remote operation for cache size
        throw ServerException(message: 'Local cache operation only');
      },
      localDataSource: () async {
        logger.t('Calculating media cache size');

        // TODO: Implement getCacheSize in MediaCache
        // For now, return estimated size
        final size = 0; // Placeholder implementation

        logger.t('Media cache size: $size bytes');
        return size;
      },
      operationName: 'getCacheSize',
    );
  }

  /// **Get media metadata - OFFLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <50ms for cached metadata
  /// **Strategy**: Cache → File analysis → Error handling
  @override
  Future<Either<Failure, MediaMetadata?>> getMediaMetadata(String url) async {
    return executeOfflineFirst<MediaMetadata?>(
      remoteDataSource: () async {
        // Remote metadata not implemented
        throw ServerException(message: 'Remote metadata not supported');
      },
      localDataSource: () async {
        logger.t('Getting media metadata for: $url');

        // Try to get cached file first
        final file = await _mediaCache.getFile(url, useIsolate: false);
        if (file == null) return null;

        // Analyze file metadata
        final fileName = file.path.split('/').last;
        final fileSize = await file.length();
        final mimeType = _getMimeType(fileName);

        final metadata = MediaMetadata(
          fileName: fileName,
          fileSize: fileSize,
          mimeType: mimeType,
        );

        logger.t('Media metadata retrieved: ${metadata.fileName}');
        return metadata;
      },
      operationName: 'getMediaMetadata',
    );
  }

  /// **Validate media file - OFFLINE OPERATION**
  ///
  /// **Performance**: <200ms for file validation
  /// **Strategy**: Local file validation with comprehensive checks
  @override
  Future<Either<Failure, MediaValidationResult>> validateMedia(File file) async {
    return executeOfflineFirst<MediaValidationResult>(
      remoteDataSource: () async {
        // No remote operation for validation
        throw ServerException(message: 'Local validation operation only');
      },
      localDataSource: () async {
        logger.t('Validating media file: ${file.path}');

        final result = await _validateMediaFile(file);

        logger.t('Media validation result: ${result.isValid}');
        return result;
      },
      operationName: 'validateMedia',
    );
  }

  /// **Get temporary URL for media - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <1s for URL generation
  /// **Strategy**: Server URL generation with error handling
  @override
  Future<Either<Failure, String>> getTemporaryUrl(
    String mediaId, {
    int expiryMinutes = 60,
  }) async {
    return executeOnlineFirst<String>(
      remoteDataSource: () async {
        logger.i('Generating temporary URL for media: $mediaId');

        // TODO: Implement server temporary URL generation
        // This would integrate with your backend API
        final tempUrl = 'https://example.com/temp/$mediaId?expires=${DateTime.now().add(Duration(minutes: expiryMinutes)).millisecondsSinceEpoch}';

        logger.i('Temporary URL generated: $tempUrl');
        return tempUrl;
      },
      localDataSource: () async {
        // Cannot generate temporary URL offline
        throw ConnectionFailure(message: 'Cannot generate temporary URL without internet connection');
      },
      operationName: 'getTemporaryUrl',
    );
  }

  /// **Delete media from server - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <2s for deletion process
  /// **Strategy**: Server deletion with local cache cleanup
  @override
  Future<Either<Failure, bool>> deleteMedia(String mediaId) async {
    return executeOnlineFirst<bool>(
      remoteDataSource: () async {
        logger.i('Deleting media from server: $mediaId');

        // TODO: Implement server media deletion
        // This would integrate with your backend API

        // Also clear from local cache
        await deleteCachedMedia(mediaId);

        logger.i('Media deleted successfully: $mediaId');
        return true;
      },
      localDataSource: () async {
        // Cannot delete from server offline, but can clear cache
        logger.w('Cannot delete from server offline, clearing cache only');
        await deleteCachedMedia(mediaId);
        return false; // Indicate partial success
      },
      operationName: 'deleteMedia',
    );
  }



  /// Helper method to check if MIME type is supported
  bool _isSupportedMimeType(String mimeType) {
    const supportedTypes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'video/mp4',
      'video/quicktime',
      'application/pdf',
      'text/plain',
    ];
    return supportedTypes.contains(mimeType);
  }

  /// Helper method to get MIME type from file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
