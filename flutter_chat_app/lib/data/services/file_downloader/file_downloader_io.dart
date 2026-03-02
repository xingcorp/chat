import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/services/i_file_downloader.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

IFileDownloader createFileDownloaderImpl(AppLogger logger) {
  return _IoFileDownloader(logger);
}

class _IoFileDownloader implements IFileDownloader {
  const _IoFileDownloader(this._logger);

  final AppLogger _logger;

  static const List<TargetPlatform> _backgroundDownloadPlatforms =
      <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ];

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

    final Uri? uri = Uri.tryParse(url);
    if (uri == null || (!uri.hasScheme && !uri.hasAuthority)) {
      return const Left(
        ValidationFailure(
          message: 'Invalid file URL.',
          code: 'invalid_input',
        ),
      );
    }

    if (_backgroundDownloadPlatforms.contains(defaultTargetPlatform)) {
      return _enqueueMobileDownload(
        url: url,
        fileName: fileName,
        headers: headers,
      );
    }

    return _openExternalUrl(uri);
  }

  Future<Either<Failure, String>> _enqueueMobileDownload({
    required String url,
    String? fileName,
    Map<String, String>? headers,
  }) async {
    try {
      final String targetDir = await _resolveDownloadDirectory();
      await Directory(targetDir).create(recursive: true);

      final String normalizedFileName =
          _normalizeFileName(fileName ?? _inferFileNameFromUrl(url));
      final String? taskId = await FlutterDownloader.enqueue(
        url: url,
        headers: headers ?? const <String, String>{},
        savedDir: targetDir,
        fileName: normalizedFileName,
        showNotification: true,
        openFileFromNotification: false,
      );

      if (taskId == null || taskId.isEmpty) {
        return const Left(
          DownloadFailure(
            message: 'Failed to enqueue download task.',
            code: 'download_failed',
          ),
        );
      }

      _logger.i(
        'Download task enqueued',
        <String, dynamic>{
          'taskId': taskId,
          'savedDir': targetDir,
          'fileName': normalizedFileName,
        },
      );
      return Right(taskId);
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to enqueue mobile download',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        DownloadFailure(
          message: 'Failed to enqueue download: $error',
          code: 'download_failed',
        ),
      );
    }
  }

  Future<Either<Failure, String>> _openExternalUrl(Uri uri) async {
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return Right(uri.toString());
      }

      return const Left(
        DownloadFailure(
          message: 'Unable to open file URL.',
          code: 'download_failed',
        ),
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to open file URL',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        DownloadFailure(
          message: 'Failed to open file URL: $error',
          code: 'download_failed',
        ),
      );
    }
  }

  Future<String> _resolveDownloadDirectory() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir.path;
      }
    }

    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final Directory downloadsDir =
        Directory('${documentsDir.path}${Platform.pathSeparator}downloads');
    return downloadsDir.path;
  }

  String _inferFileNameFromUrl(String url) {
    final Uri uri = Uri.parse(url);
    final String rawName = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'download_${DateTime.now().millisecondsSinceEpoch}';

    if (rawName.isEmpty) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }

    return rawName;
  }

  String _normalizeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
