import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Downloads and caches user/group avatars as local files for use in
/// OS-native notifications (Windows appLogoOverride, macOS attachment).
///
/// Cache strategy:
/// - Files stored in `<tempDir>/chat_notification_avatars/<userId_hash>.png`
/// - Each file reused across notifications until [clearCache] is called
/// - Download timeout: 3 seconds — if exceeded, returns `null` (notification
///   shows app icon instead)
class NotificationAvatarService {
  NotificationAvatarService({
    required AppLogger logger,
  }) : _logger = logger;

  static const Duration _downloadTimeout = Duration(seconds: 3);
  static const String _cacheSubDir = 'chat_notification_avatars';

  final AppLogger _logger;

  /// In-memory map of avatar URL → local file path.
  ///
  /// If the file still exists on disk, we skip re-downloading.
  final Map<String, String> _urlToPathCache = <String, String>{};

  /// Returns a local [File] path for the given avatar [url].
  ///
  /// - Returns cached path immediately if the file still exists.
  /// - Downloads and saves to temp directory if not cached.
  /// - Returns `null` on any failure (timeout, network error, invalid image).
  Future<String?> getAvatarFilePath(String? url) async {
    if (kIsWeb || url == null || url.trim().isEmpty) {
      return null;
    }

    // Check in-memory cache first.
    final String? cached = _urlToPathCache[url];
    if (cached != null && File(cached).existsSync()) {
      return cached;
    }

    try {
      final Directory cacheDir = await _ensureCacheDir();
      final String fileName = _urlToFileName(url);
      final String filePath = path.join(cacheDir.path, fileName);
      final File file = File(filePath);

      // Check disk cache (might have been downloaded in a previous session).
      if (file.existsSync() && file.lengthSync() > 0) {
        _urlToPathCache[url] = filePath;
        return filePath;
      }

      // Download with timeout.
      final http.Response response = await http
          .get(Uri.parse(url))
          .timeout(_downloadTimeout);

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        _logger.d(
          'Avatar download failed',
          <String, dynamic>{
            'url': url,
            'status': response.statusCode,
          },
        );
        return null;
      }

      await file.writeAsBytes(response.bodyBytes, flush: true);
      _urlToPathCache[url] = filePath;

      return filePath;
    } catch (error) {
      // Timeout, network error, file system error — all non-fatal.
      _logger.d(
        'Avatar download skipped',
        <String, dynamic>{
          'url': url,
          'error': error.toString(),
        },
      );
      return null;
    }
  }

  /// Clears all cached avatar files from disk and memory.
  Future<void> clearCache() async {
    _urlToPathCache.clear();
    try {
      final Directory cacheDir = await _ensureCacheDir();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (error) {
      _logger.d(
        'Failed to clear avatar cache',
        <String, dynamic>{'error': error.toString()},
      );
    }
  }

  Future<Directory> _ensureCacheDir() async {
    final Directory tempDir = await getTemporaryDirectory();
    final Directory cacheDir = Directory(
      path.join(tempDir.path, _cacheSubDir),
    );
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Converts a URL to a safe file name using its hashCode.
  String _urlToFileName(String url) {
    final int hash = url.hashCode & 0x7fffffff;
    return 'avatar_$hash.png';
  }
}
