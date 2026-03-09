import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/usecases/file/upload_attachment_usecase.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service for writing clipboard/web file bytes to temporary files for upload.
///
/// Implements [ITempFileWriter] from domain layer.
/// On web, this service is a no-op (web uploads use bytes directly).
@LazySingleton(as: ITempFileWriter)
class TempFileService implements ITempFileWriter {
  final AppLogger _logger;

  /// Directory for temp files — lazily initialized
  Directory? _tempDir;

  TempFileService({required AppLogger logger}) : _logger = logger;

  /// Get or create the temp directory for file uploads
  Future<Directory> _getTempDir() async {
    if (_tempDir != null) return _tempDir!;

    if (kIsWeb) {
      throw UnsupportedError(
        'TempFileService: Temp file operations not supported on web',
      );
    }

    final systemTemp = await getTemporaryDirectory();
    _tempDir = Directory(p.join(systemTemp.path, 'chat_uploads'));
    if (!_tempDir!.existsSync()) {
      await _tempDir!.create(recursive: true);
    }
    return _tempDir!;
  }

  /// Write [bytes] to a temp file with the given [fileName].
  ///
  /// Returns the absolute path to the created file.
  @override
  Future<String> writeTempFile(Uint8List bytes, String fileName) async {
    final dir = await _getTempDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = '${timestamp}_$fileName';
    final file = File(p.join(dir.path, safeName));

    await file.writeAsBytes(bytes, flush: true);

    _logger.debug('TempFileService: Wrote temp file', {
      'path': file.path,
      'size': bytes.length,
    });

    return file.path;
  }

  /// Delete a specific temp file by [path].
  @override
  Future<void> cleanupTempFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _logger.debug('TempFileService: Deleted temp file', {'path': path});
      }
    } catch (e) {
      _logger.warning(
        'TempFileService: Failed to delete temp file',
        {'path': path, 'error': e.toString()},
      );
    }
  }

  /// Delete all temp files in the upload directory.
  Future<void> cleanupAll() async {
    try {
      if (kIsWeb) return;

      final dir = await _getTempDir();
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            await entity.delete();
          }
        }
        _logger.info('TempFileService: Cleaned up all temp files', {
          'count': entities.length,
        });
      }
    } catch (e) {
      _logger.warning(
        'TempFileService: Failed to cleanup all temp files',
        {'error': e.toString()},
      );
    }
  }
}
