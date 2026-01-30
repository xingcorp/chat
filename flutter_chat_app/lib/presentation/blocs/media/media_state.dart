part of 'media_bloc.dart';

/// **Abstract class for Media BLoC states**
abstract class MediaState extends Equatable {
  const MediaState();

  @override
  List<Object?> get props => [];
}

/// **Initial state**
class MediaInitial extends MediaState {
  const MediaInitial();
}

/// **Loading state**
class MediaLoading extends MediaState {
  const MediaLoading();
}

/// **Uploading state with progress**
class MediaUploading extends MediaState {
  final String fileName;
  final double progress; // 0.0 to 1.0

  const MediaUploading({
    required this.fileName,
    required this.progress,
  });

  @override
  List<Object> get props => [fileName, progress];
}

/// **Upload success state**
class MediaUploadSuccess extends MediaState {
  final Attachment result;

  const MediaUploadSuccess({required this.result});

  @override
  List<Object> get props => [result];
}

/// **Downloading state with progress**
class MediaDownloading extends MediaState {
  final String url;
  final double progress; // 0.0 to 1.0

  const MediaDownloading({
    required this.url,
    required this.progress,
  });

  @override
  List<Object> get props => [url, progress];
}

/// **Download success state**
class MediaDownloadSuccess extends MediaState {
  final File file;

  const MediaDownloadSuccess({required this.file});

  @override
  List<Object> get props => [file];
}

/// **Cache success state**
class MediaCacheSuccess extends MediaState {
  final File file;

  const MediaCacheSuccess({required this.file});

  @override
  List<Object> get props => [file];
}

/// **Processing state (compression, thumbnail, etc.)**
class MediaProcessing extends MediaState {
  final String operation;
  final double progress; // 0.0 to 1.0

  const MediaProcessing({
    required this.operation,
    required this.progress,
  });

  @override
  List<Object> get props => [operation, progress];
}

/// **Compression success state**
class MediaCompressionSuccess extends MediaState {
  final File file;

  const MediaCompressionSuccess({required this.file});

  @override
  List<Object> get props => [file];
}

/// **Thumbnail success state**
class MediaThumbnailSuccess extends MediaState {
  final File file;

  const MediaThumbnailSuccess({required this.file});

  @override
  List<Object> get props => [file];
}

/// **Delete success state**
class MediaDeleteSuccess extends MediaState {
  final String mediaId;

  const MediaDeleteSuccess({required this.mediaId});

  @override
  List<Object> get props => [mediaId];
}

/// **Cache clear success state**
class MediaCacheClearSuccess extends MediaState {
  const MediaCacheClearSuccess();
}

/// **Cache size result state**
class MediaCacheSizeResult extends MediaState {
  final int sizeInBytes;

  const MediaCacheSizeResult({required this.sizeInBytes});

  /// Get formatted size string
  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  List<Object> get props => [sizeInBytes];
}

/// **Validation result state**
class MediaValidationResultState extends MediaState {
  final dynamic result; // Will be MediaValidationResult from domain

  const MediaValidationResultState({required this.result});

  @override
  List<Object> get props => [result];
}

/// **Error state**
class MediaError extends MediaState {
  final String message;

  const MediaError({required this.message});

  @override
  List<Object> get props => [message];
}

/// **Extension for convenient state creation**
extension MediaStateX on MediaState {
  static const MediaInitial initial = MediaInitial();
  static const MediaLoading loading = MediaLoading();

  static MediaUploading uploading({
    required String fileName,
    required double progress,
  }) =>
      MediaUploading(fileName: fileName, progress: progress);

  static MediaUploadSuccess uploadSuccess({required Attachment result}) =>
      MediaUploadSuccess(result: result);

  static MediaDownloading downloading({
    required String url,
    required double progress,
  }) =>
      MediaDownloading(url: url, progress: progress);

  static MediaDownloadSuccess downloadSuccess({required File file}) =>
      MediaDownloadSuccess(file: file);

  static MediaCacheSuccess cacheSuccess({required File file}) =>
      MediaCacheSuccess(file: file);

  static MediaProcessing processing({
    required String operation,
    required double progress,
  }) =>
      MediaProcessing(operation: operation, progress: progress);

  static MediaCompressionSuccess compressionSuccess({required File file}) =>
      MediaCompressionSuccess(file: file);

  static MediaThumbnailSuccess thumbnailSuccess({required File file}) =>
      MediaThumbnailSuccess(file: file);

  static MediaDeleteSuccess deleteSuccess({required String mediaId}) =>
      MediaDeleteSuccess(mediaId: mediaId);

  static const MediaCacheClearSuccess cacheClearSuccess = MediaCacheClearSuccess();

  static MediaCacheSizeResult cacheSizeResult({required int sizeInBytes}) =>
      MediaCacheSizeResult(sizeInBytes: sizeInBytes);

  static MediaValidationResultState validationResult({required dynamic result}) =>
      MediaValidationResultState(result: result);

  static MediaError error({required String message}) =>
      MediaError(message: message);
}
