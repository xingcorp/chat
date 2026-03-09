import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:injectable/injectable.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as p;

/// Data source for reading image data and file paths from the system clipboard.
///
/// Used for Ctrl+V / Cmd+V paste functionality in the chat input.
/// Supports:
/// - Image data paste (screenshot capture, copied image content)
/// - File path paste (Ctrl+C file(s) from OS file explorer)
///
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

  /// Read file paths from the clipboard (files copied via Ctrl+C in file explorer).
  ///
  /// Returns a list of existing file paths, or an empty list if none found.
  /// Supported on Windows (PowerShell), macOS (osascript), and Linux (xclip).
  /// Not supported on web.
  Future<List<String>> getFilePathsFromClipboard() async {
    LogUtils.d('PASTE_DEBUG', '>>> getFilePathsFromClipboard() called');
    LogUtils.d('PASTE_DEBUG', '>>> kIsWeb=$kIsWeb, Platform.isWindows=${!kIsWeb ? Platform.isWindows : "N/A"}, Platform.isMacOS=${!kIsWeb ? Platform.isMacOS : "N/A"}');

    if (kIsWeb) {
      LogUtils.d('PASTE_DEBUG', '>>> Web platform — returning empty');
      return [];
    }

    try {
      List<String> paths = [];

      if (Platform.isWindows) {
        LogUtils.d('PASTE_DEBUG', '>>> Calling _getWindowsClipboardFiles()...');
        paths = await _getWindowsClipboardFiles();
        LogUtils.d('PASTE_DEBUG', '>>> _getWindowsClipboardFiles() returned ${paths.length} raw paths: $paths');
      } else if (Platform.isMacOS) {
        paths = await _getMacOSClipboardFiles();
      } else if (Platform.isLinux) {
        paths = await _getLinuxClipboardFiles();
      }

      // Filter to only existing files (not directories)
      final validPaths = <String>[];
      for (final filePath in paths) {
        final trimmed = filePath.trim();
        if (trimmed.isEmpty) continue;
        try {
          final file = File(trimmed);
          final exists = await file.exists();
          final isDir = await FileSystemEntity.isDirectory(trimmed);
          LogUtils.d('PASTE_DEBUG', '>>> Checking path: "$trimmed" → exists=$exists, isDir=$isDir');
          if (exists && !isDir) {
            validPaths.add(trimmed);
          }
        } catch (e) {
          LogUtils.d('PASTE_DEBUG', '>>> Path check error for "$trimmed": $e');
        }
      }

      LogUtils.d('PASTE_DEBUG', '>>> Final validPaths: ${validPaths.length} paths: $validPaths');

      if (validPaths.isNotEmpty) {
        _logger.debug('ClipboardDataSource: Read files from clipboard', {
          'count': validPaths.length,
          'files': validPaths.map((f) => p.basename(f)).toList(),
        });
      }

      return validPaths;
    } catch (e, stack) {
      LogUtils.e('PASTE_DEBUG', '>>> getFilePathsFromClipboard EXCEPTION: $e\n$stack');
      _logger.warning(
        'ClipboardDataSource: Failed to read clipboard files',
        {'error': e.toString()},
      );
      return [];
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

  // ═══════════════════════════════════════════
  // Platform-specific clipboard file readers
  // ═══════════════════════════════════════════

  /// Windows: Use PowerShell to read CF_HDROP (file drop list) from clipboard.
  ///
  /// `Get-Clipboard -Format FileDropList` returns FileInfo objects.
  /// We access `.FullName` to extract just the full file paths (one per line),
  /// instead of the default formatted table output.
  Future<List<String>> _getWindowsClipboardFiles() async {
    try {
      // (Get-Clipboard -Format FileDropList).FullName returns raw paths,
      // one per line. Returns nothing (empty) if clipboard has no files.
      const command = '(Get-Clipboard -Format FileDropList).FullName';

      LogUtils.d('PASTE_DEBUG', '>>> Running PowerShell: $command');

      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-Command', command],
        stdoutEncoding: const SystemEncoding(),
      );

      LogUtils.d('PASTE_DEBUG', '>>> PowerShell exitCode=${result.exitCode}');
      LogUtils.d('PASTE_DEBUG', '>>> PowerShell stdout="${result.stdout}"');
      LogUtils.d('PASTE_DEBUG', '>>> PowerShell stderr="${result.stderr}"');

      if (result.exitCode != 0 || result.stdout == null) {
        LogUtils.d('PASTE_DEBUG', '>>> PowerShell failed or null stdout');
        return [];
      }

      final output = result.stdout.toString().trim();
      LogUtils.d('PASTE_DEBUG', '>>> PowerShell trimmed output="${output}" (length=${output.length})');

      if (output.isEmpty) {
        LogUtils.d('PASTE_DEBUG', '>>> PowerShell output is empty — no files in clipboard');
        return [];
      }

      // PowerShell returns one file path per line
      final lines = output
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      LogUtils.d('PASTE_DEBUG', '>>> PowerShell parsed ${lines.length} lines: $lines');

      return lines;
    } catch (e, stack) {
      LogUtils.e('PASTE_DEBUG', '>>> PowerShell EXCEPTION: $e\n$stack');
      _logger.debug('ClipboardDataSource: PowerShell clipboard read failed', {
        'error': e.toString(),
      });
      return [];
    }
  }

  /// macOS: Use osascript to read file paths from clipboard (Finder copy).
  Future<List<String>> _getMacOSClipboardFiles() async {
    try {
      // Get clipboard content as file URL(s)
      final result = await Process.run(
        'osascript',
        [
          '-e',
          'try\n'
              '  set theFiles to (the clipboard as «class furl»)\n'
              '  return POSIX path of theFiles\n'
              'on error\n'
              '  try\n'
              '    set theFiles to the clipboard as list\n'
              '    set output to ""\n'
              '    repeat with f in theFiles\n'
              '      set output to output & POSIX path of f & linefeed\n'
              '    end repeat\n'
              '    return output\n'
              '  on error\n'
              '    return ""\n'
              '  end try\n'
              'end try',
        ],
      );

      if (result.exitCode != 0 || result.stdout == null) return [];

      final output = result.stdout.toString().trim();
      if (output.isEmpty) return [];

      return output
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (e) {
      _logger.debug('ClipboardDataSource: osascript clipboard read failed', {
        'error': e.toString(),
      });
      return [];
    }
  }

  /// Linux: Use xclip to read file URIs from clipboard.
  Future<List<String>> _getLinuxClipboardFiles() async {
    try {
      // Try to read clipboard as URI list (file manager copy format)
      final result = await Process.run(
        'xclip',
        ['-selection', 'clipboard', '-t', 'text/uri-list', '-o'],
      );

      if (result.exitCode != 0 || result.stdout == null) return [];

      final output = result.stdout.toString().trim();
      if (output.isEmpty) return [];

      // URI list format: file:///path/to/file
      return output
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.startsWith('file://'))
          .map((uri) => Uri.parse(uri).toFilePath())
          .toList();
    } catch (e) {
      _logger.debug('ClipboardDataSource: xclip clipboard read failed', {
        'error': e.toString(),
      });
      return [];
    }
  }
}
