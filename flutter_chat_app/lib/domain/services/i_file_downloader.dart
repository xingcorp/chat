import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

/// Cross-platform abstraction for downloading remote files.
abstract class IFileDownloader {
  /// Downloads [url] and returns an identifier for the queued download task.
  ///
  /// On Android/iOS this is the `flutter_downloader` task id.
  /// On web/desktop this can be the original URL.
  Future<Either<Failure, String>> downloadFromUrl({
    required String url,
    String? fileName,
    Map<String, String>? headers,
  });
}
