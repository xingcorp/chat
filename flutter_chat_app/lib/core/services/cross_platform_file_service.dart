import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';

/// Cross-platform file data container
///
/// Holds file information for both mobile (path-based) and web (bytes-based) platforms.
/// This abstraction allows the rest of the app to work with files without
/// worrying about platform-specific implementations.
class CrossPlatformFile {
  /// File name with extension
  final String name;

  /// File extension (lowercase, without dot)
  final String extension;

  /// File size in bytes
  final int size;

  /// File path (mobile/desktop only, null on web)
  final String? path;

  /// File bytes (web only, null on mobile)
  final Uint8List? bytes;

  /// MIME type
  final String mimeType;

  /// Whether this file has bytes available (web platform)
  bool get hasBytes => bytes != null;

  /// Whether this file has a path available (mobile platform)
  bool get hasPath => path != null;

  const CrossPlatformFile({
    required this.name,
    required this.extension,
    required this.size,
    this.path,
    this.bytes,
    required this.mimeType,
  });

  /// Create from path (mobile)
  factory CrossPlatformFile.fromPath({
    required String path,
    required int size,
    String? mimeType,
  }) {
    final name = path.split('/').last.split('\\').last;
    final ext = name.split('.').last.toLowerCase();
    return CrossPlatformFile(
      name: name,
      extension: ext,
      size: size,
      path: path,
      mimeType: mimeType ?? _getMimeType(ext),
    );
  }

  /// Create from bytes (web)
  factory CrossPlatformFile.fromBytes({
    required String name,
    required Uint8List bytes,
    String? mimeType,
  }) {
    final ext = name.split('.').last.toLowerCase();
    return CrossPlatformFile(
      name: name,
      extension: ext,
      size: bytes.length,
      bytes: bytes,
      mimeType: mimeType ?? _getMimeType(ext),
    );
  }

  /// Get MIME type from extension
  static String _getMimeType(String extension) {
    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';

      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'zip':
        return 'application/zip';

      default:
        return 'application/octet-stream';
    }
  }

  /// Get message type for chat
  String get messageType {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'heic':
      case 'heif':
        return 'image';
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'webm':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'ogg':
        return 'audio';
      default:
        return 'file';
    }
  }
}

/// Service for handling files across platforms (mobile/web)
///
/// This service abstracts away the differences between:
/// - Mobile: dart:io File operations with paths
/// - Web: Uint8List bytes operations (no dart:io)
///
/// Usage:
/// ```dart
/// // Get file info (works on both platforms)
/// final fileInfo = await fileService.getFileInfo(file: file, bytes: bytes, name: name);
///
/// // Read file bytes (works on both platforms)
/// final bytes = await fileService.readFileBytes(file: file, bytes: bytes);
/// ```
@LazySingleton()
class CrossPlatformFileService {
  /// Get file information from either File (mobile) or bytes (web)
  ///
  /// On mobile: extracts info from File.path and File.length()
  /// On web: uses provided bytes and name directly
  Future<CrossPlatformFile> getFileInfo({
    File? file,
    Uint8List? bytes,
    String? name,
  }) async {
    if (kIsWeb) {
      if (bytes == null || name == null) {
        throw ArgumentError('Web platform requires bytes and name');
      }
      return CrossPlatformFile.fromBytes(name: name, bytes: bytes);
    } else {
      if (file == null) {
        throw ArgumentError('Mobile platform requires file');
      }
      final exists = await file.exists();
      if (!exists) {
        throw ArgumentError('File does not exist: ${file.path}');
      }
      final size = await file.length();
      return CrossPlatformFile.fromPath(path: file.path, size: size);
    }
  }

  /// Read file bytes from either File (mobile) or return provided bytes (web)
  ///
  /// On mobile: reads bytes from File.readAsBytes()
  /// On web: returns the provided bytes directly
  Future<Uint8List> readFileBytes({
    File? file,
    Uint8List? bytes,
  }) async {
    if (kIsWeb) {
      if (bytes == null) {
        throw ArgumentError('Web platform requires bytes');
      }
      return bytes;
    } else {
      if (file == null) {
        throw ArgumentError('Mobile platform requires file');
      }
      return await file.readAsBytes();
    }
  }

  /// Check if file exists (mobile) or bytes are available (web)
  Future<bool> fileExists({
    File? file,
    Uint8List? bytes,
  }) async {
    if (kIsWeb) {
      return bytes != null && bytes.isNotEmpty;
    } else {
      if (file == null) return false;
      return await file.exists();
    }
  }

  /// Get file size from either File (mobile) or bytes (web)
  Future<int> getFileSize({
    File? file,
    Uint8List? bytes,
  }) async {
    if (kIsWeb) {
      return bytes?.length ?? 0;
    } else {
      if (file == null) return 0;
      if (!await file.exists()) return 0;
      return await file.length();
    }
  }

  /// Extract file name from path (mobile) or return provided name (web)
  String getFileName({
    File? file,
    String? name,
  }) {
    if (kIsWeb) {
      return name ?? 'unknown_file';
    } else {
      if (file == null) return 'unknown_file';
      return file.path.split('/').last.split('\\').last;
    }
  }
}
