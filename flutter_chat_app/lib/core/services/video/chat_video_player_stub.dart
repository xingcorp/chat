/// Stub used when no concrete video backend is available.
///
/// Every method either returns immediately or emits nothing.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_chat_app/core/services/video/i_chat_video_player.dart';

IChatVideoPlayer createChatVideoPlayerImpl() => _StubChatVideoPlayer();

class _StubChatVideoPlayer implements IChatVideoPlayer {
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<ChatVideoState> _stateController =
      StreamController<ChatVideoState>.broadcast();

  @override
  double get aspectRatio => 16 / 9;

  @override
  bool get isInitialized => false;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<ChatVideoState> get stateStream => _stateController.stream;

  @override
  Future<void> initialize(String url) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> dispose() async {
    await _positionController.close();
    await _durationController.close();
    await _stateController.close();
  }

  @override
  Widget buildVideoWidget({bool showControls = true}) =>
      const SizedBox.shrink();
}
