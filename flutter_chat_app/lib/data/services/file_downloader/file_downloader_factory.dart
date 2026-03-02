import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/services/i_file_downloader.dart';

import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart'
    if (dart.library.io) 'file_downloader_io.dart';

IFileDownloader createFileDownloader(AppLogger logger) {
  return createFileDownloaderImpl(logger);
}
