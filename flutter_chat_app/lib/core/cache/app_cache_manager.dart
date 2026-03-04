import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_chat_app/core/cache/cache_stats.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  static const String keyPrefix = 'chat_app_cache_';
  static const Duration defaultCacheDuration = Duration(days: 7);
  static const Duration chatListTtl = Duration(minutes: 30);
  static const Duration messageTtl = Duration(days: 30);
  static const Duration userDataTtl = Duration(days: 14);
  static const Duration mediaThumbnailTtl = Duration(days: 30);
  static const int maxCacheSizeMb = 200; // 200MB max cache

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

  /// Trạng thái khởi tạo
  bool _isInitialized = false;

  /// Kiểm tra đã khởi tạo chưa
  bool get isInitialized => _isInitialized;

  /// Private constructor
  AppCacheManager._internal();

  /// Khởi tạo cache manager
  Future<void> initialize() async {
    _logger.i('Khởi tạo AppCacheManager');

    // Khởi tạo SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Khởi tạo Hive
    if (kIsWeb) {
      await Hive.initFlutter();
      _apiCacheBox = await Hive.openBox<String>('${keyPrefix}api_cache');
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveCacheDir = Directory('${appDir.path}/hive_cache');
      if (!await hiveCacheDir.exists()) {
        await hiveCacheDir.create(recursive: true);
      }

      // Đăng ký Hive adapters
      Hive.init(hiveCacheDir.path);
      _apiCacheBox = await Hive.openBox<String>('${keyPrefix}api_cache');
    }

    // Khởi tạo cache managers với config phù hợp
    _defaultCacheManager = CacheManager(
      _buildCacheConfig(
        cacheKey: '${keyPrefix}default_cache',
        stalePeriod: defaultCacheDuration,
        maxNrOfCacheObjects: 200,
        databaseName: '${keyPrefix}default_cache_db',
      ),
    );

    _mediaCacheManager = CacheManager(
      _buildCacheConfig(
        cacheKey: '${keyPrefix}media_cache',
        stalePeriod: defaultCacheDuration,
        maxNrOfCacheObjects: 100,
        databaseName: '${keyPrefix}media_cache_db',
      ),
    );

    _thumbnailCacheManager = CacheManager(
      _buildCacheConfig(
        cacheKey: '${keyPrefix}thumbnail_cache',
        stalePeriod: mediaThumbnailTtl,
        maxNrOfCacheObjects: 300,
        databaseName: '${keyPrefix}thumbnail_cache_db',
      ),
    );

    _isInitialized = true;
    _logger.i('AppCacheManager đã được khởi tạo');
  }

  Config _buildCacheConfig({
    required String cacheKey,
    required Duration stalePeriod,
    required int maxNrOfCacheObjects,
    required String databaseName,
  }) {
    if (kIsWeb) {
      // On web, default Config uses NonStoringObjectProvider and avoids
      // path_provider calls such as getApplicationSupportDirectory.
      return Config(
        cacheKey,
        stalePeriod: stalePeriod,
        maxNrOfCacheObjects: maxNrOfCacheObjects,
        fileService: HttpFileService(),
      );
    }

    return Config(
      cacheKey,
      stalePeriod: stalePeriod,
      maxNrOfCacheObjects: maxNrOfCacheObjects,
      repo: JsonCacheInfoRepository(databaseName: databaseName),
      fileService: HttpFileService(),
    );
  }

  /// Phương thức cho cache API responses
  Future<void> cacheApiResponse<T>(String key, T data, {Duration? ttl}) async {
    final expiry = DateTime.now().add(ttl ?? defaultCacheDuration);

    // Cache in memory
    _memoryCache[key] = _CacheEntry<T>(data, expiry);

    // Cache to disk
    try {
      final jsonData = jsonEncode(_toEncodable(data));
      await _apiCacheBox.put(key, jsonData);
      await _prefs.setInt('${key}_expiry', expiry.millisecondsSinceEpoch);
      // _logger.t('Đã cache API response: $key');
    } catch (e) {
      _logger.e('Lỗi khi cache API response: $e');
    }
  }

  dynamic _toEncodable(dynamic value) {
    if (value == null) return null;

    if (value is num || value is String || value is bool) {
      return value;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toEncodable(v)));
    }

    if (value is List) {
      return value.map(_toEncodable).toList();
    }

    // Common patterns in this codebase
    try {
      final dynamic asDynamic = value;
      final dynamic mapped = asDynamic.toMap?.call();
      if (mapped != null) return _toEncodable(mapped);
    } catch (_) {}

    try {
      final dynamic asDynamic = value;
      final dynamic json = asDynamic.toJson?.call();
      if (json != null) return _toEncodable(json);
    } catch (_) {}

    // Fallback to string to avoid crashing caching
    return value.toString();
  }

  /// Lấy API response đã cache
  Future<T?> getApiResponse<T>(
    String key, {
    Duration? ttl,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(List<dynamic>)? fromJsonList,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    bool isHit = false;

    try {
      // Kiểm tra memory cache trước
      if (_memoryCache.containsKey(key)) {
        final cacheEntry = _memoryCache[key]!;
        if (cacheEntry.expiry.isAfter(DateTime.now())) {
          _logger.t('Lấy API response từ memory cache: $key');
          isHit = true;
          await _updateAccessStats(key, true);
          final dynamic raw = cacheEntry.data;

          // If already parsed to the correct type, return directly
          if (raw is T) {
            return raw;
          }

          if (fromJson != null && raw is Map) {
            final result =
                fromJson(raw.map((k, v) => MapEntry(k.toString(), v)));
            _memoryCache[key] = _CacheEntry<T>(result, cacheEntry.expiry);
            return result;
          }

          if (fromJsonList != null && raw is List) {
            final result = fromJsonList(raw);
            _memoryCache[key] = _CacheEntry<T>(result, cacheEntry.expiry);
            return result;
          }

          return raw as T;
        } else {
          // Xóa cache đã hết hạn
          _memoryCache.remove(key);
        }
      }

      // Kiểm tra disk cache
      if (_apiCacheBox.containsKey(key)) {
        final expiryTimestamp = _prefs.getInt('${key}_expiry');
        if (expiryTimestamp != null) {
          final expiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
          if (expiry.isAfter(DateTime.now())) {
            try {
              final jsonString = _apiCacheBox.get(key);
              if (jsonString != null) {
                final dynamic decoded = jsonDecode(jsonString);

                if (fromJson != null && decoded is Map<String, dynamic>) {
                  _logger.t('Lấy API response từ disk cache: $key (Object)');
                  final result = fromJson(decoded);
                  // Lưu vào memory cache
                  _memoryCache[key] = _CacheEntry<T>(result, expiry);
                  isHit = true;
                  await _updateAccessStats(key, true);
                  _preloadRelatedData(key, decoded);
                  return result;
                } else if (fromJsonList != null && decoded is List<dynamic>) {
                  _logger.t('Lấy API response từ disk cache: $key (List)');
                  final result = fromJsonList(decoded);
                  // Lưu vào memory cache
                  _memoryCache[key] = _CacheEntry<T>(result, expiry);
                  isHit = true;
                  await _updateAccessStats(key, true);
                  _preloadRelatedData(key, decoded);
                  return result;
                } else {
                  _logger.t('Lấy API response từ disk cache: $key (Raw)');
                  final result = decoded as T;
                  _memoryCache[key] = _CacheEntry<T>(result, expiry);
                  isHit = true;
                  await _updateAccessStats(key, true);
                  return result;
                }
              }
            } catch (e) {
              _logger.e('Lỗi khi đọc API response từ cache: $e');
            }
          } else {
            // Xóa cache đã hết hạn
            await _apiCacheBox.delete(key);
            await _prefs.remove('${key}_expiry');
            await _prefs.remove('${key}_last_access');
          }
        }
      }

      _logger.t('Cache miss: $key');
      await _updateAccessStats(key, false);
      return null;
    } finally {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;

      try {
        // Ghi lại thống kê hiệu suất nếu có CacheStats service
        final cacheStats =
            GetIt.I.isRegistered<CacheStats>() ? GetIt.I<CacheStats>() : null;
        if (cacheStats != null) {
          if (isHit) {
            cacheStats.recordApiHit(key, duration.toDouble());
          } else {
            cacheStats.recordApiMiss(key, duration.toDouble());
          }
        }
      } catch (e) {
        // Bỏ qua nếu không thể ghi thống kê
      }
    }
  }

  /// Cập nhật thống kê truy cập
  Future<void> _updateAccessStats(String key, bool isHit) async {
    try {
      // Tăng số lần truy cập
      final accessCount = _prefs.getInt('${key}_access_count') ?? 0;
      await _prefs.setInt('${key}_access_count', accessCount + 1);

      // Cập nhật thời gian truy cập gần nhất
      await _prefs.setInt(
          '${key}_last_access', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Bỏ qua nếu có lỗi khi cập nhật thống kê
    }
  }

  /// Tiền tải dữ liệu liên quan nếu có thể
  void _preloadRelatedData(String key, dynamic data) {
    // Trong ứng dụng thực, thực hiện tiền tải dữ liệu liên quan
    // Ví dụ: Nếu đây là một chat, có thể tiền tải avatar của người dùng
    // hoặc tin nhắn gần đây
  }

  /// Phương thức cho cache media
  Future<File> getMediaFile(String url, {bool thumbnail = false}) async {
    final cacheManager =
        thumbnail ? _thumbnailCacheManager : _mediaCacheManager;
    try {
      _logger.t('Lấy media file từ cache: $url');
      return await cacheManager.getSingleFile(url);
    } catch (e) {
      _logger.e('Lỗi khi lấy media file: $e');
      rethrow;
    }
  }

  /// Kiểm tra file có trong cache không
  Future<bool> isMediaCached(String url, {bool thumbnail = false}) async {
    final cacheManager =
        thumbnail ? _thumbnailCacheManager : _mediaCacheManager;
    final fileInfo = await cacheManager.getFileFromCache(url);
    return fileInfo != null;
  }

  /// Cache một file với URL
  Future<void> cacheFile(String url, Uint8List bytes,
      {bool thumbnail = false}) async {
    final cacheManager =
        thumbnail ? _thumbnailCacheManager : _mediaCacheManager;
    try {
      await cacheManager.putFile(
        url,
        bytes,
        maxAge: thumbnail ? mediaThumbnailTtl : defaultCacheDuration,
      );
      _logger.t('Đã cache file: $url');
    } catch (e) {
      _logger.e('Lỗi khi cache file: $e');
    }
  }

  /// Invalidate một cache entry
  Future<void> invalidateCache(String key) async {
    _memoryCache.remove(key);
    await _apiCacheBox.delete(key);
    await _prefs.remove('${key}_expiry');
    _logger.t('Đã invalidate cache: $key');
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

  /// Runs cache cleanup in the background (called after first frame).
  Future<void> deferredCleanup() async {
    if (!_isInitialized) return;
    await _cleanupCacheIfNeeded();
  }

  /// Kiểm tra và dọn dẹp cache nếu vượt quá kích thước cho phép
  Future<void> _cleanupCacheIfNeeded() async {
    final cacheSize = await _calculateTotalCacheSize();
    if (cacheSize > maxCacheSizeMb * 1024 * 1024) {
      _logger.i(
          'Cache vượt quá kích thước tối đa ($cacheSize bytes). Dọn dẹp cache...');
      await _removeOldestCache();
    }
  }

  /// Tính toán tổng size của cache
  Future<int> _calculateTotalCacheSize() async {
    int totalSize = 0;

    try {
      if (kIsWeb) {
        if (_apiCacheBox.isOpen) {
          for (final key in _apiCacheBox.keys) {
            final value = _apiCacheBox.get(key);
            if (value != null) {
              totalSize += value.length;
            }
          }
        }

        _logger.t(
            'Tổng kích thước cache: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)}MB');
        return totalSize;
      }

      // Tính kích thước của cache directories
      final tempDir = await getTemporaryDirectory();
      final cacheDirs = [
        Directory('${tempDir.path}/libCachedImageData'),
        Directory('${tempDir.path}/${keyPrefix}default_cache'),
        Directory('${tempDir.path}/${keyPrefix}media_cache'),
        Directory('${tempDir.path}/${keyPrefix}thumbnail_cache')
      ];

      final futures = <Future<int>>[];

      // Tính kích thước cho mỗi directory
      for (final dir in cacheDirs) {
        futures.add(_calculateDirectorySize(dir));
      }

      // Chờ tất cả tính toán hoàn tất và tổng hợp kết quả
      final sizes = await Future.wait(futures);
      totalSize = sizes.fold(0, (sum, size) => sum + size);

      // Ước tính kích thước của Hive và SharedPreferences cache
      if (_apiCacheBox.isOpen) {
        // Sử dụng độ dài thực tế của các giá trị thay vì ước tính
        for (final key in _apiCacheBox.keys) {
          final value = _apiCacheBox.get(key);
          if (value != null) {
            totalSize += value.length;
          }
        }
      }

      _logger.t(
          'Tổng kích thước cache: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)}MB');
    } catch (e) {
      _logger.e('Lỗi khi tính toán kích thước cache: $e');
    }

    return totalSize;
  }

  /// Tính kích thước của một thư mục
  Future<int> _calculateDirectorySize(Directory directory) async {
    int size = 0;

    if (!await directory.exists()) {
      return 0;
    }

    try {
      await for (final entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final fileSize = await entity.length();
          size += fileSize;
        }
      }
    } catch (e) {
      _logger.w('Lỗi khi tính kích thước thư mục ${directory.path}: $e');
    }

    return size;
  }

  /// Xóa cache cũ nhất theo chiến lược LRU
  Future<void> _removeOldestCache() async {
    _logger.i('Bắt đầu dọn dẹp cache theo chiến lược LRU');

    try {
      // Lấy thông tin về kích thước hiện tại
      final currentSize = await _calculateTotalCacheSize();
      final targetSize = (maxCacheSizeMb * 0.7 * 1024 * 1024)
          .toInt(); // Mục tiêu giảm xuống 70% kích thước tối đa

      _logger.i(
          'Kích thước hiện tại: ${(currentSize / (1024 * 1024)).toStringAsFixed(2)}MB, '
          'mục tiêu: ${(targetSize / (1024 * 1024)).toStringAsFixed(2)}MB');

      // Xóa cache theo thứ tự ưu tiên

      // 1. Đầu tiên xóa cache media không quan trọng (giữ lại thumbnails)
      await _mediaCacheManager.emptyCache();
      int sizeAfterMedia = await _calculateTotalCacheSize();

      if (sizeAfterMedia <= targetSize) {
        _logger.i('Hoàn tất dọn dẹp sau khi xóa media cache');
        return;
      }

      // 2. Xóa bớt thumbnail cache nếu vẫn cần
      await _thumbnailCacheManager.emptyCache();
      int sizeAfterThumbnails = await _calculateTotalCacheSize();

      if (sizeAfterThumbnails <= targetSize) {
        _logger.i('Hoàn tất dọn dẹp sau khi xóa thumbnails');
        return;
      }

      // 3. Xóa API cache entry lâu nhất trong số các entry ít được truy cập
      final keys =
          _prefs.getKeys().where((k) => k.endsWith('_expiry')).toList();
      final entries = <String, _CacheEntryMetadata>{};

      // Thu thập metadata về các cache entry
      for (final key in keys) {
        final expiryTimestamp = _prefs.getInt(key);
        if (expiryTimestamp != null) {
          final cacheKey =
              key.substring(0, key.length - 7); // Loại bỏ '_expiry'
          final lastAccessTime =
              _prefs.getInt('${cacheKey}_last_access') ?? expiryTimestamp;

          entries[cacheKey] = _CacheEntryMetadata(
              key: cacheKey,
              expiryTime: expiryTimestamp,
              lastAccessTime: lastAccessTime,
              frequency: _prefs.getInt('${cacheKey}_access_count') ?? 0);
        }
      }

      if (entries.isNotEmpty) {
        // Sắp xếp theo thứ tự: Ít truy cập nhất -> Lâu nhất không được truy cập -> Gần hết hạn nhất
        final sortedEntries = entries.values.toList()
          ..sort((a, b) {
            // Đầu tiên sắp xếp theo tần suất truy cập
            final freqCompare = a.frequency.compareTo(b.frequency);
            if (freqCompare != 0) return freqCompare;

            // Sau đó theo thời gian truy cập gần đây nhất
            return a.lastAccessTime.compareTo(b.lastAccessTime);
          });

        // Xóa 40% cache entry ít được sử dụng nhất
        final entriesToRemove =
            sortedEntries.take((sortedEntries.length * 0.4).ceil());
        int removedCount = 0;

        for (final entry in entriesToRemove) {
          await _apiCacheBox.delete(entry.key);
          await _prefs.remove('${entry.key}_expiry');
          await _prefs.remove('${entry.key}_last_access');
          await _prefs.remove('${entry.key}_access_count');
          _memoryCache.remove(entry.key);
          removedCount++;

          // Kiểm tra xem đã đạt đủ kích thước mục tiêu chưa sau mỗi 10 entry
          if (removedCount % 10 == 0) {
            final currentSize = await _calculateTotalCacheSize();
            if (currentSize <= targetSize) {
              _logger.i(
                  'Hoàn tất dọn dẹp sau khi xóa $removedCount API cache entries');
              return;
            }
          }
        }

        _logger.i('Đã xóa $removedCount API cache entries');
      }

      // 4. Nếu vẫn cần, xóa tất cả cache
      if (await _calculateTotalCacheSize() > targetSize) {
        _logger.w(
            'Vẫn vượt quá kích thước mục tiêu sau khi áp dụng chiến lược LRU, xóa tất cả cache');
        await _defaultCacheManager.emptyCache();
        _memoryCache.clear();
        await _apiCacheBox.clear();
      }
    } catch (e) {
      _logger.e('Lỗi trong quá trình dọn dẹp cache: $e');
    }
  }

  /// Kiểm tra xem một key có trong cache không (cho debugging)
  bool isInMemoryCache(String key) => _memoryCache.containsKey(key);

  Future<bool> isInDiskCache(String key) async => _apiCacheBox.containsKey(key);

  /// Lấy tất cả cache key
  Future<List<String>> getAllCacheKeys() async {
    if (!_isInitialized) {
      _logger.w('Không thể lấy cache keys: AppCacheManager chưa được khởi tạo');
      return [];
    }

    final List<String> keys = [];

    // Lấy keys từ memory cache
    keys.addAll(_memoryCache.keys);

    // Lấy keys từ disk cache (Hive)
    if (_apiCacheBox.isOpen) {
      keys.addAll(_apiCacheBox.keys.map((dynamic key) => key.toString()));
    }

    return keys;
  }
}

/// Class lưu trữ cache entry với dữ liệu và thời gian hết hạn
class _CacheEntry<T> {
  final T data;
  final DateTime expiry;

  _CacheEntry(this.data, this.expiry);
}

/// Class metadata cho cache entry
class _CacheEntryMetadata {
  final String key;
  final int expiryTime;
  final int lastAccessTime;
  final int frequency;

  _CacheEntryMetadata(
      {required this.key,
      required this.expiryTime,
      required this.lastAccessTime,
      required this.frequency});
}
