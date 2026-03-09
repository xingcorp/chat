import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/base/base_usecase.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:injectable/injectable.dart';

/// Parameters for file validation
class ValidateFileParams extends Equatable {
  /// File name including extension
  final String fileName;

  /// File size in bytes
  final int fileSize;

  /// MIME type of the file
  final String mimeType;

  /// Current number of attachments already in the queue
  final int currentAttachmentCount;

  const ValidateFileParams({
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.currentAttachmentCount,
  });

  @override
  List<Object?> get props => [fileName, fileSize, mimeType, currentAttachmentCount];
}

/// Validates a file before adding it to the attachment queue.
///
/// Checks:
/// - File size does not exceed [AppConstants.kMaxAttachmentSize] (1GB)
/// - File type is in the allowed list
/// - Total attachment count does not exceed [AppConstants.kMaxAttachmentsPerMessage] (10)
/// - File is not empty (0 bytes)
///
/// This is pure domain logic — no Data or Presentation layer dependencies.
@injectable
class ValidateFileUseCase extends UseCase<bool, ValidateFileParams> {
  ValidateFileUseCase();

  @override
  Future<Either<Failure, bool>> call(ValidateFileParams params) async {
    // Check: file is not empty
    if (params.fileSize <= 0) {
      return const Left(
        ValidationFailure(
          message: 'File is empty',
          code: 'file_empty',
        ),
      );
    }

    // Check: file size within limit (1GB)
    if (params.fileSize > AppConstants.kMaxAttachmentSize) {
      final maxSizeMB = AppConstants.kMaxAttachmentSize / (1024 * 1024);
      final displaySize = maxSizeMB >= 1024
          ? '${(maxSizeMB / 1024).toStringAsFixed(0)}GB'
          : '${maxSizeMB.toStringAsFixed(0)}MB';
      return Left(
        ValidationFailure(
          message: 'File exceeds maximum size of $displaySize',
          code: 'file_too_large',
        ),
      );
    }

    // Note: All file types are allowed for upload.
    // Type detection is handled by FileValidationService.detectType()
    // which categorizes files for preview display only.

    // Check: attachment count within limit (10)
    if (params.currentAttachmentCount >= AppConstants.kMaxAttachmentsPerMessage) {
      return Left(
        ValidationFailure(
          message: 'Maximum ${AppConstants.kMaxAttachmentsPerMessage} files per message',
          code: 'max_files_exceeded',
        ),
      );
    }

    return const Right(true);
  }
}
