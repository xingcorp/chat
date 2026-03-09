part of 'file_attachment_bloc.dart';

/// Events for [FileAttachmentBloc]
abstract class FileAttachmentEvent extends Equatable {
  const FileAttachmentEvent();

  @override
  List<Object?> get props => [];
}

/// Files added via drag & drop from OS
class FilesDropped extends FileAttachmentEvent {
  final List<XFile> files;

  const FilesDropped({required this.files});

  @override
  List<Object?> get props => [files];
}

/// Image pasted from clipboard (Ctrl+V / Cmd+V)
class ImagePasted extends FileAttachmentEvent {
  final Uint8List bytes;
  final String fileName;

  const ImagePasted({required this.bytes, required this.fileName});

  @override
  List<Object?> get props => [fileName];
}

/// Files selected via existing file picker
class FilesPicked extends FileAttachmentEvent {
  final List<PickedFileInfo> files;

  const FilesPicked({required this.files});

  @override
  List<Object?> get props => [files];
}

/// Remove a specific pending file from the queue
class FileRemoved extends FileAttachmentEvent {
  final String localId;

  const FileRemoved({required this.localId});

  @override
  List<Object?> get props => [localId];
}

/// Retry upload for a failed file
class UploadRetried extends FileAttachmentEvent {
  final String localId;

  const UploadRetried({required this.localId});

  @override
  List<Object?> get props => [localId];
}

/// Cancel upload for a file in progress
class UploadCancelled extends FileAttachmentEvent {
  final String localId;

  const UploadCancelled({required this.localId});

  @override
  List<Object?> get props => [localId];
}

/// Internal: upload progress updated
class UploadProgressUpdated extends FileAttachmentEvent {
  final String localId;
  final double progress;

  const UploadProgressUpdated({
    required this.localId,
    required this.progress,
  });

  @override
  List<Object?> get props => [localId, progress];
}

/// Internal: upload completed successfully
class UploadCompleted extends FileAttachmentEvent {
  final String localId;
  final String url;
  final String uploadId;

  const UploadCompleted({
    required this.localId,
    required this.url,
    required this.uploadId,
  });

  @override
  List<Object?> get props => [localId, url, uploadId];
}

/// Internal: upload failed
class UploadFailed extends FileAttachmentEvent {
  final String localId;
  final String error;

  const UploadFailed({required this.localId, required this.error});

  @override
  List<Object?> get props => [localId, error];
}

/// Clear all pending files (after message sent or cancel all)
class AllFilesCleared extends FileAttachmentEvent {
  const AllFilesCleared();
}
