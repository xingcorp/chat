/// Factory that resolves the correct [IChatAudioPlayer] implementation at
/// compile time via conditional imports.
///
/// ```dart
/// final player = createChatAudioPlayer();
/// await player.setSource('https://example.com/audio.mp3');
/// await player.play();
/// ```
///
/// - **Web / unsupported** → stub (no-op)
/// - **IO non-Windows** → `just_audio`
/// - **IO Windows** → `audioplayers`
library;

import 'package:flutter_chat_app/core/services/audio/chat_audio_player_stub.dart'
    if (dart.library.io) 'package:flutter_chat_app/core/services/audio/chat_audio_player_io.dart';
import 'package:flutter_chat_app/core/services/audio/i_chat_audio_player.dart';

/// Create a new per-widget audio player instance.
///
/// Each call returns a fresh player; callers are responsible for calling
/// [IChatAudioPlayer.dispose] when done.
IChatAudioPlayer createChatAudioPlayer() {
  return createChatAudioPlayerImpl();
}
