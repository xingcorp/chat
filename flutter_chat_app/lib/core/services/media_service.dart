import 'dart:io';
import 'dart:ui';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

class MediaDimensions {
  final double width;
  final double height;

  MediaDimensions(this.width, this.height);
}

@singleton
class MediaService {
  final BaseCacheManager _cacheManager;
  final String _mediaDirectory;
  
  // Cache to avoid repeated disk operations for the same file
  final Map<String, File> _localFileCache = {};
  final Map<String, MediaDimensions> _dimensionsCache = {};
  
  // For testing/production implementation
  @factoryMethod
  static Future<MediaService> create() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = '${appDir.path}/media';
    
    // Ensure directory exists
    final directory = Directory(mediaDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return MediaService._(
      DefaultCacheManager(),
      mediaDir,
    );
  }
  
  MediaService._(this._cacheManager, this._mediaDirectory);
  
  /// Get local media file if exists
  Future<File?> getLocalMediaFile(String messageId, String url) async {
    final cacheKey = '$messageId-$url';
    
    if (_localFileCache.containsKey(cacheKey)) {
      return _localFileCache[cacheKey];
    }
    
    final fileName = url.split('/').last;
    final localPath = '$_mediaDirectory/$messageId-$fileName';
    final file = File(localPath);
    
    if (await file.exists()) {
      _localFileCache[cacheKey] = file;
      return file;
    }
    
    // Check if file exists in cache manager
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        // Copy to our managed directory for persistence
        await fileInfo.file.copy(localPath);
        final localFile = File(localPath);
        _localFileCache[cacheKey] = localFile;
        return localFile;
      }
    } catch (e) {
      // Ignore cache errors, will download instead
    }
    
    return null;
  }
  
  /// Download media from remote URL
  void downloadMedia(
    String messageId,
    String url, {
    Function(double progress)? onProgress,
    Function(File file)? onSuccess,
    Function(dynamic error)? onError,
  }) async {
    try {
      // First check if we already have it
      final existingFile = await getLocalMediaFile(messageId, url);
      if (existingFile != null) {
        onSuccess?.call(existingFile);
        return;
      }
      
      final fileName = url.split('/').last;
      final localPath = '$_mediaDirectory/$messageId-$fileName';
      
      // Download with the cache manager
      final fileStream = _cacheManager.getFileStream(
        url,
        withProgress: true,
      );
      
      double lastProgress = 0;
      await for (final result in fileStream) {
        if (result is DownloadProgress) {
          final progress = result.progress;
          if (progress != null && (progress - lastProgress).abs() > 0.05) {
            lastProgress = progress;
            onProgress?.call(progress);
          }
        }
        
        if (result is FileInfo) {
          // Copy to our managed directory for persistence
          await result.file.copy(localPath);
          final localFile = File(localPath);
          _localFileCache['$messageId-$url'] = localFile;
          onSuccess?.call(localFile);
          break;
        }
      }
    } catch (e) {
      onError?.call(e);
    }
  }
  
  /// Get dimensions of a media file
  Future<MediaDimensions?> getMediaDimensions(File file) async {
    final path = file.path;
    
    if (_dimensionsCache.containsKey(path)) {
      return _dimensionsCache[path];
    }
    
    try {
      // This is a simple implementation - you might want to use a more
      // sophisticated approach based on media type (image/video)
      final codec = await instantiateImageCodec(
        await file.readAsBytes(),
        targetWidth: 1,
        targetHeight: 1,
      );
      
      final frameInfo = await codec.getNextFrame();
      final dimensions = MediaDimensions(
        frameInfo.image.width.toDouble(),
        frameInfo.image.height.toDouble(),
      );
      
      _dimensionsCache[path] = dimensions;
      return dimensions;
    } catch (e) {
      // Return default dimensions on error
      return MediaDimensions(16, 9);
    }
  }
  
  /// Compress an image file before uploading
  Future<File?> compressImageFile(File file, {int quality = 70}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${const Uuid().v4()}.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1024, // Limit max resolution
        minHeight: 1024,
      );
      
      return result != null ? File(result.path) : null;
    } catch (e) {
      return null;
    }
  }
  
  /// Clear all cached media files that are older than the specified duration
  Future<void> clearOldMediaCache({Duration maxAge = const Duration(days: 7)}) async {
    try {
      final dir = Directory(_mediaDirectory);
      if (!await dir.exists()) return;
      
      final now = DateTime.now();
      final files = await dir.list().toList();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final fileAge = now.difference(stat.modified);
          
          if (fileAge > maxAge) {
            await file.delete();
            // Also remove from memory cache
            _localFileCache.removeWhere((_, f) => f.path == file.path);
            _dimensionsCache.remove(file.path);
          }
        }
      }
    } catch (e) {
      // Log error but don't crash
    }
  }
  
  /// Clear all media caches (both memory and disk)
  Future<void> clearAllMediaCache() async {
    try {
      // Clear memory cache
      _localFileCache.clear();
      _dimensionsCache.clear();
      
      // Clear disk cache
      final dir = Directory(_mediaDirectory);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
      
      // Clear cache manager
      await _cacheManager.emptyCache();
    } catch (e) {
      // Log error but don't crash
    }
  }
} 