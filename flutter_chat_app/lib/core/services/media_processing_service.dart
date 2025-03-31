import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Các loại xử lý media được hỗ trợ
enum MediaProcessingType {
  /// Nén hình ảnh
  imageCompression,
  
  /// Thay đổi kích thước hình ảnh
  imageResize,
  
  /// Áp dụng bộ lọc hình ảnh
  imageFilter,
  
  /// Cắt hình ảnh
  imageCrop,
  
  /// Mã hóa media 
  encryption,
  
  /// Giải mã media
  decryption,
}

/// Kết quả xử lý media
class MediaProcessingResult {
  /// File kết quả
  final File? outputFile;
  
  /// Dữ liệu bytes kết quả
  final Uint8List? outputBytes;
  
  /// Thông điệp lỗi nếu có
  final String? errorMessage;
  
  /// Thời gian xử lý (milliseconds)
  final int processingTimeMs;
  
  /// Xác định xử lý thành công hay không
  bool get isSuccess => errorMessage == null && (outputFile != null || outputBytes != null);
  
  /// Constructor cho kết quả thành công
  MediaProcessingResult.success({
    this.outputFile,
    this.outputBytes,
    required this.processingTimeMs,
  }) : errorMessage = null;
  
  /// Constructor cho kết quả lỗi
  MediaProcessingResult.error({
    required String error,
    required this.processingTimeMs,
  }) : 
    errorMessage = error,
    outputFile = null,
    outputBytes = null;
}

/// Service xử lý media trong isolate riêng
@lazySingleton
class MediaProcessingService {
  /// Biến cho việc tạo UUID
  final _uuid = Uuid();
  
  /// Thư mục tạm để lưu các tệp xử lý
  late final Directory _tempDir;
  
  /// Khởi tạo service
  Future<void> initialize() async {
    try {
      _tempDir = await getTemporaryDirectory();
      debugPrint('MediaProcessingService đã khởi tạo thành công');
      debugPrint('Thư mục tạm: ${_tempDir.path}');
    } catch (e) {
      debugPrint('Lỗi khởi tạo MediaProcessingService: $e');
      rethrow;
    }
  }
  
  /// Nén hình ảnh trong isolate
  Future<MediaProcessingResult> compressImage({
    required File imageFile,
    int quality = 80,
    bool preserveExif = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Tạo đường dẫn tệp đích
      final outputPath = _generateTempFilePath(extension: '.jpg');
      
      // Thực hiện nén trong isolate
      final outputFile = await compute(
        _compressImageIsolate,
        {
          'inputPath': imageFile.path,
          'outputPath': outputPath,
          'quality': quality,
          'preserveExif': preserveExif,
        },
      );
      
      stopwatch.stop();
      return MediaProcessingResult.success(
        outputFile: outputFile,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('Lỗi nén hình ảnh: $e');
      return MediaProcessingResult.error(
        error: 'Không thể nén hình ảnh: $e',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  
  /// Thay đổi kích thước hình ảnh trong isolate
  Future<MediaProcessingResult> resizeImage({
    required File imageFile, 
    required int width,
    required int height,
    bool maintainAspectRatio = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final outputPath = _generateTempFilePath(extension: '.jpg');
      
      final outputFile = await compute(
        _resizeImageIsolate,
        {
          'inputPath': imageFile.path,
          'outputPath': outputPath,
          'width': width,
          'height': height,
          'maintainAspectRatio': maintainAspectRatio,
        },
      );
      
      stopwatch.stop();
      return MediaProcessingResult.success(
        outputFile: outputFile,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('Lỗi thay đổi kích thước hình ảnh: $e');
      return MediaProcessingResult.error(
        error: 'Không thể thay đổi kích thước hình ảnh: $e',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  
  /// Cắt hình ảnh trong isolate
  Future<MediaProcessingResult> cropImage({
    required File imageFile,
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final outputPath = _generateTempFilePath(extension: '.jpg');
      
      final outputFile = await compute(
        _cropImageIsolate,
        {
          'inputPath': imageFile.path,
          'outputPath': outputPath,
          'x': x,
          'y': y,
          'width': width,
          'height': height,
        },
      );
      
      stopwatch.stop();
      return MediaProcessingResult.success(
        outputFile: outputFile,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('Lỗi cắt hình ảnh: $e');
      return MediaProcessingResult.error(
        error: 'Không thể cắt hình ảnh: $e',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  
  /// Áp dụng bộ lọc hình ảnh trong isolate
  Future<MediaProcessingResult> applyImageFilter({
    required File imageFile,
    required String filterType,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final outputPath = _generateTempFilePath(extension: '.jpg');
      
      final outputFile = await compute(
        _applyImageFilterIsolate,
        {
          'inputPath': imageFile.path,
          'outputPath': outputPath,
          'filterType': filterType,
        },
      );
      
      stopwatch.stop();
      return MediaProcessingResult.success(
        outputFile: outputFile,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('Lỗi áp dụng bộ lọc hình ảnh: $e');
      return MediaProcessingResult.error(
        error: 'Không thể áp dụng bộ lọc: $e',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  
  /// Mã hóa tệp trong isolate
  Future<MediaProcessingResult> encryptFile({
    required File inputFile,
    required String password,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final outputPath = _generateTempFilePath(extension: '.enc');
      
      final result = await compute(
        _encryptFileIsolate,
        {
          'inputPath': inputFile.path,
          'outputPath': outputPath,
          'password': password,
        },
      );
      
      if (result['success'] as bool) {
        stopwatch.stop();
        return MediaProcessingResult.success(
          outputFile: File(result['outputPath'] as String),
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        stopwatch.stop();
        return MediaProcessingResult.error(
          error: result['error'] as String,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('Lỗi mã hóa tệp: $e');
      return MediaProcessingResult.error(
        error: 'Không thể mã hóa tệp: $e',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  
  /// Giải mã tệp trong isolate
  Future<MediaProcessingResult> decryptFile({
    required File encryptedFile,
    required String password,
    String? outputExtension,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final extension = outputExtension ?? '.dec';
      final outputPath = _generateTempFilePath(extension: extension);
      
      final result = await compute(
        _decryptFileIsolate,
        {
          'inputPath': encryptedFile.path,
          'outputPath': outputPath,
          'password': password,
        },
      );
      
      if (result['success'] as bool) {
        stopwatch.stop();
        return MediaProcessingResult.success(
          outputFile: File(result['outputPath'] as String),
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        stopwatch.stop();
        return MediaProcessingResult.error(
          error: result['error'] as String,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('Lỗi giải mã tệp: $e');
      return MediaProcessingResult.error(
        error: 'Không thể giải mã tệp: $e',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  
  /// Xử lý nhiều hình ảnh cùng lúc
  Future<List<MediaProcessingResult>> batchProcessImages({
    required List<File> imageFiles,
    required MediaProcessingType processingType,
    Map<String, dynamic> options = const {},
  }) async {
    final results = <MediaProcessingResult>[];
    
    // Chia nhỏ xử lý để tránh quá tải
    final maxConcurrent = 2;
    
    for (int i = 0; i < imageFiles.length; i += maxConcurrent) {
      final batch = imageFiles.skip(i).take(maxConcurrent);
      final futures = batch.map((file) {
        switch (processingType) {
          case MediaProcessingType.imageCompression:
            return compressImage(
              imageFile: file,
              quality: options['quality'] as int? ?? 80,
              preserveExif: options['preserveExif'] as bool? ?? false,
            );
          case MediaProcessingType.imageResize:
            return resizeImage(
              imageFile: file,
              width: options['width'] as int? ?? 800,
              height: options['height'] as int? ?? 600,
              maintainAspectRatio: options['maintainAspectRatio'] as bool? ?? true,
            );
          case MediaProcessingType.imageFilter:
            return applyImageFilter(
              imageFile: file,
              filterType: options['filterType'] as String? ?? 'grayscale',
            );
          case MediaProcessingType.imageCrop:
            return cropImage(
              imageFile: file,
              x: options['x'] as int? ?? 0,
              y: options['y'] as int? ?? 0,
              width: options['width'] as int? ?? 100,
              height: options['height'] as int? ?? 100,
            );
          default:
            throw ArgumentError('Loại xử lý không hỗ trợ');
        }
      });
      
      results.addAll(await Future.wait(futures));
    }
    
    return results;
  }
  
  /// Tạo đường dẫn tệp tạm
  String _generateTempFilePath({
    required String extension,
    String prefix = '',
  }) {
    final fileName = '$prefix${_uuid.v4()}$extension';
    return '${_tempDir.path}/$fileName';
  }
  
  /// Xóa tệp tạm
  Future<void> clearTemporaryFiles() async {
    try {
      final dir = Directory(_tempDir.path);
      
      final entities = await dir.list().toList();
      for (var entity in entities) {
        if (entity is File && 
            (entity.path.contains('img_') || 
             entity.path.contains('.enc') ||
             entity.path.contains('.dec'))) {
          await entity.delete();
        }
      }
      
      debugPrint('Đã xóa các tệp tạm');
    } catch (e) {
      debugPrint('Lỗi xóa tệp tạm: $e');
    }
  }
}

/// Xử lý nén hình ảnh trong isolate
Future<File> _compressImageIsolate(Map<String, dynamic> params) async {
  final inputPath = params['inputPath'] as String;
  final outputPath = params['outputPath'] as String;
  final quality = params['quality'] as int;
  final preserveExif = params['preserveExif'] as bool;
  
  // Đọc hình ảnh
  final bytes = await File(inputPath).readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) {
    throw Exception('Không thể đọc hình ảnh');
  }
  
  // Nén hình ảnh với chất lượng được chỉ định
  final encodedImage = img.encodeJpg(image, quality: quality);
  
  // Ghi hình ảnh đã nén
  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(encodedImage);
  
  return outputFile;
}

/// Xử lý thay đổi kích thước hình ảnh trong isolate
Future<File> _resizeImageIsolate(Map<String, dynamic> params) async {
  final inputPath = params['inputPath'] as String;
  final outputPath = params['outputPath'] as String;
  final width = params['width'] as int;
  final height = params['height'] as int;
  final maintainAspectRatio = params['maintainAspectRatio'] as bool;
  
  // Đọc hình ảnh
  final bytes = await File(inputPath).readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) {
    throw Exception('Không thể đọc hình ảnh');
  }
  
  // Thay đổi kích thước hình ảnh
  final resizedImage = maintainAspectRatio
      ? img.copyResize(image, width: width, height: height, interpolation: img.Interpolation.average)
      : img.copyResize(image, width: width, height: height, interpolation: img.Interpolation.average);
  
  // Ghi hình ảnh đã thay đổi kích thước
  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(img.encodeJpg(resizedImage));
  
  return outputFile;
}

/// Xử lý cắt hình ảnh trong isolate
Future<File> _cropImageIsolate(Map<String, dynamic> params) async {
  final inputPath = params['inputPath'] as String;
  final outputPath = params['outputPath'] as String;
  final x = params['x'] as int;
  final y = params['y'] as int;
  final width = params['width'] as int;
  final height = params['height'] as int;
  
  // Đọc hình ảnh
  final bytes = await File(inputPath).readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) {
    throw Exception('Không thể đọc hình ảnh');
  }
  
  // Cắt hình ảnh
  final croppedImage = img.copyCrop(image, x: x, y: y, width: width, height: height);
  
  // Ghi hình ảnh đã cắt
  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(img.encodeJpg(croppedImage));
  
  return outputFile;
}

/// Áp dụng bộ lọc cho hình ảnh
Future<File> _applyImageFilterIsolate(Map<String, dynamic> params) async {
  final inputPath = params['inputPath'] as String;
  final outputPath = params['outputPath'] as String;
  final filterType = params['filterType'] as String;
  
  // Đọc hình ảnh
  final bytes = await File(inputPath).readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) {
    throw Exception('Không thể đọc hình ảnh');
  }
  
  // Áp dụng bộ lọc
  late final img.Image filteredImage;
  
  switch (filterType.toLowerCase()) {
    case 'grayscale':
      filteredImage = img.grayscale(image);
      break;
    case 'sepia':
      filteredImage = img.sepia(image);
      break;
    case 'invert':
      filteredImage = img.invert(image);
      break;
    case 'blur':
      filteredImage = img.gaussianBlur(image, radius: 3);
      break;
    default:
      throw Exception('Bộ lọc không hỗ trợ: $filterType');
  }
  
  // Ghi hình ảnh đã lọc
  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(img.encodeJpg(filteredImage));
  
  return outputFile;
}

/// Mã hóa tệp trong isolate
Future<Map<String, dynamic>> _encryptFileIsolate(Map<String, dynamic> params) async {
  final inputPath = params['inputPath'] as String;
  final outputPath = params['outputPath'] as String;
  final password = params['password'] as String;
  
  try {
    // Đọc tệp nguồn
    final file = File(inputPath);
    final inputBytes = await file.readAsBytes();
    
    // Tạo khóa từ mật khẩu
    final keyBytes = _generateKey(password);
    
    // Mã hóa dữ liệu
    final encryptedBytes = _encryptData(inputBytes, keyBytes);
    
    // Ghi tệp đã mã hóa
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(encryptedBytes);
    
    return {
      'success': true,
      'outputPath': outputPath,
    };
  } catch (e) {
    return {
      'success': false,
      'error': 'Lỗi mã hóa: $e',
    };
  }
}

/// Giải mã tệp trong isolate
Future<Map<String, dynamic>> _decryptFileIsolate(Map<String, dynamic> params) async {
  final inputPath = params['inputPath'] as String;
  final outputPath = params['outputPath'] as String;
  final password = params['password'] as String;
  
  try {
    // Đọc tệp đã mã hóa
    final file = File(inputPath);
    final encryptedBytes = await file.readAsBytes();
    
    // Tạo khóa từ mật khẩu
    final keyBytes = _generateKey(password);
    
    // Giải mã dữ liệu
    final decryptedBytes = _decryptData(encryptedBytes, keyBytes);
    
    // Ghi tệp đã giải mã
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(decryptedBytes);
    
    return {
      'success': true,
      'outputPath': outputPath,
    };
  } catch (e) {
    return {
      'success': false,
      'error': 'Lỗi giải mã: $e',
    };
  }
}

/// Tạo khóa từ mật khẩu
Uint8List _generateKey(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return Uint8List.fromList(digest.bytes);
}

/// Mã hóa dữ liệu (triển khai đơn giản, trong thực tế nên sử dụng thư viện mã hóa mạnh mẽ hơn)
Uint8List _encryptData(Uint8List data, Uint8List key) {
  final result = Uint8List(data.length);
  
  for (var i = 0; i < data.length; i++) {
    result[i] = data[i] ^ key[i % key.length];
  }
  
  return result;
}

/// Giải mã dữ liệu
Uint8List _decryptData(Uint8List data, Uint8List key) {
  // Với phương pháp XOR, mã hóa và giải mã là cùng một hoạt động
  return _encryptData(data, key);
} 