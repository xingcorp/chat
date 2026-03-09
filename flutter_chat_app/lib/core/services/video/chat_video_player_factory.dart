/// Factory that resolves the correct [IChatVideoPlayer] implementation at
/// compile time via conditional imports.
///
/// ```dart
/// final player = createChatVideoPlayer();
/// await player.initialize('https://example.com/video.mp4');
/// // Use player.buildVideoWidget() in widget tree
/// await player.play();
/// ```
///
/// - **Web / unsupported** → stub (no-op)
/// - **IO non-Windows** → `video_player` + `chewie`
/// - **IO Windows** → `media_kit`
library;

import 'package:flutter_chat_app/core/services/video/chat_video_player_stub.dart'
    if (dart.library.io) 'package:flutter_chat_app/core/services/video/chat_video_player_io.dart';
import 'package:flutter_chat_app/core/services/video/i_chat_video_player.dart';

/// Create a new per-widget video player instance.
///
/// Each call returns a fresh player; callers are responsible for calling
/// [IChatVideoPlayer.dispose] when done.
IChatVideoPlayer createChatVideoPlayer() {
  return createChatVideoPlayerImpl();
}
