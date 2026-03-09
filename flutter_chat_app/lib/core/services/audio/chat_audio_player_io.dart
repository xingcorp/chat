/// IO implementation selector for [IChatAudioPlayer].
///
/// On **Windows** → delegates to [AudioPlayersChatPlayer] (audioplayers).
/// On **all other IO platforms** → delegates to [JustAudioChatPlayer] (just_audio).
library;

import 'dart:io' show Platform;

import 'package:flutter_chat_app/core/services/audio/audioplayers_chat_player.dart';
import 'package:flutter_chat_app/core/services/audio/i_chat_audio_player.dart';
import 'package:flutter_chat_app/core/services/audio/just_audio_chat_player.dart';

IChatAudioPlayer createChatAudioPlayerImpl() {
  if (Platform.isWindows) {
    return AudioPlayersChatPlayer();
  }
  return JustAudioChatPlayer();
}
