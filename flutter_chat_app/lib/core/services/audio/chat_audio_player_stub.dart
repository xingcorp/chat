/// Stub used when no concrete audio backend is available (e.g. web builds
/// that haven't wired a web-specific player yet).
///
/// Every method either returns immediately or emits nothing.
library;

import 'dart:async';

import 'package:flutter_chat_app/core/services/audio/i_chat_audio_player.dart';

IChatAudioPlayer createChatAudioPlayerImpl() => _StubChatAudioPlayer();

class _StubChatAudioPlayer implements IChatAudioPlayer {
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<ChatPlayerState> _stateController =
      StreamController<ChatPlayerState>.broadcast();

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<ChatPlayerState> get playerStateStream => _stateController.stream;

  @override
  Future<Duration?> setSource(String url) async => null;

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {
    await _positionController.close();
    await _durationController.close();
    await _stateController.close();
  }
}
