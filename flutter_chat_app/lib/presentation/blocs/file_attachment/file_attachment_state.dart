part of 'file_attachment_bloc.dart';

/// State for [FileAttachmentBloc]
class FileAttachmentState extends Equatable {
  /// List of files currently in the attachment queue
  final List<PendingFile> pendingFiles;

  /// Last validation/upload error message (for showing snackbar)
  final String? lastError;

  /// Error code for the last error (for programmatic handling)
  final String? lastErrorCode;

  const FileAttachmentState({
    this.pendingFiles = const [],
    this.lastError,
    this.lastErrorCode,
  });

  /// Whether there are any files pending
  bool get hasFiles => pendingFiles.isNotEmpty;

  /// Number of pending files
  int get fileCount => pendingFiles.length;

  /// Whether all files have completed upload
  bool get allUploadsCompleted =>
      pendingFiles.isNotEmpty &&
      pendingFiles.every((f) => f.status == PendingFileStatus.completed);

  /// Whether any file is currently uploading
  bool get hasActiveUploads => pendingFiles.any(
        (f) =>
            f.status == PendingFileStatus.uploading ||
            f.status == PendingFileStatus.preparing,
      );

  /// Whether any file has failed
  bool get hasFailedUploads =>
      pendingFiles.any((f) => f.status == PendingFileStatus.failed);

  /// Remaining attachment slots available
  int get remainingSlots =>
      AppConstants.kMaxAttachmentsPerMessage - pendingFiles.length;

  /// Get completed attachments ready for message send.
  ///
  /// Maps completed [PendingFile]s to [Attachment] entities.
  List<Attachment> get completedAttachments => pendingFiles
      .where(
        (f) => f.status == PendingFileStatus.completed && f.uploadedUrl != null,
      )
      .map((f) => f.toAttachment())
      .toList();

  /// Create a copy with updated fields
  FileAttachmentState copyWith({
    List<PendingFile>? pendingFiles,
    String? lastError,
    String? lastErrorCode,
    bool clearError = false,
  }) {
    return FileAttachmentState(
      pendingFiles: pendingFiles ?? this.pendingFiles,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastErrorCode: clearError ? null : (lastErrorCode ?? this.lastErrorCode),
    );
  }

  @override
  List<Object?> get props => [pendingFiles, lastError, lastErrorCode];
}
