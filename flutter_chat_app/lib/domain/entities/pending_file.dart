import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';

/// Status of a pending file in the attachment queue
enum PendingFileStatus {
  /// File selected, not yet started upload
  pending,

  /// File is being validated/compressed
  preparing,

  /// File is uploading to server
  uploading,

  /// Upload completed, url available
  completed,

  /// Upload failed
  failed,

  /// Upload cancelled by user
  cancelled,
}

/// Represents a file that has been selected for attachment (via drag & drop,
/// clipboard paste, or file picker) but may not yet be fully uploaded.
///
/// Tracks the full lifecycle from selection through upload completion.
/// Converts to [Attachment] once upload is complete.
class PendingFile extends Equatable {
  /// Unique local identifier (UUID generated on creation)
  final String localId;

  /// Original file name
  final String fileName;

  /// File size in bytes
  final int fileSize;

  /// MIME type of the file
  final String mimeType;

  /// Attachment type category
  final AttachmentType type;

  /// File path on disk (desktop/mobile — null on web)
  final String? localPath;

  /// File bytes in memory (web / clipboard paste — null on desktop with path)
  final Uint8List? bytes;

  /// Current status in the upload lifecycle
  final PendingFileStatus status;

  /// Upload progress from 0.0 to 1.0
  final double uploadProgress;

  /// CDN URL after successful upload
  final String? uploadedUrl;

  /// Server-side upload/storage ID
  final String? uploadId;

  /// Error message if upload failed
  final String? errorMessage;

  /// Timestamp when file was added
  final DateTime addedAt;

  const PendingFile({
    required this.localId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.type,
    this.localPath,
    this.bytes,
    this.status = PendingFileStatus.pending,
    this.uploadProgress = 0.0,
    this.uploadedUrl,
    this.uploadId,
    this.errorMessage,
    required this.addedAt,
  });

  /// Whether this file has completed uploading
  bool get isCompleted => status == PendingFileStatus.completed;

  /// Whether this file has failed uploading
  bool get hasFailed => status == PendingFileStatus.failed;

  /// Whether this file is currently being uploaded
  bool get isUploading =>
      status == PendingFileStatus.uploading ||
      status == PendingFileStatus.preparing;

  /// Whether file data is available (either path or bytes)
  bool get hasData => localPath != null || bytes != null;

  /// Whether this is an image file
  bool get isImage => type == AttachmentType.image;

  /// Whether this is a video file
  bool get isVideo => type == AttachmentType.video;

  /// Whether this is an audio file
  bool get isAudio => type == AttachmentType.audio;

  /// Whether this is a document file
  bool get isDocument => type == AttachmentType.document;

  /// Create a copy with updated fields
  PendingFile copyWith({
    String? localId,
    String? fileName,
    int? fileSize,
    String? mimeType,
    AttachmentType? type,
    String? localPath,
    Uint8List? bytes,
    PendingFileStatus? status,
    double? uploadProgress,
    String? uploadedUrl,
    String? uploadId,
    String? errorMessage,
    DateTime? addedAt,
  }) {
    return PendingFile(
      localId: localId ?? this.localId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      bytes: bytes ?? this.bytes,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      uploadId: uploadId ?? this.uploadId,
      errorMessage: errorMessage ?? this.errorMessage,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Convert to [Attachment] entity (only valid when upload is completed)
  Attachment toAttachment() {
    return Attachment(
      id: uploadId ?? localId,
      name: fileName,
      localPath: localPath,
      url: uploadedUrl,
      type: type,
      mimeType: mimeType,
      size: fileSize,
      status: _mapStatus(),
      uploadProgress: (uploadProgress * 100).round(),
      errorMessage: errorMessage,
    );
  }

  AttachmentStatus _mapStatus() {
    switch (status) {
      case PendingFileStatus.pending:
        return AttachmentStatus.pending;
      case PendingFileStatus.preparing:
        return AttachmentStatus.preparing;
      case PendingFileStatus.uploading:
        return AttachmentStatus.uploading;
      case PendingFileStatus.completed:
        return AttachmentStatus.uploaded;
      case PendingFileStatus.failed:
      case PendingFileStatus.cancelled:
        return AttachmentStatus.error;
    }
  }

  @override
  List<Object?> get props => [
        localId,
        fileName,
        fileSize,
        mimeType,
        type,
        localPath,
        status,
        uploadProgress,
        uploadedUrl,
        uploadId,
        errorMessage,
        addedAt,
      ];
}
