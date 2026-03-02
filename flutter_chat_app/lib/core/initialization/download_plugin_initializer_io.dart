import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

Future<void> initializeDownloadPluginImpl() async {
  final TargetPlatform platform = defaultTargetPlatform;
  final bool isSupportedPlatform =
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;

  if (!isSupportedPlatform) {
    return;
  }

  try {
    await FlutterDownloader.initialize(
      debug: kDebugMode,
      ignoreSsl: false,
    );
  } catch (_) {
    // Download plugin initialization failure should not block app startup.
  }
}
