import 'dart:typed_data';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/usecases/message/upload_file_usecase.dart';
import 'package:injectable/injectable.dart';

/// Abstract interface for temp file operations.
///
/// Domain layer defines the contract; Data layer provides implementation.
abstract class ITempFileWriter {
  /// Write bytes to a temporary file, returning the path
  Future<String> writeTempFile(Uint8List bytes, String fileName);

  /// Cleanup a temporary file
  Future<void> cleanupTempFile(String path);
}

/// Parameters for uploading an attachment
class UploadAttachmentParams {
  /// Local ID for tracking (PendingFile.localId)
  final String localId;

  /// File path on disk (desktop/mobile)
  final String? filePath;

  /// File bytes in memory (web / clipboard paste)
  final Uint8List? bytes;

  /// Original file name
  final String fileName;

  /// MIME type
  final String mimeType;

  /// Progress callback: receives progress 0.0 to 1.0
  final void Function(double progress)? onProgress;

  const UploadAttachmentParams({
    required this.localId,
    this.filePath,
    this.bytes,
    required this.fileName,
    required this.mimeType,
    this.onProgress,
  });
}

/// Uploads a file attachment to the server.
///
/// Wraps [UploadFileUseCase] to handle both file-path and bytes-based uploads.
/// For bytes-based uploads (web/clipboard), writes to a temp file first,
/// then delegates to the existing presigned URL upload flow.
@injectable
class UploadAttachmentUseCase {
  final UploadFileUseCase _uploadFileUseCase;
  final ITempFileWriter _tempFileWriter;
  final AppLogger _logger;

  UploadAttachmentUseCase({
    required UploadFileUseCase uploadFileUseCase,
    required ITempFileWriter tempFileWriter,
    required AppLogger logger,
  })  : _uploadFileUseCase = uploadFileUseCase,
        _tempFileWriter = tempFileWriter,
        _logger = logger;

  /// Execute the upload.
  ///
  /// Returns [UploadFileResult] on success, [Failure] on error.
  /// Cleans up temp files automatically on completion.
  Future<Either<Failure, UploadFileResult>> call(
    UploadAttachmentParams params,
  ) async {
    _logger.info('UploadAttachmentUseCase: Starting upload', {
      'localId': params.localId,
      'fileName': params.fileName,
      'hasPath': params.filePath != null,
      'hasBytes': params.bytes != null,
    });

    String? tempFilePath;

    try {
      // Determine file path — if bytes-only (web/clipboard), write temp file
      final String uploadPath;
      if (params.filePath != null) {
        uploadPath = params.filePath!;
      } else if (params.bytes != null) {
        tempFilePath = await _tempFileWriter.writeTempFile(
          params.bytes!,
          params.fileName,
        );
        uploadPath = tempFilePath;
      } else {
        return const Left(
          ValidationFailure(
            message: 'No file data provided (neither path nor bytes)',
            code: 'no_file_data',
          ),
        );
      }

      // Delegate to existing upload flow (presigned URL)
      final result = await _uploadFileUseCase.call(
        filePath: uploadPath,
        onProgress: params.onProgress != null
            ? (count, total) {
                if (total > 0) {
                  params.onProgress!(count / total);
                }
              }
            : null,
      );

      return result;
    } catch (e, stackTrace) {
      _logger.error(
        'UploadAttachmentUseCase: Unexpected error',
        e,
        stackTrace,
      );
      return Left(
        UnexpectedFailure(message: 'Upload failed: ${e.toString()}'),
      );
    } finally {
      // Cleanup temp file if we created one
      if (tempFilePath != null) {
        try {
          await _tempFileWriter.cleanupTempFile(tempFilePath);
        } catch (e) {
          _logger.warning(
            'UploadAttachmentUseCase: Failed to cleanup temp file',
            {'path': tempFilePath, 'error': e.toString()},
          );
        }
      }
    }
  }
}
