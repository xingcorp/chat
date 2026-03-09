import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

/// Service for validating file attributes before upload.
///
/// Handles MIME type detection, extension validation, size checking,
/// and human-readable file size formatting.
@LazySingleton()
class FileValidationService {
  /// Allowed image extensions
  static const Set<String> allowedImageExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif',
  };

  /// Allowed video extensions
  static const Set<String> allowedVideoExtensions = {
    '.mp4', '.mov', '.avi', '.mkv', '.webm',
  };

  /// Allowed audio extensions
  static const Set<String> allowedAudioExtensions = {
    '.mp3', '.wav', '.ogg', '.m4a', '.aac',
  };

  /// Allowed document extensions
  static const Set<String> allowedDocExtensions = {
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    '.txt', '.csv', '.json', '.xml',
  };

  /// Allowed archive extensions
  static const Set<String> allowedArchiveExtensions = {
    '.zip', '.rar', '.7z',
  };

  /// All allowed extensions combined
  static final Set<String> allAllowedExtensions = {
    ...allowedImageExtensions,
    ...allowedVideoExtensions,
    ...allowedAudioExtensions,
    ...allowedDocExtensions,
    ...allowedArchiveExtensions,
  };

  /// Detect [AttachmentType] from file name and MIME type.
  AttachmentType detectType(String fileName, String mimeType) {
    final extension = p.extension(fileName).toLowerCase();

    // Try extension first
    if (allowedImageExtensions.contains(extension)) {
      return AttachmentType.image;
    }
    if (allowedVideoExtensions.contains(extension)) {
      return AttachmentType.video;
    }
    if (allowedAudioExtensions.contains(extension)) {
      return AttachmentType.audio;
    }
    if (allowedDocExtensions.contains(extension) ||
        allowedArchiveExtensions.contains(extension)) {
      return AttachmentType.document;
    }

    // Fallback to MIME type prefix
    final mimePrefix = mimeType.split('/').first;
    switch (mimePrefix) {
      case 'image':
        return AttachmentType.image;
      case 'video':
        return AttachmentType.video;
      case 'audio':
        return AttachmentType.audio;
      default:
        return AttachmentType.document;
    }
  }

  /// Check if the file type is allowed.
  ///
  /// Currently all file types are allowed for upload.
  /// The extension/MIME sets above are used only for [detectType] categorization.
  bool isAllowedType(String fileName, String mimeType) {
    return true;
  }

  /// Check if the file size is within the allowed limit.
  bool isWithinSizeLimit(int sizeBytes) {
    return sizeBytes > 0 && sizeBytes <= AppConstants.kMaxAttachmentSize;
  }

  /// Format file size to human-readable string.
  ///
  /// Examples: "456 B", "12.3 KB", "2.3 MB", "1.0 GB"
  String formatFileSize(int bytes) {
    if (bytes < 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    if (unitIndex == 0) {
      return '${size.toInt()} ${units[unitIndex]}';
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
