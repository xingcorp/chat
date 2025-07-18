part of 'media_bloc.dart';

/// **Abstract class for Media BLoC events**
abstract class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object?> get props => [];
}

/// **Upload media file event**
class UploadMedia extends MediaEvent {
  final String messageId;
  final String chatId;
  final File file;

  const UploadMedia({
    required this.messageId,
    required this.chatId,
    required this.file,
  });

  @override
  List<Object> get props => [messageId, chatId, file];
}

/// **Download media file event**
class DownloadMedia extends MediaEvent {
  final String url;
  final String? messageId;
  final bool useCache;

  const DownloadMedia({
    required this.url,
    this.messageId,
    this.useCache = true,
  });

  @override
  List<Object?> get props => [url, messageId, useCache];
}

/// **Get cached media event**
class GetCachedMedia extends MediaEvent {
  final String url;
  final String? key;

  const GetCachedMedia({
    required this.url,
    this.key,
  });

  @override
  List<Object?> get props => [url, key];
}

/// **Compress image event**
class CompressImage extends MediaEvent {
  final File file;
  final int quality;

  const CompressImage({
    required this.file,
    this.quality = 80,
  });

  @override
  List<Object> get props => [file, quality];
}

/// **Generate thumbnail event**
class GenerateThumbnail extends MediaEvent {
  final File file;
  final int size;

  const GenerateThumbnail({
    required this.file,
    this.size = 200,
  });

  @override
  List<Object> get props => [file, size];
}

/// **Delete media event**
class DeleteMedia extends MediaEvent {
  final String mediaId;

  const DeleteMedia({required this.mediaId});

  @override
  List<Object> get props => [mediaId];
}

/// **Clear media cache event**
class ClearMediaCache extends MediaEvent {
  const ClearMediaCache();
}

/// **Get cache size event**
class GetCacheSize extends MediaEvent {
  const GetCacheSize();
}

/// **Validate media file event**
class ValidateMedia extends MediaEvent {
  final File file;

  const ValidateMedia({required this.file});

  @override
  List<Object> get props => [file];
}

/// **Clear media error event**
class ClearMediaError extends MediaEvent {
  const ClearMediaError();
}
