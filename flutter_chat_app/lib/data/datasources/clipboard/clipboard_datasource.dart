import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:injectable/injectable.dart';
import 'package:pasteboard/pasteboard.dart';

/// Data source for reading image data from the system clipboard.
///
/// Used for Ctrl+V / Cmd+V paste functionality in the chat input.
/// Only active on web and desktop platforms.
@LazySingleton()
class ClipboardDataSource {
  final AppLogger _logger;

  ClipboardDataSource({required AppLogger logger}) : _logger = logger;

  /// Read image data from the clipboard.
  ///
  /// Returns bytes and a generated filename, or null if no image is available.
  Future<({Uint8List bytes, String fileName})?> getImageFromClipboard() async {
    try {
      if (!_isSupported) return null;

      final imageBytes = await Pasteboard.image;
      if (imageBytes == null || imageBytes.isEmpty) {
        return null;
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'pasted_image_$timestamp.png';

      _logger.debug('ClipboardDataSource: Read image from clipboard', {
        'size': imageBytes.length,
        'fileName': fileName,
      });

      return (bytes: imageBytes, fileName: fileName);
    } catch (e) {
      _logger.warning(
        'ClipboardDataSource: Failed to read clipboard image',
        {'error': e.toString()},
      );
      return null;
    }
  }

  /// Check if the clipboard currently contains image data.
  Future<bool> hasImageData() async {
    try {
      if (!_isSupported) return false;

      final imageBytes = await Pasteboard.image;
      return imageBytes != null && imageBytes.isNotEmpty;
    } catch (e) {
      _logger.warning(
        'ClipboardDataSource: Failed to check clipboard',
        {'error': e.toString()},
      );
      return false;
    }
  }

  /// Whether clipboard image reading is supported on the current platform.
  bool get _isSupported {
    if (kIsWeb) return true;
    // pasteboard supports macOS, Windows, Linux
    return true;
  }
}
