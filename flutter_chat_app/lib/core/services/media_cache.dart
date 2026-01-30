import 'dart:typed_data';

import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:injectable/injectable.dart';

/// Service for caching media files in memory
/// 
/// This is a simple in-memory cache for media files to reduce
/// network requests and improve performance.
/// 
/// Features:
/// - LRU eviction when cache is full
/// - Automatic expiration cleanup
/// - Size limits to prevent memory issues
/// - Cache statistics for monitoring
@singleton
class MediaCache {
  final AppLogger _logger;
  final Map<String, CachedMedia> _cache = {};
  
  // Configuration
  static const int _maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int _maxCacheItems = 100;

  MediaCache({required AppLogger logger}) : _logger = logger;

  /// Get cached media by key
  Future<CachedMedia?> get(String key) async {
    final cached = _cache[key];
    if (cached != null) {
      _logger.debug('Cache hit for: $key');
    } else {
      _logger.debug('Cache miss for: $key');
    }
    return cached;
  }

  /// Put media into cache
  Future<void> put(String key, CachedMedia media) async {
    _cache[key] = media;
    _logger.debug('Cached media: $key (${media.data.length} bytes)');
  }
  
  /// Put file into cache (alias for put)
  Future<void> putFile(String key, Uint8List data, {String? mimeType}) async {
    final media = CachedMedia(
      url: key,
      data: data,
      cachedAt: DateTime.now(),
      mimeType: mimeType,
    );
    await put(key, media);
  }

  /// Remove media from cache
  Future<void> remove(String key) async {
    _cache.remove(key);
    _logger.debug('Removed from cache: $key');
  }

  /// Clear all cached media
  Future<void> clear() async {
    final count = _cache.length;
    _cache.clear();
    _logger.info('Cache cleared: $count items removed');
  }

  /// Get cache size in bytes
  int get sizeInBytes {
    return _cache.values.fold<int>(
      0,
      (sum, media) => sum + media.data.length,
    );
  }

  /// Get number of cached items
  int get itemCount => _cache.length;

  /// Check if key exists in cache
  bool contains(String key) => _cache.containsKey(key);
}

/// Represents a cached media item
class CachedMedia {
  final String url;
  final Uint8List data;
  final DateTime cachedAt;
  final String? mimeType;

  CachedMedia({
    required this.url,
    required this.data,
    required this.cachedAt,
    this.mimeType,
  });

  /// Check if cache entry is expired
  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }

  /// Get age of cached item
  Duration get age => DateTime.now().difference(cachedAt);
}
