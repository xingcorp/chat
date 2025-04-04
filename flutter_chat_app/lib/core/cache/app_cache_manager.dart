import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manager lưu trữ và quản lý cache của ứng dụng
class AppCacheManager {
  /// Singleton instance
  static final AppCacheManager _instance = AppCacheManager._internal();
  
  /// Factory constructor
  factory AppCacheManager() => _instance;
  
  /// Logger
  final _logger = Logger();
  
  /// Cache configuration
  static const String KEY_PREFIX = 'chat_app_cache_';
  static const Duration DEFAULT_CACHE_DURATION = Duration(days: 7);
  static const Duration CHAT_LIST_TTL = Duration(minutes: 30);
  static const Duration MESSAGE_TTL = Duration(days: 30);
  static const Duration USER_DATA_TTL = Duration(days: 14);
  static const Duration MEDIA_THUMBNAIL_TTL = Duration(days: 30);
  static const int MAX_CACHE_SIZE_MB = 200; // 200MB max cache
  
  /// Cache managers
  late CacheManager _defaultCacheManager;
  late CacheManager _mediaCacheManager;
  late CacheManager _thumbnailCacheManager;
  
  /// Memory cache cho API responses
  final Map<String, _CacheEntry<dynamic>> _memoryCache = {};
  
  /// Shared Preferences để lưu cache metadata
  late SharedPreferences _prefs;
  
  /// Hive box cho api cache
  late Box<String> _apiCacheBox;
  
  /// Private constructor
  AppCacheManager._internal();
  
  /// Khởi tạo cache manager
  Future<void> initialize() async {
    _logger.i('Khởi tạo AppCacheManager');
    
    // Khởi tạo SharedPreferences
    _prefs = await SharedPreferences.getInstance();
    
    // Khởi tạo Hive
    final appDir = await getApplicationDocumentsDirectory();
    final hiveCacheDir = Directory('${appDir.path}/hive_cache');
    if (!await hiveCacheDir.exists()) {
      await hiveCacheDir.create(recursive: true);
    }
    
    // Đăng ký Hive adapters
    Hive.init(hiveCacheDir.path);
    _apiCacheBox = await Hive.openBox<String>('${KEY_PREFIX}api_cache');
    
    // Khởi tạo cache managers với config phù hợp
    _defaultCacheManager = CacheManager(
      Config(
        '${KEY_PREFIX}default_cache',
        stalePeriod: DEFAULT_CACHE_DURATION,
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: '${KEY_PREFIX}default_cache_db'),
        fileService: HttpFileService(),
      ),
    );
    
    _mediaCacheManager = CacheManager(
      Config(
        '${KEY_PREFIX}media_cache',
        stalePeriod: DEFAULT_CACHE_DURATION,
        maxNrOfCacheObjects: 100,
        repo: JsonCacheInfoRepository(databaseName: '${KEY_PREFIX}media_cache_db'),
        fileService: HttpFileService(),
      ),
    );
    
    _thumbnailCacheManager = CacheManager(
      Config(
        '${KEY_PREFIX}thumbnail_cache',
        stalePeriod: MEDIA_THUMBNAIL_TTL,
        maxNrOfCacheObjects: 300,
        repo: JsonCacheInfoRepository(databaseName: '${KEY_PREFIX}thumbnail_cache_db'),
        fileService: HttpFileService(),
      ),
    );
    
    await _cleanupCacheIfNeeded();
    
    _logger.i('AppCacheManager đã được khởi tạo');
  }
  
  /// Phương thức cho cache API responses
  Future<void> cacheApiResponse<T>(String key, T data, {Duration? ttl}) async {
    final expiry = DateTime.now().add(ttl ?? DEFAULT_CACHE_DURATION);
    
    // Cache in memory
    _memoryCache[key] = _CacheEntry<T>(data, expiry);
    
    // Cache to disk
    try {
      final jsonData = jsonEncode(data);
      await _apiCacheBox.put(key, jsonData);
      await _prefs.setInt('${key}_expiry', expiry.millisecondsSinceEpoch);
      _logger.v('Đã cache API response: $key');
    } catch (e) {
      _logger.e('Lỗi khi cache API response: $e');
    }
  }
  
  /// Lấy API response đã cache
  Future<T?> getApiResponse<T>(String key, {
    Duration? ttl,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(List<dynamic>)? fromJsonList,
  }) async {
    // Kiểm tra memory cache trước
    if (_memoryCache.containsKey(key)) {
      final cacheEntry = _memoryCache[key]!;
      if (cacheEntry.expiry.isAfter(DateTime.now())) {
        _logger.v('Lấy API response từ memory cache: $key');
        return cacheEntry.data as T;
      } else {
        // Xóa cache đã hết hạn
        _memoryCache.remove(key);
      }
    }
    
    // Kiểm tra disk cache
    if (await _apiCacheBox.containsKey(key)) {
      final expiryTimestamp = _prefs.getInt('${key}_expiry');
      if (expiryTimestamp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
        if (expiry.isAfter(DateTime.now())) {
          try {
            final jsonString = _apiCacheBox.get(key);
            if (jsonString != null) {
              final dynamic decoded = jsonDecode(jsonString);
              
              if (fromJson != null && decoded is Map<String, dynamic>) {
                _logger.v('Lấy API response từ disk cache: $key (Object)');
                final result = fromJson(decoded);
                // Lưu vào memory cache
                _memoryCache[key] = _CacheEntry<T>(result, expiry);
                return result;
              } else if (fromJsonList != null && decoded is List<dynamic>) {
                _logger.v('Lấy API response từ disk cache: $key (List)');
                final result = fromJsonList(decoded);
                // Lưu vào memory cache
                _memoryCache[key] = _CacheEntry<T>(result, expiry);
                return result;
              } else {
                _logger.v('Lấy API response từ disk cache: $key (Raw)');
                return decoded as T;
              }
            }
          } catch (e) {
            _logger.e('Lỗi khi đọc API response từ cache: $e');
          }
        } else {
          // Xóa cache đã hết hạn
          await _apiCacheBox.delete(key);
          await _prefs.remove('${key}_expiry');
        }
      }
    }
    
    _logger.v('Cache miss: $key');
    return null;
  }
  
  /// Phương thức cho cache media
  Future<File> getMediaFile(String url, {bool thumbnail = false}) async {
    final cacheManager = thumbnail ? _thumbnailCacheManager : _mediaCacheManager;
    try {
      _logger.v('Lấy media file từ cache: $url');
      return await cacheManager.getSingleFile(url);
    } catch (e) {
      _logger.e('Lỗi khi lấy media file: $e');
      rethrow;
    }
  }
  
  /// Kiểm tra file có trong cache không
  Future<bool> isMediaCached(String url, {bool thumbnail = false}) async {
    final cacheManager = thumbnail ? _thumbnailCacheManager : _mediaCacheManager;
    final fileInfo = await cacheManager.getFileFromCache(url);
    return fileInfo != null;
  }
  
  /// Cache một file với URL
  Future<void> cacheFile(String url, Uint8List bytes, {bool thumbnail = false}) async {
    final cacheManager = thumbnail ? _thumbnailCacheManager : _mediaCacheManager;
    try {
      await cacheManager.putFile(
        url,
        bytes,
        maxAge: thumbnail ? MEDIA_THUMBNAIL_TTL : DEFAULT_CACHE_DURATION,
      );
      _logger.v('Đã cache file: $url');
    } catch (e) {
      _logger.e('Lỗi khi cache file: $e');
    }
  }
  
  /// Invalidate một cache entry
  Future<void> invalidateCache(String key) async {
    _memoryCache.remove(key);
    await _apiCacheBox.delete(key);
    await _prefs.remove('${key}_expiry');
    _logger.v('Đã invalidate cache: $key');
  }
  
  /// Xóa toàn bộ cache
  Future<void> clearAllCache() async {
    _logger.i('Xóa toàn bộ cache');
    _memoryCache.clear();
    await _apiCacheBox.clear();
    
    // Xóa tất cả cache entries
    final keys = _prefs.getKeys().where((k) => k.endsWith('_expiry')).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
    
    await _defaultCacheManager.emptyCache();
    await _mediaCacheManager.emptyCache();
    await _thumbnailCacheManager.emptyCache();
  }
  
  /// Kiểm tra và dọn dẹp cache nếu vượt quá kích thước cho phép
  Future<void> _cleanupCacheIfNeeded() async {
    final cacheSize = await _calculateTotalCacheSize();
    if (cacheSize > MAX_CACHE_SIZE_MB * 1024 * 1024) {
      _logger.i('Cache vượt quá kích thước tối đa ($cacheSize bytes). Dọn dẹp cache...');
      await _removeOldestCache();
    }
  }
  
  /// Tính toán tổng size của cache
  Future<int> _calculateTotalCacheSize() async {
    int totalSize = 0;
    
    // Tính kích thước của cache directories
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/libCachedImageData');
    
    if (await cacheDir.exists()) {
      await for (final file in cacheDir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          final size = await file.length();
          totalSize += size;
        }
      }
    }
    
    // Ước tính kích thước của Hive và SharedPreferences cache
    totalSize += await _apiCacheBox.length * 1000; // Ước tính trung bình 1KB mỗi entry
    
    return totalSize;
  }
  
  /// Xóa cache cũ nhất theo chiến lược LRU
  Future<void> _removeOldestCache() async {
    // Xóa các file cũ nhất từ các cache managers
    await _defaultCacheManager.emptyCache();
    await _mediaCacheManager.emptyCache();
    
    // Giữ lại thumbnails vì chúng nhỏ và hữu ích
    
    // Xóa 50% API cache entries cũ nhất
    final keys = _prefs.getKeys().where((k) => k.endsWith('_expiry')).toList();
    final entries = <String, int>{};
    
    for (final key in keys) {
      final expiryTimestamp = _prefs.getInt(key);
      if (expiryTimestamp != null) {
        final cacheKey = key.substring(0, key.length - 7); // Loại bỏ '_expiry'
        entries[cacheKey] = expiryTimestamp;
      }
    }
    
    // Sắp xếp theo thời gian tạo (hoặc hết hạn)
    final sortedEntries = entries.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Xóa 50% entries cũ nhất
    final entriesToRemove = sortedEntries.take(sortedEntries.length ~/ 2);
    for (final entry in entriesToRemove) {
      await _apiCacheBox.delete(entry.key);
      await _prefs.remove('${entry.key}_expiry');
      _memoryCache.remove(entry.key);
    }
    
    _logger.i('Đã xóa ${entriesToRemove.length} cache entries cũ');
  }
  
  /// Kiểm tra xem một key có trong cache không (cho debugging)
  bool isInMemoryCache(String key) => _memoryCache.containsKey(key);
  
  Future<bool> isInDiskCache(String key) async => await _apiCacheBox.containsKey(key);
}

/// Class lưu trữ cache entry với dữ liệu và thời gian hết hạn
class _CacheEntry<T> {
  final T data;
  final DateTime expiry;
  
  _CacheEntry(this.data, this.expiry);
} 