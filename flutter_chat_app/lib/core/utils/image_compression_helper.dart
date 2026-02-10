import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Helper class for compressing images before upload
///
/// Features:
/// - Compress images to reduce file size
/// - Maintain reasonable quality (80%)
/// - Generate temp file paths
/// - Handle compression errors gracefully
class ImageCompressionHelper {
  /// Maximum image width after compression
  static const int maxWidth = 1920;

  /// Maximum image height after compression
  static const int maxHeight = 1920;

  /// Compression quality (0-100)
  static const int quality = 80;

  /// Compress an image file to reduce size
  ///
  /// Returns compressed file or original if compression fails/not needed
  static Future<File?> compressImage(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        return null;
      }

      // Get file size
      final fileSize = await imageFile.length();

      // Skip compression if file is already small (<500KB)
      if (fileSize < 500 * 1024) {
        return imageFile;
      }

      // Get temp directory for output
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}',
      );

      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: _getCompressFormat(imageFile.path),
      );

      if (compressedFile == null) {
        return imageFile; // Return original if compression fails
      }

      // Check if compression actually reduced size
      final compressedSize = await File(compressedFile.path).length();
      if (compressedSize >= fileSize) {
        // Compression didn't help, delete compressed file and return original
        await File(compressedFile.path).delete();
        return imageFile;
      }

      return File(compressedFile.path);
    } catch (e) {
      // Return original file if compression fails
      return imageFile;
    }
  }

  /// Compress multiple images in parallel
  static Future<List<File>> compressImages(List<File> imageFiles) async {
    final results = await Future.wait(
      imageFiles.map((file) => compressImage(file)),
    );

    return results.whereType<File>().toList();
  }

  /// Get compression format based on file extension
  static CompressFormat _getCompressFormat(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return CompressFormat.jpeg;
      case '.png':
        return CompressFormat.png;
      case '.webp':
        return CompressFormat.webp;
      case '.heic':
        return CompressFormat.heic;
      default:
        return CompressFormat.jpeg;
    }
  }

  /// Calculate compressed file size estimate
  static Future<int> estimateCompressedSize(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      if (fileSize < 500 * 1024) {
        return fileSize; // No compression needed
      }

      // Rough estimate: 30-50% reduction with quality 80
      return (fileSize * 0.6).round();
    } catch (e) {
      return 0;
    }
  }

  /// Check if file needs compression
  static Future<bool> needsCompression(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      return fileSize >= 500 * 1024; // >500KB
    } catch (e) {
      return false;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
