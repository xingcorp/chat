import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:uuid/uuid.dart';

// Enum to represent video quality
enum VideoQuality {
  lowQuality,
  mediumQuality,
  highQuality,
  ultraHighQuality
}

/// Service responsible for managing media resources in the chat application
/// Handles progressive loading, compression, and caching of media files
@lazySingleton
class ResourceManagerService {
  final BehaviorSubject<double> _cacheSizeSubject = BehaviorSubject<double>.seeded(0);
  Stream<double> get cacheSizeStream => _cacheSizeSubject.stream;
  
  late final BaseCacheManager _cacheManager;
  late final String _cacheDirectory;
  late final String _tempDirectory;
  
  // Configurable parameters
  int maxCacheSizeMB = 200; // 200 MB default
  int cacheDurationDays = 7; // 7 days default
  int imageCompressionThreshold = 1024 * 1024; // 1MB
  
  ResourceManagerService() {
    _initService();
  }
  
  Future<void> _initService() async {
    if (kIsWeb) {
      _cacheDirectory = 'media_cache';
      _tempDirectory = 'temp';
      _cacheManager = DefaultCacheManager();
      _cacheSizeSubject.add(0);
      return;
    }

    // Initialize directories
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = path.join(appDir.path, 'media_cache');
    _tempDirectory = path.join(appDir.path, 'temp');
    
    // Create directories if they don't exist
    await Directory(_cacheDirectory).create(recursive: true);
    await Directory(_tempDirectory).create(recursive: true);
    
    // Initialize cache manager
    _cacheManager = DefaultCacheManager();
    
    // Schedule cache cleanup
    _scheduleCacheCleanup();
    
    // Calculate and update current cache size
    _updateCacheSize();
  }
  
  /// Compresses an image file
  /// Returns the path to the compressed file
  Future<File?> compressImage({
    required File file,
    int quality = 80,
    int? targetWidth,
    int? targetHeight,
  }) async {
    try {
      final fileSize = await file.length();
      
      // For larger images, use compute to avoid blocking the UI thread
      if (fileSize > imageCompressionThreshold) {
        return await compute(_compressImageInIsolate, {
          'path': file.path,
          'quality': quality,
          'targetWidth': targetWidth,
          'targetHeight': targetHeight,
          'outputPath': '$_tempDirectory/${const Uuid().v4()}.jpg',
        });
      }
      
      // For smaller images, compress directly
      final outputPath = '$_tempDirectory/${const Uuid().v4()}.jpg';
      
      // Note: This is a simplified implementation
      // In a real application, you would use an image compression package
      debugPrint('Image would be compressed with quality: $quality');
      
      return file.copy(outputPath);
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }
  
  // Helper method to compress image in isolate - simplified implementation
  static Future<File?> _compressImageInIsolate(Map<String, dynamic> params) async {
    try {
      final inputFile = File(params['path']);
      final outputFile = File(params['outputPath']);
      
      // Simplified implementation - in reality would use an image compression package
      return inputFile.copy(outputFile.path);
    } catch (e) {
      debugPrint('Image compression in isolate error: $e');
      return null;
    }
  }
  
  /// Compresses a video file - simplified implementation
  /// Returns the path to the compressed file
  Future<File?> compressVideo({
    required File file,
    VideoQuality quality = VideoQuality.mediumQuality,
  }) async {
    try {
      // This is a simplified implementation
      // In a real application, you would use a video compression package
      
      final outputPath = '$_tempDirectory/${const Uuid().v4()}.mp4';
      debugPrint('Video would be compressed with quality: $quality');
      
      return file.copy(outputPath);
    } catch (e) {
      debugPrint('Video compression error: $e');
      return null;
    }
  }
  
  /// Creates a thumbnail from a video file - simplified implementation
  Future<File?> createVideoThumbnail({
    required String videoPath,
    int quality = 50,
    int maxWidth = 300,
    int maxHeight = 300,
  }) async {
    try {
      // Simplified implementation - in a real app would use a video processing package
      final outputPath = '$_tempDirectory/${const Uuid().v4()}_thumb.jpg';
      debugPrint('Video thumbnail would be created from: $videoPath with quality: $quality');
      
      // Just create an empty file for demonstration purposes
      return File(outputPath).create();
    } catch (e) {
      debugPrint('Video thumbnail creation error: $e');
      return null;
    }
  }
  
  /// Creates a thumbnail from an image file - simplified implementation
  Future<File?> createImageThumbnail({
    required File imageFile,
    int maxWidth = 300,
    int maxHeight = 300,
    int quality = 70,
  }) async {
    try {
      final outputPath = '$_tempDirectory/${const Uuid().v4()}_thumb.jpg';
      
      // Simplified implementation - would use an image processing package
      debugPrint('Image thumbnail would be created with dimensions: $maxWidth x $maxHeight, quality: $quality');
      
      return imageFile.copy(outputPath);
    } catch (e) {
      debugPrint('Image thumbnail creation error: $e');
      return null;
    }
  }
  
  /// Downloads a file from a URL with optional progress tracking
  Future<File?> downloadFile({
    required String url,
    required String fileName,
    bool cache = true,
    Stream<double>? progressStream,
  }) async {
    try {
      if (cache) {
        // Download with caching
        final fileInfo = await _cacheManager.downloadFile(
          url,
          key: fileName,
          authHeaders: <String, String>{},
        );
        return fileInfo.file;
      } else {
        // Download to temp directory without caching
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(url));
        final response = await request.close();
        
        final outputFile = File('$_tempDirectory/$fileName');
        final sink = outputFile.openWrite();
        
        int totalBytes = response.contentLength;
        int receivedBytes = 0;
        
        final progressController = StreamController<double>();
        if (progressStream != null) {
          progressController.stream.pipe(progressStream as StreamConsumer<double>);
        }
        
        await response.forEach((bytes) {
          receivedBytes += bytes.length;
          sink.add(bytes);
          if (totalBytes > 0 && progressStream != null) {
            progressController.add(receivedBytes / totalBytes);
          }
        });
        
        await sink.close();
        await progressController.close();
        
        return outputFile;
      }
    } catch (e) {
      debugPrint('File download error: $e');
      return null;
    }
  }
  
  /// Loads an image with a blur effect while the full image is loading
  Widget loadImageWithBlur({
    required String url,
    double blurAmount = 10.0,
    int thumbnailSize = 100,
    BoxFit fit = BoxFit.cover,
    double width = double.infinity,
    double height = double.infinity,
    Widget? loadingPlaceholder,
    Widget? errorWidget,
  }) {
    // Generate a thumbnail URL - this assumes your backend supports size parameters
    // Adjust this logic based on your actual backend URL structure
    String thumbnailUrl = url;
    if (url.contains('?')) {
      thumbnailUrl = '$url&width=$thumbnailSize&height=$thumbnailSize';
    } else {
      thumbnailUrl = '$url?width=$thumbnailSize&height=$thumbnailSize';
    }
    
    return Stack(
      children: [
        // Blurred small image (loads first)
        Image.network(
          thumbnailUrl,
          fit: fit,
          width: width,
          height: height,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                child: child,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return loadingPlaceholder ?? const Center(
              child: CircularProgressIndicator(),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? const Center(
              child: Icon(Icons.error_outline, color: Colors.red),
            );
          },
        ),
        
        // Full resolution image (loads second)
        Image.network(
          url,
          fit: fit,
          width: width,
          height: height,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox.shrink();
          },
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
  
  /// Progressive loading of media (thumbnail first, then full resolution)
  Widget progressiveMediaLoader({
    required String url,
    required String mediaType, // 'image' or 'video'
    double thumbnailQuality = 20.0,
    double fullQuality = 100.0,
    double width = double.infinity,
    double height = double.infinity,
    BoxFit fit = BoxFit.cover,
    bool autoPlay = false,
    Widget? loadingWidget,
    Widget? errorWidget,
    Function(double)? onProgress,
    Function(Object)? onError,
  }) {
    // TODO: Implement proper progress tracking with dispose mechanism
    // StreamController approach causes memory leaks in this context
    // Consider using StatefulWidget or callback-based progress tracking
    
    if (mediaType.toLowerCase() == 'image') {
      return loadImageWithBlur(
        url: url,
        blurAmount: 5.0,
        thumbnailSize: 200,
        width: width,
        height: height,
        fit: fit,
        loadingPlaceholder: loadingWidget,
        errorWidget: errorWidget,
      );
    } else if (mediaType.toLowerCase() == 'video') {
      // Implement video progressive loading
      // This is a placeholder - integrate with your video player of choice
      return FutureBuilder<String?>(
        future: _getVideoThumbnailUrl(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return loadingWidget ?? const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return errorWidget ?? const Center(child: Icon(Icons.error));
          } else {
            // Return video thumbnail with play button overlay
            return Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  snapshot.data!,
                  width: width,
                  height: height,
                  fit: fit,
                  errorBuilder: (context, error, stackTrace) {
                    return errorWidget ?? const Center(child: Icon(Icons.error));
                  },
                ),
                Icon(
                  Icons.play_circle_fill,
                  size: 50,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            );
          }
        },
      );
    } else {
      return errorWidget ?? const Center(child: Text('Unsupported media type'));
    }
  }
  
  // Placeholder method for getting video thumbnail URL
  Future<String?> _getVideoThumbnailUrl(String videoUrl) async {
    // You would implement logic to get a thumbnail URL from your backend
    // Or generate one locally if you have the video file
    // For now, just return the same URL
    return videoUrl;
  }
  
  /// Cleans up old cache files based on age and total size
  Future<void> cleanupCache({bool force = false}) async {
    if (kIsWeb) return;
    try {
      final cacheDir = Directory(_cacheDirectory);
      if (!await cacheDir.exists()) return;
      
      final currentSize = await _calculateDirectorySize(cacheDir);
      final maxSize = maxCacheSizeMB * 1024 * 1024;
      
      // If cache is smaller than threshold and not forcing cleanup, return
      if (currentSize < maxSize && !force) return;
      
      // List all files in cache directory and sort by last modified time
      final files = await cacheDir.list().toList();
      files.sort((a, b) {
        if (a is File && b is File) {
          return a.lastModifiedSync().compareTo(b.lastModifiedSync());
        }
        return 0;
      });
      
      // Calculate cutoff date for automatic deletion
      final cutoffDate = DateTime.now().subtract(Duration(days: cacheDurationDays));
      
      // Delete oldest files first until we're under the threshold
      var currentCacheSize = currentSize;
      for (var entity in files) {
        if (entity is File) {
          final lastModified = entity.lastModifiedSync();
          
          // Delete if older than cache duration or if we need to reduce cache size
          if (lastModified.isBefore(cutoffDate) || currentCacheSize > maxSize) {
            final fileSize = await entity.length();
            await entity.delete();
            currentCacheSize -= fileSize;
          }
          
          // Break if we're under the threshold
          if (currentCacheSize < maxSize * 0.8) break;
        }
      }
      
      // Update cache size
      _updateCacheSize();
    } catch (e) {
      debugPrint('Cache cleanup error: $e');
    }
  }
  
  /// Clears temporary files
  Future<void> clearTempFiles() async {
    if (kIsWeb) return;
    try {
      final tempDir = Directory(_tempDirectory);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
      }
    } catch (e) {
      debugPrint('Clear temp files error: $e');
    }
  }
  
  /// Clears all cached and temporary files
  Future<void> clearAllCache() async {
    if (kIsWeb) return;
    try {
      await _cacheManager.emptyCache();
      await clearTempFiles();
      
      final cacheDir = Directory(_cacheDirectory);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      
      _updateCacheSize();
    } catch (e) {
      debugPrint('Clear all cache error: $e');
    }
  }
  
  /// Updates the current cache size
  Future<void> _updateCacheSize() async {
    if (kIsWeb) {
      _cacheSizeSubject.add(0);
      return;
    }
    try {
      final cacheDir = Directory(_cacheDirectory);
      if (await cacheDir.exists()) {
        final size = await _calculateDirectorySize(cacheDir);
        _cacheSizeSubject.add(size / (1024 * 1024)); // Convert to MB
      } else {
        _cacheSizeSubject.add(0);
      }
    } catch (e) {
      debugPrint('Update cache size error: $e');
    }
  }
  
  /// Calculates the size of a directory in bytes
  Future<int> _calculateDirectorySize(Directory directory) async {
    if (kIsWeb) return 0;
    int totalSize = 0;
    try {
      final files = directory.listSync(recursive: true, followLinks: false);
      for (var entity in files) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('Calculate directory size error: $e');
    }
    return totalSize;
  }
  
  /// Schedules periodic cache cleanup
  void _scheduleCacheCleanup() {
    if (kIsWeb) return;
    // Run cache cleanup every 24 hours
    Timer.periodic(const Duration(hours: 24), (timer) {
      cleanupCache();
    });
  }
  
  /// Disposes resources
  void dispose() {
    _cacheSizeSubject.close();
  }
} 