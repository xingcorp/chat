/// IO implementation — initializes media_kit on Windows.
library;

import 'dart:io' show Platform;

import 'package:media_kit/media_kit.dart';

Future<void> ensureMediaKitInitializedImpl() async {
  if (Platform.isWindows) {
    MediaKit.ensureInitialized();
  }
  // On Android/iOS/macOS/Linux media_kit is not used, so skip.
}
