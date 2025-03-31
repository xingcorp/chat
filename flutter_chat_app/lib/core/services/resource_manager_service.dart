import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import 'package:video_compress/video_compress.dart';

/// Quản lý tài nguyên và tối ưu hóa hiệu suất cho ứng dụng
@lazySingleton
class ResourceManagerService {
  /// Giới hạn kích thước hình ảnh (MB) để xử lý bằng compute
  static const double _imageComputeThresholdMB = 2.0;
  
  /// Giới hạn kích thước video (MB) để xử lý bằng isolate
  static const double _videoIsolateThresholdMB = 10.0;
  
  /// Chất lượng nén hình ảnh mặc định
  static const int _defaultImageQuality = 80;
  
  /// Chất lượng nén video mặc định
  static const int _defaultVideoQuality = 70;
  
  /// Tạo UUID cho các tệp tin
  final _uuid = Uuid();
  
  /// Thư mục tạm để lưu các tệp đang xử lý
  late final Directory _tempDir;
  
  /// Thư mục cache để lưu các tệp đã tải về
  late final Directory _cacheDir;
  
  /// Khởi tạo service
  Future<void> initialize() async {
    try {
      _tempDir = await getTemporaryDirectory();
      _cacheDir = await getApplicationCacheDirectory();
      debugPrint('ResourceManagerService đã khởi tạo thành công');
      debugPrint('Thư mục tạm: ${_tempDir.path}');
      debugPrint('Thư mục cache: ${_cacheDir.path}');
    } catch (e) {
      debugPrint('Lỗi khởi tạo ResourceManagerService: $e');
      rethrow;
    }
  }
  
  /// Nén hình ảnh với tối ưu hóa đa lõi
  /// 
  /// [file]: Tệp hình ảnh cần nén
  /// [quality]: Chất lượng nén (1-100)
  /// [maxWidth]: Chiều rộng tối đa
  /// [maxHeight]: Chiều cao tối đa
  /// Trả về tệp đã nén
  Future<File> compressImage({
    required File file,
    int quality = _defaultImageQuality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final fileSize = await file.length();
    final fileSizeMB = fileSize / (1024 * 1024);
    
    // Tạo tệp đích
    final targetPath = _generateTempFilePath(
      extension: _getExtension(file.path),
      prefix: 'compressed_img_',
    );
    
    try {
      if (fileSizeMB > _imageComputeThresholdMB) {
        // Sử dụng compute cho tệp lớn để tránh block UI thread
        debugPrint('Nén hình ảnh lớn (${fileSizeMB.toStringAsFixed(2)}MB) bằng compute');
        
        final result = await compute(_compressImageIsolate, {
          'sourcePath': file.path,
          'targetPath': targetPath,
          'quality': quality,
          'maxWidth': maxWidth,
          'maxHeight': maxHeight,
        });
        
        return File(result);
      } else {
        // Xử lý trực tiếp trên thread chính
        debugPrint('Nén hình ảnh nhỏ (${fileSizeMB.toStringAsFixed(2)}MB) trên main thread');
        
        final result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: quality,
          minWidth: maxWidth ?? 1080,
          minHeight: maxHeight ?? 1920,
        );
        
        if (result == null) {
          throw Exception('Nén hình ảnh thất bại');
        }
        
        return File(result.path);
      }
    } catch (e) {
      debugPrint('Lỗi nén hình ảnh: $e');
      // Trả về tệp gốc nếu nén thất bại
      return file;
    }
  }
  
  /// Nén video với tối ưu hóa đa lõi
  /// 
  /// [file]: Tệp video cần nén
  /// [quality]: Chất lượng nén (dùng enum VideoQuality)
  /// Trả về tệp đã nén
  Future<File?> compressVideo({
    required File file,
    VideoQuality quality = VideoQuality.DefaultQuality,
  }) async {
    final fileSize = await file.length();
    final fileSizeMB = fileSize / (1024 * 1024);
    
    try {
      if (fileSizeMB > _videoIsolateThresholdMB) {
        // Sử dụng isolate riêng cho video lớn
        debugPrint('Nén video lớn (${fileSizeMB.toStringAsFixed(2)}MB) bằng isolate');
        return await _compressVideoWithIsolate(file, quality);
      } else {
        // Dùng thư viện trực tiếp cho video nhỏ
        debugPrint('Nén video nhỏ (${fileSizeMB.toStringAsFixed(2)}MB) với VideoCompress');
        
        final info = await VideoCompress.compressVideo(
          file.path,
          quality: quality,
          deleteOrigin: false,
        );
        
        return info?.file;
      }
    } catch (e) {
      debugPrint('Lỗi nén video: $e');
      return null;
    }
  }
  
  /// Lấy thumbnail từ video
  /// 
  /// [videoFile]: Tệp video cần lấy thumbnail
  /// [quality]: Chất lượng thumbnail (1-100)
  /// [timeMs]: Vị trí thời gian để lấy thumbnail (milliseconds)
  Future<File?> getVideoThumbnail({
    required File videoFile,
    int quality = 50,
    int timeMs = 0,
  }) async {
    try {
      return await compute(_extractThumbnailIsolate, {
        'videoPath': videoFile.path,
        'quality': quality,
        'timeMs': timeMs,
      });
    } catch (e) {
      debugPrint('Lỗi tạo thumbnail: $e');
      return null;
    }
  }
  
  /// Quản lý tải tệp media lớn
  /// 
  /// [url]: URL của tệp cần tải
  /// [useCaching]: Có lưu vào bộ nhớ cache hay không
  /// [onProgress]: Callback tiến trình tải (0.0 - 1.0)
  /// [streamingMode]: Sử dụng chế độ streaming (cho video/audio)
  Future<File?> loadMedia({
    required String url,
    bool useCaching = true,
    Function(double)? onProgress,
    bool streamingMode = false,
  }) async {
    // Nếu URL là đường dẫn cục bộ, trả về tệp ngay
    if (url.startsWith('file://') || url.startsWith('/')) {
      final file = File(url.replaceAll('file://', ''));
      if (await file.exists()) {
        return file;
      }
    }
    
    // Kiểm tra cache
    if (useCaching) {
      final cachedFile = _getCachedFile(url);
      if (cachedFile != null && await cachedFile.exists()) {
        debugPrint('Đã tìm thấy tệp trong cache: ${cachedFile.path}');
        return cachedFile;
      }
    }
    
    try {
      if (streamingMode) {
        // Trả về null vì streaming sẽ được xử lý bởi player
        debugPrint('Sử dụng chế độ streaming cho: $url');
        return null;
      } else {
        // Tải tệp hoàn chỉnh
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(url));
        final response = await request.close();
        
        // Tạo tệp đích
        final cachedFilePath = _generateCacheFilePath(
          url: url,
          mimeType: _guessMimeType(url),
        );
        final file = File(cachedFilePath);
        
        // Theo dõi tiến trình tải
        final contentLength = response.contentLength;
        int bytesReceived = 0;
        
        // Sử dụng compute để tránh block UI thread
        final completer = Completer<File>();
        
        // Tạo tệp và ghi dữ liệu
        final sink = file.openWrite();
        
        response.listen(
          (data) {
            sink.add(data);
            bytesReceived += data.length;
            
            if (contentLength > 0 && onProgress != null) {
              onProgress(bytesReceived / contentLength);
            }
          },
          onDone: () async {
            await sink.flush();
            await sink.close();
            httpClient.close();
            completer.complete(file);
          },
          onError: (e) {
            sink.close();
            httpClient.close();
            completer.completeError(e);
          },
          cancelOnError: true,
        );
        
        return await completer.future;
      }
    } catch (e) {
      debugPrint('Lỗi tải media: $e');
      return null;
    }
  }
  
  /// Xóa tệp khỏi cache
  Future<bool> removeFromCache(String url) async {
    try {
      final file = _getCachedFile(url);
      if (file != null && await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi xóa tệp khỏi cache: $e');
      return false;
    }
  }
  
  /// Xóa toàn bộ cache
  Future<bool> clearCache() async {
    try {
      final dir = Directory(_cacheDir.path);
      await dir.delete(recursive: true);
      await dir.create();
      return true;
    } catch (e) {
      debugPrint('Lỗi xóa cache: $e');
      return false;
    }
  }
  
  /// Xóa tệp tạm
  Future<void> clearTemporaryFiles() async {
    try {
      final dir = Directory(_tempDir.path);
      
      final entities = await dir.list().toList();
      for (var entity in entities) {
        if (entity is File && 
            (entity.path.contains('compressed_') || 
             entity.path.contains('thumbnail_'))) {
          await entity.delete();
        }
      }
      
      debugPrint('Đã xóa các tệp tạm');
    } catch (e) {
      debugPrint('Lỗi xóa tệp tạm: $e');
    }
  }
  
  /// Tính toán kích thước cache
  Future<int> getCacheSize() async {
    try {
      final dir = Directory(_cacheDir.path);
      int totalSize = 0;
      
      await for (var entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Lỗi tính kích thước cache: $e');
      return 0;
    }
  }
  
  /// Lấy tệp từ cache
  File? _getCachedFile(String url) {
    final filePath = _generateCacheFilePath(
      url: url,
      mimeType: _guessMimeType(url),
    );
    
    final file = File(filePath);
    return file;
  }
  
  /// Tạo đường dẫn tệp cache
  String _generateCacheFilePath({
    required String url,
    String? mimeType,
  }) {
    // Tạo hash từ URL để làm tên tệp
    final fileHash = url.hashCode.toString();
    final extension = _getExtensionFromUrl(url) ?? _getExtensionFromMimeType(mimeType);
    
    return '${_cacheDir.path}/media_$fileHash$extension';
  }
  
  /// Tạo đường dẫn tệp tạm
  String _generateTempFilePath({
    required String extension,
    String prefix = '',
  }) {
    final fileName = '$prefix${_uuid.v4()}$extension';
    return '${_tempDir.path}/$fileName';
  }
  
  /// Lấy phần mở rộng từ URL
  String? _getExtensionFromUrl(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    
    // Lấy phần mở rộng từ đường dẫn
    final index = path.lastIndexOf('.');
    if (index != -1 && index < path.length - 1) {
      return path.substring(index);
    }
    
    return null;
  }
  
  /// Lấy phần mở rộng từ MIME type
  String _getExtensionFromMimeType(String? mimeType) {
    if (mimeType == null) return '.dat';
    
    final parts = mimeType.split('/');
    if (parts.length != 2) return '.dat';
    
    switch (parts[0]) {
      case 'image':
        return '.${parts[1] == 'jpeg' ? 'jpg' : parts[1]}';
      case 'video':
        return '.${parts[1]}';
      case 'audio':
        return '.${parts[1]}';
      default:
        return '.dat';
    }
  }
  
  /// Lấy MIME type từ URL
  String? _guessMimeType(String url) {
    return lookupMimeType(url);
  }
  
  /// Lấy phần mở rộng của tệp
  String _getExtension(String path) {
    final index = path.lastIndexOf('.');
    if (index != -1 && index < path.length - 1) {
      return path.substring(index);
    }
    return '';
  }
  
  /// Nén video trong một isolate riêng
  Future<File?> _compressVideoWithIsolate(File file, VideoQuality quality) async {
    final completer = Completer<File?>();
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      _videoCompressIsolate,
      {
        'sendPort': receivePort.sendPort,
        'videoPath': file.path,
        'quality': quality.index,
      },
      debugName: 'video_compression',
    );
    
    receivePort.listen((message) {
      if (message is Map) {
        if (message.containsKey('error')) {
          debugPrint('Lỗi nén video trong isolate: ${message['error']}');
          completer.complete(null);
        } else if (message.containsKey('result')) {
          final resultPath = message['result'] as String?;
          if (resultPath != null) {
            completer.complete(File(resultPath));
          } else {
            completer.complete(null);
          }
        }
      }
      
      receivePort.close();
    });
    
    return completer.future;
  }
}

/// Hàm nén hình ảnh để chạy trong isolate (compute)
Future<String> _compressImageIsolate(Map params) async {
  final sourcePath = params['sourcePath'] as String;
  final targetPath = params['targetPath'] as String;
  final quality = params['quality'] as int;
  final maxWidth = params['maxWidth'] as int?;
  final maxHeight = params['maxHeight'] as int?;
  
  final result = await FlutterImageCompress.compressAndGetFile(
    sourcePath,
    targetPath,
    quality: quality,
    minWidth: maxWidth ?? 1080,
    minHeight: maxHeight ?? 1920,
  );
  
  if (result == null) {
    throw Exception('Nén hình ảnh thất bại');
  }
  
  return result.path;
}

/// Extract thumbnail trong isolate (compute)
Future<File?> _extractThumbnailIsolate(Map params) async {
  final videoPath = params['videoPath'] as String;
  final quality = params['quality'] as int;
  final timeMs = params['timeMs'] as int;
  
  try {
    final thumbnail = await VideoCompress.getFileThumbnail(
      videoPath,
      quality: quality,
      position: timeMs,
    );
    
    return thumbnail;
  } catch (e) {
    print('Lỗi tạo thumbnail trong isolate: $e');
    return null;
  }
}

/// Hàm nén video trong isolate riêng
void _videoCompressIsolate(Map params) async {
  final SendPort sendPort = params['sendPort'] as SendPort;
  final String videoPath = params['videoPath'] as String;
  final int qualityIndex = params['quality'] as int;
  
  try {
    final quality = VideoQuality.values[qualityIndex];
    
    final info = await VideoCompress.compressVideo(
      videoPath,
      quality: quality,
      deleteOrigin: false,
    );
    
    if (info?.file != null) {
      sendPort.send({'result': info!.file!.path});
    } else {
      sendPort.send({'result': null});
    }
  } catch (e) {
    sendPort.send({'error': e.toString()});
  }
} 