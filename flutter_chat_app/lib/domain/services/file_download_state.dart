import 'package:equatable/equatable.dart';

enum FileDownloadStatus {
  idle,
  enqueued,
  downloading,
  completed,
  failed,
  canceled,
}

class FileDownloadState extends Equatable {
  const FileDownloadState({
    required this.key,
    required this.status,
    required this.progress,
    this.sourceUrl,
    this.taskId,
    this.fileName,
    this.localPath,
    this.errorMessage,
  });

  factory FileDownloadState.idle(
    String key, {
    String? sourceUrl,
    String? fileName,
  }) {
    return FileDownloadState(
      key: key,
      status: FileDownloadStatus.idle,
      progress: 0,
      sourceUrl: sourceUrl,
      fileName: fileName,
    );
  }

  final String key;
  final FileDownloadStatus status;
  final int progress;
  final String? sourceUrl;
  final String? taskId;
  final String? fileName;
  final String? localPath;
  final String? errorMessage;

  bool get isInProgress =>
      status == FileDownloadStatus.enqueued ||
      status == FileDownloadStatus.downloading;

  bool get canOpen =>
      status == FileDownloadStatus.completed &&
      ((taskId?.isNotEmpty ?? false) ||
          (localPath?.isNotEmpty ?? false) ||
          (sourceUrl?.isNotEmpty ?? false));

  bool get canRetry =>
      status == FileDownloadStatus.failed ||
      status == FileDownloadStatus.canceled;

  FileDownloadState copyWith({
    FileDownloadStatus? status,
    int? progress,
    String? sourceUrl,
    String? taskId,
    String? fileName,
    String? localPath,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return FileDownloadState(
      key: key,
      status: status ?? this.status,
      progress: _normalizeProgress(progress ?? this.progress),
      sourceUrl: sourceUrl ?? this.sourceUrl,
      taskId: taskId ?? this.taskId,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static int _normalizeProgress(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > 100) {
      return 100;
    }
    return value;
  }

  @override
  List<Object?> get props => <Object?>[
        key,
        status,
        progress,
        sourceUrl,
        taskId,
        fileName,
        localPath,
        errorMessage,
      ];
}
