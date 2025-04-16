import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:get_it/get_it.dart';

import 'app_cache_manager.dart';
import '../utils/isolate_manager.dart';
import '../utils/device_performance_tier.dart';

/// Manager quản lý cache cho file media (hình ảnh, video...)
class MediaCacheManager {
  /// Singleton instance
  static final MediaCacheManager _instance = MediaCacheManager._internal();
  
  /// Factory constructor
  factory MediaCacheManager() => _instance;
  
  /// Logger
  final _logger = Logger();
  
  /// AppCacheManager instance
  final AppCacheManager _cacheManager = AppCacheManager();
  
  /// IsolateManager for background processing
  late final IsolateManager _isolateManager;
  
  /// Device performance tier for adaptive behavior
  DevicePerformanceTier _performanceTier = DevicePerformanceTier.medium;
  
  /// Số lượng tối đa các ảnh được tiền tải cùng lúc
  int _maxConcurrentPreloads = 3;
  
  /// Hàng đợi tiền tải
  final List<String> _preloadQueue = [];
  
  /// Đang tiền tải
  final Set<String> _currentlyPreloading = {};
  
  /// Sizes tối ưu cho thumbnails
  static const int THUMBNAIL_SIZE_SMALL = 100;
  static const int THUMBNAIL_SIZE_MEDIUM = 300;
  static const int THUMBNAIL_SIZE_LARGE = 600;
  
  /// Chất lượng nén mặc định (0-100)
  static const int DEFAULT_COMPRESS_QUALITY = 85;
  
  /// Maximum width cho ảnh được optimize (để tránh quá lớn khi upload)
  static const int MAX_OPTIMIZE_WIDTH = 1920;
  
  /// Private constructor
  MediaCacheManager._internal() {
    _initializeDependencies();
  }
  
  /// Khởi tạo các dependencies
  Future<void> _initializeDependencies() async {
    try {
      // Lấy IsolateManager từ DI container
      _isolateManager = GetIt.I<IsolateManager>();
      
      // Xác định performance tier
      _performanceTier = await DeviceCapabilityDetector.detectCapabilities();
      
      // Điều chỉnh cấu hình dựa trên performance tier
      _adjustSettings();
      
      _logger.i('MediaCacheManager đã khởi tạo: Performance tier = $_performanceTier');
    } catch (e) {
      _logger.e('Lỗi khi khởi tạo MediaCacheManager: $e');
    }
  }
  
  /// Điều chỉnh cấu hình dựa trên khả năng thiết bị
  void _adjustSettings() {
    switch (_performanceTier) {
      case DevicePerformanceTier.low:
        _maxConcurrentPreloads = 1;
        break;
      case DevicePerformanceTier.medium:
        _maxConcurrentPreloads = 3;
        break;
      case DevicePerformanceTier.high:
        _maxConcurrentPreloads = 5;
        break;
    }
  }
  
  /// Lấy hình ảnh với kích thước tối ưu
  Future<File> getOptimizedImage(
    String url, {
    int? width,
    int? height,
    bool useIsolate = true,
  }) async {
    // Tạo key dựa vào URL và kích thước yêu cầu
    final cacheKey = _generateCacheKey(url, width, height);
    
    try {
      // Kiểm tra xem hình ảnh đã tối ưu đã được cache chưa
      if (await _cacheManager.isMediaCached(cacheKey)) {
        _logger.v('Lấy hình ảnh tối ưu từ cache: $cacheKey');
        return await _cacheManager.getMediaFile(cacheKey);
      }
      
      // Nếu không có trong cache, tải và tối ưu
      final originalFile = await _cacheManager.getMediaFile(url);
      
      if (useIsolate && _isolateManager != null) {
        // Xử lý trong isolate để không block main thread
        final optimizedBytes = await _processImageInIsolate(
          originalFile.path,
          width: width,
          height: height,
        );
        
        // Lưu vào file tạm
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${path.basename(cacheKey)}');
        await tempFile.writeAsBytes(optimizedBytes);
        
        // Lưu vào cache
        await _cacheManager.cacheFile(cacheKey, optimizedBytes);
        
        return tempFile;
      } else {
        // Xử lý trong main thread nếu không dùng isolate
        final optimizedFile = await _optimizeImage(
          originalFile,
          width: width,
          height: height,
        );
        
        // Lưu phiên bản tối ưu vào cache
        final optimizedBytes = await optimizedFile.readAsBytes();
        await _cacheManager.cacheFile(cacheKey, optimizedBytes);
        
        return optimizedFile;
      }
    } catch (e) {
      _logger.e('Lỗi khi lấy hình ảnh tối ưu: $e');
      rethrow;
    }
  }
  
  /// Xử lý ảnh trong isolate
  Future<Uint8List> _processImageInIsolate(
    String imagePath, {
    int? width,
    int? height,
  }) async {
    // Tạo một task ID duy nhất
    final taskId = 'img_optimize_${DateTime.now().millisecondsSinceEpoch}';
    
    // Chuẩn bị dữ liệu cho isolate
    final params = {
      'width': width,
      'height': height,
      'quality': DEFAULT_COMPRESS_QUALITY,
    };
    
    // Thực thi trong isolate
    final result = await _isolateManager.processInBackground(
      taskType: IsolateTaskType.imageProcessing,
      taskId: taskId,
      data: imagePath,
      params: params,
      priority: TaskPriority.medium,
    );
    
    if (result.error != null) {
      throw Exception('Lỗi khi xử lý ảnh trong isolate: ${result.error}');
    }
    
    return result.result as Uint8List;
  }
  
  /// Tạo và lấy thumbnail cho một hình ảnh
  Future<File> getImageThumbnail(
    String imageUrl, {
    int size = THUMBNAIL_SIZE_MEDIUM,
    bool useIsolate = true,
  }) async {
    final thumbnailCacheKey = '${imageUrl}_thumb_$size';
    
    try {
      // Kiểm tra xem thumbnail đã có trong cache chưa
      if (await _cacheManager.isMediaCached(thumbnailCacheKey, thumbnail: true)) {
        _logger.v('Lấy thumbnail hình ảnh từ cache: $thumbnailCacheKey');
        return await _cacheManager.getMediaFile(thumbnailCacheKey, thumbnail: true);
      }
      
      // Nếu không có, tải ảnh gốc
      final originalFile = await _cacheManager.getMediaFile(imageUrl);
      
      if (useIsolate && _isolateManager != null) {
        // Xử lý trong isolate 
        final thumbnailBytes = await _generateThumbnailInIsolate(
          originalFile.path,
          size: size,
        );
        
        // Lưu vào file tạm
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${path.basename(thumbnailCacheKey)}');
        await tempFile.writeAsBytes(thumbnailBytes);
        
        // Lưu thumbnail vào cache
        await _cacheManager.cacheFile(thumbnailCacheKey, thumbnailBytes, thumbnail: true);
        
        return tempFile;
      } else {
        // Xử lý trong main thread
        final thumbnailFile = await _generateImageThumbnail(originalFile.path, size);
        
        // Lưu thumbnail vào cache
        final thumbnailBytes = await thumbnailFile.readAsBytes();
        await _cacheManager.cacheFile(thumbnailCacheKey, thumbnailBytes, thumbnail: true);
        
        return thumbnailFile;
      }
    } catch (e) {
      _logger.e('Lỗi khi tạo thumbnail hình ảnh: $e');
      rethrow;
    }
  }
  
  /// Tạo thumbnail trong isolate
  Future<Uint8List> _generateThumbnailInIsolate(
    String imagePath, {
    required int size,
  }) async {
    // Tạo task ID duy nhất
    final taskId = 'thumb_gen_${DateTime.now().millisecondsSinceEpoch}';
    
    // Chuẩn bị tham số
    final params = {
      'size': size,
      'quality': 80, // Chất lượng cho thumbnail
    };
    
    // Thực thi trong isolate
    final result = await _isolateManager.processInBackground(
      taskType: IsolateTaskType.imageProcessing,
      taskId: taskId,
      data: imagePath,
      params: params,
      priority: TaskPriority.low, // Thumbnail là ưu tiên thấp
    );
    
    if (result.error != null) {
      throw Exception('Lỗi khi tạo thumbnail trong isolate: ${result.error}');
    }
    
    return result.result as Uint8List;
  }
  
  /// Tiền tải các ảnh và thumbnail dựa trên danh sách URL
  Future<void> preloadImages(
    List<String> imageUrls, {
    int thumbnailSize = THUMBNAIL_SIZE_SMALL,
    bool preloadFullImages = false,
  }) async {
    if (imageUrls.isEmpty) return;
    
    // Thêm vào hàng đợi tiền tải
    for (final url in imageUrls) {
      if (!_preloadQueue.contains(url) && !_currentlyPreloading.contains(url)) {
        _preloadQueue.add(url);
      }
    }
    
    // Bắt đầu tiền tải nếu chưa đạt số lượng tối đa
    _processPreloadQueue(thumbnailSize, preloadFullImages);
  }
  
  /// Xử lý hàng đợi tiền tải
  void _processPreloadQueue(int thumbnailSize, bool preloadFullImages) {
    if (_preloadQueue.isEmpty || _currentlyPreloading.length >= _maxConcurrentPreloads) {
      return;
    }
    
    // Lấy URL tiếp theo từ hàng đợi
    final url = _preloadQueue.removeAt(0);
    _currentlyPreloading.add(url);
    
    // Tiền tải bất đồng bộ
    () async {
      try {
        // Tiền tải thumbnail
        await getImageThumbnail(url, size: thumbnailSize, useIsolate: true);
        
        // Tiền tải ảnh đầy đủ nếu được yêu cầu
        if (preloadFullImages) {
          await getOptimizedImage(url, useIsolate: true);
        }
      } catch (e) {
        _logger.w('Lỗi khi tiền tải ảnh $url: $e');
      } finally {
        _currentlyPreloading.remove(url);
        
        // Xử lý URL tiếp theo trong hàng đợi
        _processPreloadQueue(thumbnailSize, preloadFullImages);
      }
    }();
    
    // Nếu vẫn có thể xử lý thêm, tiếp tục lấy từ hàng đợi
    if (_currentlyPreloading.length < _maxConcurrentPreloads) {
      _processPreloadQueue(thumbnailSize, preloadFullImages);
    }
  }
  
  /// Tạo key cho cache dựa trên URL và kích thước
  String _generateCacheKey(String url, int? width, int? height) {
    if (width == null && height == null) {
      return url;
    }
    return '${url}_w${width ?? 0}_h${height ?? 0}';
  }
  
  /// Tối ưu hình ảnh trước khi tải lên
  Future<File> optimizeForUpload(File imageFile, {int quality = DEFAULT_COMPRESS_QUALITY}) async {
    try {
      final targetPath = await _getTemporaryFilePath('.jpg');
      
      _logger.v('Tối ưu hình ảnh trước khi tải lên: ${imageFile.path}');
      
      // Nén hình ảnh với kích thước tối đa
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: quality,
        minWidth: MAX_OPTIMIZE_WIDTH,
        keepExif: false, // Loại bỏ EXIF data để giảm kích thước
      );
      
      if (result == null) {
        throw Exception('Không thể tối ưu hình ảnh');
      }
      
      // So sánh kích thước file
      final originalSize = await imageFile.length();
      final optimizedSize = await result.length();
      
      _logger.i('Tối ưu hình ảnh: '
          '${(originalSize / 1024).toStringAsFixed(2)}KB -> '
          '${(optimizedSize / 1024).toStringAsFixed(2)}KB '
          '(giảm ${(100 - (optimizedSize / originalSize * 100)).toStringAsFixed(2)}%)');
      
      return File(result.path);
    } catch (e) {
      _logger.e('Lỗi khi tối ưu hình ảnh: $e');
      // Trả về file gốc nếu có lỗi
      return imageFile;
    }
  }
  
  /// Nén video trước khi tải lên
  Future<MediaInfo?> compressVideo(File videoFile) async {
    try {
      _logger.v('Bắt đầu nén video: ${videoFile.path}');
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      
      if (info != null) {
        final originalSize = info.filesize ?? 0;
        final compressedSize = File(info.path!).lengthSync();
        
        _logger.i('Nén video: '
            '${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB -> '
            '${(compressedSize / 1024 / 1024).toStringAsFixed(2)}MB '
            '(giảm ${(100 - (compressedSize / originalSize * 100)).toStringAsFixed(2)}%)');
      }
      
      return info;
    } catch (e) {
      _logger.e('Lỗi khi nén video: $e');
      return null;
    }
  }
  
  /// Tiền tải thumbnail cho danh sách URLs
  Future<void> prefetchThumbnails(List<String> imageUrls, {int size = THUMBNAIL_SIZE_SMALL}) async {
    // Chỉ tiền tải tối đa 10 thumbnail để tránh quá tải
    final urlsToLoad = imageUrls.take(10).toList();
    
    for (final url in urlsToLoad) {
      try {
        unawaited(getImageThumbnail(url, size: size));
      } catch (e) {
        // Bỏ qua lỗi khi tiền tải
        _logger.v('Lỗi khi tiền tải thumbnail: $e');
      }
    }
  }
  
  /// Tạo Uint8List thumbnail từ widget (dùng cho các preview tùy chỉnh)
  Future<Uint8List?> generateWidgetThumbnail(
      ui.Image image, {int maxWidth = 300, int maxHeight = 300}) async {
    try {
      // Tính toán tỷ lệ để giữ nguyên tỷ lệ khung hình
      final ratio = image.width / image.height;
      int width = maxWidth;
      int height = (width / ratio).round();
      
      if (height > maxHeight) {
        height = maxHeight;
        width = (height * ratio).round();
      }
      
      // Tạo thumbnail với kích thước mới
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..filterQuality = FilterQuality.medium,
      );
      
      final picture = recorder.endRecording();
      final thumbnail = await picture.toImage(width, height);
      
      final byteData = await thumbnail.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _logger.e('Lỗi khi tạo thumbnail từ widget: $e');
      return null;
    }
  }
  
  /// Xóa cache media không còn dùng đến
  Future<void> clearUnusedCache(List<String> activeUrls) async {
    // Implement heuristic để xóa cache không còn dùng đến
    // Nhưng vẫn giữ active URLs
  }
  
  /// Tạo đường dẫn file tạm
  Future<String> _getTemporaryFilePath(String extension) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(tempDir.path, 'media_$timestamp$extension');
  }
  
  /// Lấy thumbnail cho video
  Future<File> getVideoThumbnail(String videoUrl, {int quality = 50}) async {
    final thumbnailCacheKey = '${videoUrl}_video_thumb';
    
    try {
      // Kiểm tra xem thumbnail đã có trong cache chưa
      if (await _cacheManager.isMediaCached(thumbnailCacheKey, thumbnail: true)) {
        _logger.v('Lấy thumbnail video từ cache: $thumbnailCacheKey');
        return await _cacheManager.getMediaFile(thumbnailCacheKey, thumbnail: true);
      }
      
      // Nếu không có, tải video và tạo thumbnail
      final videoFile = await _cacheManager.getMediaFile(videoUrl);
      final thumbnailFile = await _generateVideoThumbnail(videoFile.path, quality);
      
      // Lưu thumbnail vào cache
      final thumbnailBytes = await thumbnailFile.readAsBytes();
      await _cacheManager.cacheFile(thumbnailCacheKey, thumbnailBytes, thumbnail: true);
      
      return thumbnailFile;
    } catch (e) {
      _logger.e('Lỗi khi tạo thumbnail video: $e');
      rethrow;
    }
  }
  
  /// Tạo thumbnail cho video
  Future<File> _generateVideoThumbnail(String videoPath, int quality) async {
    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: quality,
        position: -1, // -1 lấy frame ở giữa video
      );
      
      return thumbnailFile;
    } catch (e) {
      _logger.e('Lỗi khi tạo thumbnail cho video: $e');
      rethrow;
    }
  }
  
  /// Phương thức tối ưu hình ảnh
  Future<File> _optimizeImage(File file, {int? width, int? height}) async {
    final targetPath = await _getTemporaryFilePath('.jpg');
    
    _logger.v('Tối ưu hình ảnh: ${file.path} (${width}x${height})');
    
    int targetWidth = width ?? MAX_OPTIMIZE_WIDTH;
    int targetHeight = height ?? 1080;
    
    // Không cần nén nếu kích thước đã đủ nhỏ
    final fileSize = await file.length();
    if (fileSize < 200 * 1024) { // < 200KB
      return file;
    }
    
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: DEFAULT_COMPRESS_QUALITY,
        minWidth: targetWidth,
        minHeight: targetHeight,
      );
      
      if (result == null) {
        _logger.e('Không thể tối ưu hình ảnh');
        return file;
      }
      
      return File(result.path);
    } catch (e) {
      _logger.e('Lỗi khi tối ưu hình ảnh: $e');
      return file;
    }
  }
  
  /// Tạo thumbnail cho hình ảnh
  Future<File> _generateImageThumbnail(String imagePath, int size) async {
    final targetPath = await _getTemporaryFilePath('.jpg');
    
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: 80,
        minWidth: size,
        minHeight: size,
      );
      
      if (result == null) {
        throw Exception('Không thể tạo thumbnail cho hình ảnh');
      }
      
      return File(result.path);
    } catch (e) {
      _logger.e('Lỗi khi tạo thumbnail hình ảnh: $e');
      rethrow;
    }
  }
}

/// Hàm tiện ích để cho phép không đồng bộ mà không cần await
void unawaited(Future<void> future) {} 