import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import 'app_cache_manager.dart';

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
  
  /// Sizes tối ưu cho thumbnails
  static const int THUMBNAIL_SIZE_SMALL = 100;
  static const int THUMBNAIL_SIZE_MEDIUM = 300;
  static const int THUMBNAIL_SIZE_LARGE = 600;
  
  /// Chất lượng nén mặc định (0-100)
  static const int DEFAULT_COMPRESS_QUALITY = 85;
  
  /// Maximum width cho ảnh được optimize (để tránh quá lớn khi upload)
  static const int MAX_OPTIMIZE_WIDTH = 1920;
  
  /// Private constructor
  MediaCacheManager._internal();
  
  /// Lấy hình ảnh với kích thước tối ưu
  Future<File> getOptimizedImage(String url, {int? width, int? height}) async {
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
      final optimizedFile = await _optimizeImage(
        originalFile,
        width: width,
        height: height,
      );
      
      // Lưu phiên bản tối ưu vào cache
      final optimizedBytes = await optimizedFile.readAsBytes();
      await _cacheManager.cacheFile(cacheKey, optimizedBytes);
      
      return optimizedFile;
    } catch (e) {
      _logger.e('Lỗi khi lấy hình ảnh tối ưu: $e');
      rethrow;
    }
  }
  
  /// Tạo và lấy thumbnail cho một hình ảnh
  Future<File> getImageThumbnail(String imageUrl, {int size = THUMBNAIL_SIZE_MEDIUM}) async {
    final thumbnailCacheKey = '${imageUrl}_thumb_$size';
    
    try {
      // Kiểm tra xem thumbnail đã có trong cache chưa
      if (await _cacheManager.isMediaCached(thumbnailCacheKey, thumbnail: true)) {
        _logger.v('Lấy thumbnail hình ảnh từ cache: $thumbnailCacheKey');
        return await _cacheManager.getMediaFile(thumbnailCacheKey, thumbnail: true);
      }
      
      // Nếu không có, tải ảnh gốc và tạo thumbnail
      final originalFile = await _cacheManager.getMediaFile(imageUrl);
      final thumbnailFile = await _generateImageThumbnail(originalFile.path, size);
      
      // Lưu thumbnail vào cache
      final thumbnailBytes = await thumbnailFile.readAsBytes();
      await _cacheManager.cacheFile(thumbnailCacheKey, thumbnailBytes, thumbnail: true);
      
      return thumbnailFile;
    } catch (e) {
      _logger.e('Lỗi khi tạo thumbnail hình ảnh: $e');
      rethrow;
    }
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
  
  /// Tạo key cho cache dựa vào URL và kích thước
  String _generateCacheKey(String url, int? width, int? height) {
    if (width != null || height != null) {
      return '${url}_w${width ?? 0}_h${height ?? 0}';
    }
    return url;
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
  
  /// Tạo đường dẫn file tạm
  Future<String> _getTemporaryFilePath(String extension) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(tempDir.path, 'media_$timestamp$extension');
  }
}

/// Hàm tiện ích để cho phép không đồng bộ mà không cần await
void unawaited(Future<void> future) {} 