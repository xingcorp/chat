/// IO implementation selector for [IChatVideoPlayer].
///
/// On **Windows** → delegates to [MediaKitChatVideoPlayer] (media_kit).
/// On **all other IO platforms** → delegates to [NativeChatVideoPlayer]
/// (video_player + chewie).
library;

import 'dart:io' show Platform;

import 'package:flutter_chat_app/core/services/video/i_chat_video_player.dart';
import 'package:flutter_chat_app/core/services/video/media_kit_chat_video_player.dart';
import 'package:flutter_chat_app/core/services/video/native_chat_video_player.dart';

IChatVideoPlayer createChatVideoPlayerImpl() {
  if (Platform.isWindows) {
    return MediaKitChatVideoPlayer();
  }
  return NativeChatVideoPlayer();
}
