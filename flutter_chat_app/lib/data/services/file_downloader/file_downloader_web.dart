import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/services/i_file_downloader.dart';
import 'package:url_launcher/url_launcher.dart';

IFileDownloader createFileDownloaderImpl(AppLogger logger) {
  return _WebFileDownloader(logger);
}

class _WebFileDownloader implements IFileDownloader {
  const _WebFileDownloader(this._logger);

  final AppLogger _logger;

  @override
  Future<Either<Failure, String>> downloadFromUrl({
    required String url,
    String? fileName,
    Map<String, String>? headers,
  }) async {
    if (url.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Missing file URL for download.',
          code: 'invalid_input',
        ),
      );
    }

    try {
      final Uri? uri = Uri.tryParse(url);
      if (uri == null) {
        return const Left(
          ValidationFailure(
            message: 'Invalid file URL.',
            code: 'invalid_input',
          ),
        );
      }

      final bool launched = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );
      if (!launched) {
        return const Left(
          DownloadFailure(
            message: 'Unable to open file URL for download.',
            code: 'download_failed',
          ),
        );
      }

      return Right(uri.toString());
    } catch (error, stackTrace) {
      _logger.e(
        'Web file download failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        DownloadFailure(
          message: 'Web file download failed: $error',
          code: 'download_failed',
        ),
      );
    }
  }
}
