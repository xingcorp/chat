/// Conditional-import factory for media_kit initialization.
///
/// On Windows (dart:io) → calls [MediaKit.ensureInitialized()].
/// On other platforms → no-op.
///
/// Must be called once before [createChatVideoPlayer] on Windows builds.
library;

import 'package:flutter_chat_app/core/initialization/media_kit_initializer_stub.dart'
    if (dart.library.io) 'package:flutter_chat_app/core/initialization/media_kit_initializer_io.dart';

/// Ensure media_kit native libraries are loaded (Windows only).
///
/// Safe to call on any platform — no-op when media_kit is not needed.
Future<void> ensureMediaKitInitialized() => ensureMediaKitInitializedImpl();
