import 'dart:io';
import 'dart:typed_data';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/core/utils/isolate_manager.dart';

/// Lớp quản lý cache cho media
@singleton
class MediaCache {
  /// Kích thước tối đa cho cache bộ nhớ (10MB)
  static const int _maxMemoryCacheSize = 10 * 1024 * 1024;
  
  /// Kích thước tối đa cho cache đĩa (100MB)
  static const int _maxDiskCacheSize = 100 * 1024 * 1024;
  
  /// Thời gian hết hạn mặc định (7 ngày)
  static const Duration _defaultExpiration = Duration(days: 7);
  
  /// Manager cho cache đĩa
  final BaseCacheManager _diskCache;
  
  /// Cache bộ nhớ cho media nhỏ
  final Map<String, Uint8List> _memoryCache = LinkedHashMap();
  
  /// Performance monitor
  final PerformanceMonitor _performanceMonitor;
  
  /// Isolate manager
  final IsolateManager _isolateManager;
  
  /// Thư mục cache
  final String _cacheDirectory;
  
  /// Constructor
  MediaCache._(
    this._diskCache,
    this._performanceMonitor,
    this._isolateManager,
    this._cacheDirectory,
  );
  
  /// Factory method để tạo instance
  @factoryMethod
  static Future<MediaCache> create(
    PerformanceMonitor performanceMonitor,
    IsolateManager isolateManager,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = '${appDir.path}/media_cache';
    
    // Đảm bảo thư mục cache tồn tại
    await Directory(cacheDir).create(recursive: true);
    
    // Tạo cache manager tùy chỉnh
    final cacheManager = CacheManager(
      Config(
        'mediaCache',
        stalePeriod: _defaultExpiration,
        maxNrOfCacheObjects: 100,
        repo: JsonCacheInfoRepository(databaseName: 'mediaCache'),
        fileService: HttpFileService(),
      ),
    );
    
    return MediaCache._(
      cacheManager,
      performanceMonitor,
      isolateManager,
      cacheDir,
    );
  }
  
  /// Lấy file từ cache hoặc tải xuống nếu chưa có
  Future<File?> getFile(String url, {
    String? key,
    bool useIsolate = true,
    void Function(double progress)? onProgress,
  }) async {
    final cacheKey = key ?? url;
    _performanceMonitor.startTrace(TraceType.loadMessages);
    
    try {
      // Kiểm tra trong memory cache trước
      if (_memoryCache.containsKey(cacheKey)) {
        _addMetricToPerformanceMonitor('memory_hit_count', 1);
        
        // Lưu vào file tạm để trả về
        final tempFile = await _createTempFileFromBytes(
          _memoryCache[cacheKey]!,
          cacheKey,
        );
        
        _performanceMonitor.stopTrace(TraceType.loadMessages);
        return tempFile;
      }
      
      // Kiểm tra trong disk cache
      try {
        final fileInfo = await _diskCache.getFileFromCache(cacheKey);
        if (fileInfo != null) {
          _addMetricToPerformanceMonitor('disk_hit_count', 1);
          
          // Nếu file nhỏ, lưu vào memory cache
          if (fileInfo.file.lengthSync() < _maxMemoryCacheSize / 10) {
            final bytes = await fileInfo.file.readAsBytes();
            _addToMemoryCache(cacheKey, bytes);
          }
          
          _performanceMonitor.stopTrace(TraceType.loadMessages);
          return fileInfo.file;
        }
      } catch (e) {
        debugPrint('Error getting file from disk cache: $e');
      }
      
      // Tải file từ network
      _addMetricToPerformanceMonitor('network_fetch_count', 1);
      
      if (useIsolate) {
        // Tải trong isolate để không chặn main thread
        final result = await _isolateManager.processInBackground(
          taskType: IsolateTaskType.fileOperation,
          data: {
            'url': url,
            'key': cacheKey,
          },
          params: {
            'operation': 'download',
            'cacheDir': _cacheDirectory,
          },
        );
        
        if (result.isSuccess && result.result != null) {
          final filePath = result.result['path'] as String;
          final file = File(filePath);
          
          // Nếu file nhỏ, lưu vào memory cache
          if (file.lengthSync() < _maxMemoryCacheSize / 10) {
            final bytes = await file.readAsBytes();
            _addToMemoryCache(cacheKey, bytes);
          }
          
          _performanceMonitor.stopTrace(TraceType.loadMessages);
          return file;
        }
      } else {
        // Tải trực tiếp trên main thread
        final fileStream = _diskCache.getFileStream(
          url,
          key: cacheKey,
          withProgress: true,
        );
        
        File? resultFile;
        await for (final result in fileStream) {
          if (result is DownloadProgress && onProgress != null) {
            onProgress(result.progress ?? 0);
          }
          
          if (result is FileInfo) {
            resultFile = result.file;
            
            // Nếu file nhỏ, lưu vào memory cache
            if (resultFile.lengthSync() < _maxMemoryCacheSize / 10) {
              final bytes = await resultFile.readAsBytes();
              _addToMemoryCache(cacheKey, bytes);
            }
            break;
          }
        }
        
        _performanceMonitor.stopTrace(TraceType.loadMessages);
        return resultFile;
      }
      
      _performanceMonitor.stopTrace(TraceType.loadMessages);
      return null;
    } catch (e) {
      _performanceMonitor.stopTrace(TraceType.loadMessages);
      debugPrint('Error in getFile: $e');
      return null;
    }
  }
  
  /// Thêm metric vào performance monitor
  void _addMetricToPerformanceMonitor(String name, int value) {
    try {
      _performanceMonitor.addTraceMetric(
        TraceType.loadMessages,
        metricName: name, 
        value: value
      );
    } catch (e) {
      // Ignore errors in performance monitoring
      debugPrint('Error adding metric: $e');
    }
  }
  
  /// Lấy bytes từ cache hoặc tải xuống nếu chưa có
  Future<Uint8List?> getBytes(String url, {String? key}) async {
    final cacheKey = key ?? url;
    _performanceMonitor.startTrace(TraceType.loadMessages);
    
    try {
      // Kiểm tra trong memory cache trước
      if (_memoryCache.containsKey(cacheKey)) {
        _addMetricToPerformanceMonitor('memory_hit_count', 1);
        
        final bytes = _memoryCache[cacheKey]!;
        _performanceMonitor.stopTrace(TraceType.loadMessages);
        return bytes;
      }
      
      // Không tìm thấy trong memory cache, lấy file từ disk cache
      final file = await getFile(url, key: cacheKey, useIsolate: false);
      if (file != null) {
        final bytes = await file.readAsBytes();
        
        // Lưu vào memory cache nếu đủ nhỏ
        if (bytes.length < _maxMemoryCacheSize / 10) {
          _addToMemoryCache(cacheKey, bytes);
        }
        
        _performanceMonitor.stopTrace(TraceType.loadMessages);
        return bytes;
      }
      
      _performanceMonitor.stopTrace(TraceType.loadMessages);
      return null;
    } catch (e) {
      _performanceMonitor.stopTrace(TraceType.loadMessages);
      debugPrint('Error in getBytes: $e');
      return null;
    }
  }
  
  /// Thêm file vào cache
  Future<void> putFile(String key, File file) async {
    try {
      // Đọc file thành bytes để truyền vào putFile
      final bytes = await file.readAsBytes();
      await _diskCache.putFile(key, bytes);
      
      // Lưu vào memory cache nếu đủ nhỏ
      if (file.lengthSync() < _maxMemoryCacheSize / 10) {
        _addToMemoryCache(key, bytes);
      }
    } catch (e) {
      debugPrint('Error putting file to cache: $e');
    }
  }
  
  /// Thêm bytes vào cache
  Future<void> putBytes(String key, Uint8List bytes) async {
    try {
      // Lưu vào memory cache nếu đủ nhỏ
      if (bytes.length < _maxMemoryCacheSize / 10) {
        _addToMemoryCache(key, bytes);
      }
      
      // Lưu vào disk cache
      final temp = await _createTempFileFromBytes(bytes, key);
      // Đọc nội dung file thành bytes trước khi truyền
      final tempBytes = await temp.readAsBytes();
      await _diskCache.putFile(key, tempBytes);
    } catch (e) {
      debugPrint('Error putting bytes to cache: $e');
    }
  }
  
  /// Nén ảnh trước khi lưu
  Future<File?> compressImage(File file, {int quality = 80}) async {
    _performanceMonitor.startTrace(TraceType.sendMessage);
    
    try {
      // Xử lý trong isolate để không chặn main thread
      final result = await _isolateManager.processInBackground(
        taskType: IsolateTaskType.imageProcessing,
        data: {
          'path': file.path,
          'size': file.lengthSync(),
        },
        params: {
          'quality': quality,
          'cacheDir': _cacheDirectory,
        },
      );
      
      if (result.isSuccess && result.result != null) {
        final newPath = result.result['path'] as String?;
        
        _performanceMonitor.stopTrace(TraceType.sendMessage);
        
        if (newPath != null) {
          return File(newPath);
        }
      }
      
      // Nếu xử lý bằng isolate thất bại, thử xử lý trực tiếp
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${const Uuid().v4()}.jpg';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1024,
        minHeight: 1024,
      );
      
      _performanceMonitor.stopTrace(TraceType.sendMessage);
      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      _performanceMonitor.stopTrace(TraceType.sendMessage);
      debugPrint('Error compressing image: $e');
      return null;
    }
  }
  
  /// Xóa một item khỏi cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _diskCache.removeFile(key);
  }
  
  /// Xóa tất cả cache
  Future<void> clear() async {
    _memoryCache.clear();
    await _diskCache.emptyCache();
  }
  
  /// Xóa các file cache cũ
  Future<void> clearStale() async {
    await _diskCache.emptyCache();
  }
  
  /// Kiểm tra xem cache có chứa key không
  Future<bool> contains(String key) async {
    if (_memoryCache.containsKey(key)) {
      return true;
    }
    
    final fileInfo = await _diskCache.getFileFromCache(key);
    return fileInfo != null;
  }
  
  /// Thêm dữ liệu vào memory cache
  void _addToMemoryCache(String key, Uint8List bytes) {
    // Kiểm tra kích thước hiện tại của cache
    int currentSize = _calculateMemoryCacheSize();
    
    // Nếu thêm item mới sẽ vượt quá giới hạn, xóa bớt các item cũ
    while (currentSize + bytes.length > _maxMemoryCacheSize && _memoryCache.isNotEmpty) {
      final oldestKey = _memoryCache.keys.first;
      final removedSize = _memoryCache[oldestKey]!.length;
      _memoryCache.remove(oldestKey);
      currentSize -= removedSize;
    }
    
    // Thêm item mới vào cache
    _memoryCache[key] = bytes;
  }
  
  /// Tính kích thước hiện tại của memory cache
  int _calculateMemoryCacheSize() {
    int size = 0;
    for (final bytes in _memoryCache.values) {
      size += bytes.length;
    }
    return size;
  }
  
  /// Tạo file tạm từ bytes
  Future<File> _createTempFileFromBytes(Uint8List bytes, String key) async {
    final tempDir = await getTemporaryDirectory();
    
    // Xác định phần mở rộng từ key hoặc mặc định
    String ext = '.dat';
    final mimeType = lookupMimeType(key);
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) {
        ext = mimeType.contains('png') ? '.png' : '.jpg';
      } else if (mimeType.startsWith('video/')) {
        ext = '.mp4';
      } else if (mimeType.startsWith('audio/')) {
        ext = '.mp3';
      }
    }
    
    final tempFile = File('${tempDir.path}/${const Uuid().v4()}$ext');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }
  
  /// Lấy instance từ service locator
  static MediaCache get instance => GetIt.I<MediaCache>();
} 