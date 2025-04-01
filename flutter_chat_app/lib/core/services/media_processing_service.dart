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

/// Service factory để tạo implementation phù hợp với từng nền tảng
@lazySingleton
class MediaProcessingServiceFactory {
  /// Tạo instance phù hợp cho từng nền tảng
  static IMediaProcessingService create() {
    if (kIsWeb) {
      return WebMediaProcessingService();
    } else if (Platform.isIOS || Platform.isAndroid) {
      return MobileMediaProcessingService();
    } else {
      return DesktopMediaProcessingService();
    }
  }
}

/// Interface định nghĩa các phương thức xử lý media
abstract class IMediaProcessingService {
  /// Khởi tạo service
  Future<void> initialize();
  
  /// Nén hình ảnh
  Future<MediaProcessingResult> compressImage({
    required dynamic imageInput,
    int quality = 80,
    bool preserveExif = false,
  });
  
  /// Thay đổi kích thước hình ảnh
  Future<MediaProcessingResult> resizeImage({
    required dynamic imageInput, 
    required int width,
    required int height,
    bool maintainAspectRatio = true,
  });
  
  /// Áp dụng bộ lọc hình ảnh
  Future<MediaProcessingResult> applyImageFilter({
    required dynamic imageInput,
    required String filterType,
  });
  
  /// Cắt hình ảnh
  Future<MediaProcessingResult> cropImage({
    required dynamic imageInput,
    required int x,
    required int y,
    required int width,
    required int height,
  });
  
  /// Tạo đường dẫn tệp tạm thời
  String generateTempFilePath({String extension = '.tmp'});
}

/// Base class với các phương thức chung
abstract class BaseMediaProcessingService implements IMediaProcessingService {
  /// Biến cho việc tạo UUID
  final _uuid = Uuid();
  
  @override
  String generateTempFilePath({String extension = '.tmp'}) {
    return 'temp_${_uuid.v4()}$extension';
  }
}

/// Cài đặt cho mobile (Android, iOS)
class MobileMediaProcessingService extends BaseMediaProcessingService {
  /// Thư mục tạm để lưu các tệp xử lý
  late final Directory _tempDir;

  @override
  Future<void> initialize() async {
    try {
      _tempDir = await getTemporaryDirectory();
      debugPrint('MobileMediaProcessingService đã khởi tạo thành công');
      debugPrint('Thư mục tạm: ${_tempDir.path}');
    } catch (e) {
      debugPrint('Lỗi khởi tạo MobileMediaProcessingService: $e');
      rethrow;
    }
  }
  
  @override
  Future<MediaProcessingResult> compressImage({
    required dynamic imageInput,
    int quality = 80,
    bool preserveExif = false,
  }) async {
    final imageFile = imageInput as File;
    final stopwatch = Stopwatch()..start();
    
    try {
      // Tạo đường dẫn tệp đích
      final outputPath = '${_tempDir.path}/${generateTempFilePath(extension: '.jpg')}';
      
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
  
  @override
  Future<MediaProcessingResult> resizeImage({
    required dynamic imageInput, 
    required int width,
    required int height,
    bool maintainAspectRatio = true,
  }) async {
    final imageFile = imageInput as File;
    final stopwatch = Stopwatch()..start();
    
    try {
      final outputPath = '${_tempDir.path}/${generateTempFilePath(extension: '.jpg')}';
      
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
  
  @override
  Future<MediaProcessingResult> cropImage({
    required dynamic imageInput,
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    final imageFile = imageInput as File;
    final stopwatch = Stopwatch()..start();
    
    try {
      final outputPath = '${_tempDir.path}/${generateTempFilePath(extension: '.jpg')}';
      
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
  
  @override
  Future<MediaProcessingResult> applyImageFilter({
    required dynamic imageInput,
    required String filterType,
  }) async {
    final imageFile = imageInput as File;
    final stopwatch = Stopwatch()..start();
    
    try {
      final outputPath = '${_tempDir.path}/${generateTempFilePath(extension: '.jpg')}';
      
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
}

/// Cài đặt cho web
class WebMediaProcessingService extends BaseMediaProcessingService {
  @override
  Future<void> initialize() async {
    debugPrint('WebMediaProcessingService đã khởi tạo thành công');
  }
  
  @override
  Future<MediaProcessingResult> compressImage({
    required dynamic imageInput,
    int quality = 80,
    bool preserveExif = false,
  }) async {
    final Uint8List imageBytes = imageInput is Uint8List 
        ? imageInput 
        : await (imageInput as File).readAsBytes();
    final stopwatch = Stopwatch()..start();
    
    try {
      // Xử lý trực tiếp trong main thread vì web không hỗ trợ isolate
      final result = _compressImageWeb(imageBytes, quality);
      
      stopwatch.stop();
      return MediaProcessingResult.success(
        outputBytes: result,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('Lỗi nén hình ảnh web: $e');
      return MediaProcessingResult.error(
        error: 'Không thể nén hình ảnh trên web: $e',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  
  @override
  Future<MediaProcessingResult> resizeImage({
    required dynamic imageInput, 
    required int width,
    required int height,
    bool maintainAspectRatio = true,
  }) async {
    final Uint8List imageBytes = imageInput is Uint8List 
        ? imageInput 
        : await (imageInput as File).readAsBytes();
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = _resizeImageWeb(imageBytes, width, height, maintainAspectRatio);
      
      stopwatch.stop();
      return MediaProcessingResult.success(
        outputBytes: result,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return MediaProcessingResult.error(
        error: 'Không thể thay đổi kích thước hình ảnh trên web: $e',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  
  @override
  Future<MediaProcessingResult> cropImage({
    required dynamic imageInput,
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    final Uint8List imageBytes = imageInput is Uint8List 
        ? imageInput 
        : await (imageInput as File).readAsBytes();
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = _cropImageWeb(imageBytes, x, y, width, height);
      
      stopwatch.stop();
      return MediaProcessingResult.success(
        outputBytes: result,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return MediaProcessingResult.error(
        error: 'Không thể cắt hình ảnh trên web: $e',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  
  @override
  Future<MediaProcessingResult> applyImageFilter({
    required dynamic imageInput,
    required String filterType,
  }) async {
    final Uint8List imageBytes = imageInput is Uint8List 
        ? imageInput 
        : await (imageInput as File).readAsBytes();
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = _applyImageFilterWeb(imageBytes, filterType);
      
      stopwatch.stop();
      return MediaProcessingResult.success(
        outputBytes: result,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return MediaProcessingResult.error(
        error: 'Không thể áp dụng bộ lọc hình ảnh trên web: $e',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  
  /// Nén hình ảnh web
  Uint8List _compressImageWeb(Uint8List bytes, int quality) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Không thể decode hình ảnh');
    
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }
  
  /// Thay đổi kích thước hình ảnh web
  Uint8List _resizeImageWeb(Uint8List bytes, int width, int height, bool maintainAspectRatio) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Không thể decode hình ảnh');
    
    final resized = maintainAspectRatio
        ? img.copyResize(image, width: width, height: height, interpolation: img.Interpolation.linear)
        : img.copyResizeCropSquare(image, size: width);
    
    return Uint8List.fromList(img.encodeJpg(resized));
  }
  
  /// Cắt hình ảnh web
  Uint8List _cropImageWeb(Uint8List bytes, int x, int y, int width, int height) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Không thể decode hình ảnh');
    
    final cropped = img.copyCrop(image, x: x, y: y, width: width, height: height);
    
    return Uint8List.fromList(img.encodeJpg(cropped));
  }
  
  /// Áp dụng bộ lọc hình ảnh web
  Uint8List _applyImageFilterWeb(Uint8List bytes, String filterType) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Không thể decode hình ảnh');
    
    img.Image filtered;
    switch (filterType) {
      case 'grayscale':
        filtered = img.grayscale(image);
        break;
      case 'sepia':
        filtered = img.sepia(image);
        break;
      case 'invert':
        filtered = img.invert(image);
        break;
      default:
        filtered = image;
    }
    
    return Uint8List.fromList(img.encodeJpg(filtered));
  }
}

/// Cài đặt cho desktop (Windows, macOS, Linux)
class DesktopMediaProcessingService extends BaseMediaProcessingService {
  /// Thư mục tạm để lưu các tệp xử lý
  late final Directory _tempDir;
  
  @override
  Future<void> initialize() async {
    try {
      _tempDir = await getTemporaryDirectory();
      debugPrint('DesktopMediaProcessingService đã khởi tạo thành công');
      debugPrint('Thư mục tạm: ${_tempDir.path}');
    } catch (e) {
      debugPrint('Lỗi khởi tạo DesktopMediaProcessingService: $e');
      rethrow;
    }
  }
  
  // Cài đặt các phương thức tương tự như trong MobileMediaProcessingService
  // Có thể tận dụng lại phần lớn mã
  @override
  Future<MediaProcessingResult> compressImage({
    required dynamic imageInput,
    int quality = 80,
    bool preserveExif = false,
  }) async {
    final imageFile = imageInput as File;
    final stopwatch = Stopwatch()..start();
    
    try {
      // Tạo đường dẫn tệp đích
      final outputPath = '${_tempDir.path}/${generateTempFilePath(extension: '.jpg')}';
      
      // Desktop có thể sử dụng compute isolate như mobile
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
  
  @override
  Future<MediaProcessingResult> resizeImage({
    required dynamic imageInput, 
    required int width,
    required int height,
    bool maintainAspectRatio = true,
  }) async {
    final imageFile = imageInput as File;
    final stopwatch = Stopwatch()..start();
    
    try {
      final outputPath = '${_tempDir.path}/${generateTempFilePath(extension: '.jpg')}';
      
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
  
  @override
  Future<MediaProcessingResult> cropImage({
    required dynamic imageInput,
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    final imageFile = imageInput as File;
    final stopwatch = Stopwatch()..start();
    
    try {
      final outputPath = '${_tempDir.path}/${generateTempFilePath(extension: '.jpg')}';
      
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
  
  @override
  Future<MediaProcessingResult> applyImageFilter({
    required dynamic imageInput,
    required String filterType,
  }) async {
    final imageFile = imageInput as File;
    final stopwatch = Stopwatch()..start();
    
    try {
      final outputPath = '${_tempDir.path}/${generateTempFilePath(extension: '.jpg')}';
      
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
}

/// Class cũ giữ lại để tương thích - facade pattern
@lazySingleton
class MediaProcessingService implements IMediaProcessingService {
  final IMediaProcessingService _implementation;
  
  MediaProcessingService() : _implementation = MediaProcessingServiceFactory.create();
  
  @override
  Future<void> initialize() => _implementation.initialize();
  
  @override
  Future<MediaProcessingResult> compressImage({
    required dynamic imageInput,
    int quality = 80,
    bool preserveExif = false,
  }) => _implementation.compressImage(
    imageInput: imageInput,
    quality: quality,
    preserveExif: preserveExif,
  );
  
  @override
  Future<MediaProcessingResult> resizeImage({
    required dynamic imageInput,
    required int width, 
    required int height,
    bool maintainAspectRatio = true,
  }) => _implementation.resizeImage(
    imageInput: imageInput,
    width: width,
    height: height,
    maintainAspectRatio: maintainAspectRatio,
  );
  
  @override
  Future<MediaProcessingResult> cropImage({
    required dynamic imageInput,
    required int x,
    required int y,
    required int width,
    required int height,
  }) => _implementation.cropImage(
    imageInput: imageInput,
    x: x,
    y: y,
    width: width,
    height: height,
  );
  
  @override
  Future<MediaProcessingResult> applyImageFilter({
    required dynamic imageInput,
    required String filterType,
  }) => _implementation.applyImageFilter(
    imageInput: imageInput,
    filterType: filterType,
  );
  
  @override
  String generateTempFilePath({String extension = '.tmp'}) => 
    _implementation.generateTempFilePath(extension: extension);
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