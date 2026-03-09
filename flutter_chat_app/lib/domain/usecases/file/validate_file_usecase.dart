import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/base/base_usecase.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

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
/// - File size does not exceed [AppConstants.kMaxAttachmentSize] (25MB)
/// - File type is in the allowed list
/// - Total attachment count does not exceed [AppConstants.kMaxAttachmentsPerMessage] (10)
/// - File is not empty (0 bytes)
///
/// This is pure domain logic — no Data or Presentation layer dependencies.
@injectable
class ValidateFileUseCase extends UseCase<bool, ValidateFileParams> {
  /// Allowed file extensions for upload
  static const Set<String> _allowedExtensions = {
    // Images
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif',
    // Videos
    '.mp4', '.mov', '.avi', '.mkv', '.webm',
    // Audio
    '.mp3', '.wav', '.ogg', '.m4a', '.aac',
    // Documents
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    '.txt', '.csv', '.json', '.xml',
    // Archives
    '.zip', '.rar', '.7z',
  };

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

    // Check: file size within limit (25MB)
    if (params.fileSize > AppConstants.kMaxAttachmentSize) {
      final maxSizeMB = AppConstants.kMaxAttachmentSize / (1024 * 1024);
      return Left(
        ValidationFailure(
          message: 'File exceeds maximum size of ${maxSizeMB.toStringAsFixed(0)}MB',
          code: 'file_too_large',
        ),
      );
    }

    // Check: file type is allowed
    final extension = p.extension(params.fileName).toLowerCase();
    if (extension.isNotEmpty && !_allowedExtensions.contains(extension)) {
      return Left(
        ValidationFailure(
          message: 'File type not allowed: ${params.fileName}',
          code: 'file_type_not_allowed',
        ),
      );
    }

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
