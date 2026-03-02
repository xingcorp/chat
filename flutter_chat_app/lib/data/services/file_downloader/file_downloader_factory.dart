import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/services/file_downloader/file_downloader_stub.dart'
    if (dart.library.html) 'package:flutter_chat_app/data/services/file_downloader/file_downloader_web.dart'
    if (dart.library.io) 'package:flutter_chat_app/data/services/file_downloader/file_downloader_io.dart';
import 'package:flutter_chat_app/domain/services/i_file_downloader.dart';

IFileDownloader createFileDownloader(AppLogger logger) {
  return createFileDownloaderImpl(logger);
}
