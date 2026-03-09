/// [IChatVideoPlayer] implementation backed by `media_kit`.
///
/// Used on **Windows** where the native `video_player` plugin is not
/// supported. On other platforms [NativeChatVideoPlayer] is used instead.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/services/video/i_chat_video_player.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

class MediaKitChatVideoPlayer implements IChatVideoPlayer {
  late final mk.Player _player;
  late final mkv.VideoController _videoController;

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<ChatVideoState> _stateController =
      StreamController<ChatVideoState>.broadcast();

  final List<StreamSubscription<dynamic>> _subs =
      <StreamSubscription<dynamic>>[];
  bool _disposed = false;
  double _aspectRatio = 16 / 9;
  bool _isInitialized = false;

  MediaKitChatVideoPlayer() {
    _player = mk.Player();
    _videoController = mkv.VideoController(_player);
    _setupStreams();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  @override
  double get aspectRatio => _aspectRatio;

  @override
  bool get isInitialized => _isInitialized;

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<ChatVideoState> get stateStream => _stateController.stream;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize(String url) async {
    await _player.open(mk.Media(url), play: false);

    // Wait for first duration event to confirm initialisation.
    final duration = await _player.stream.duration
        .firstWhere((d) => d > Duration.zero)
        .timeout(const Duration(seconds: 10), onTimeout: () => Duration.zero);

    if (_disposed) return;

    if (duration > Duration.zero) {
      _durationController.add(duration);
    }

    // Try to resolve aspect ratio from video dimensions.
    final width = _player.state.width;
    final height = _player.state.height;
    if (width != null && height != null && width > 0 && height > 0) {
      _aspectRatio = width / height;
    }

    _isInitialized = true;
    _stateController.add(const ChatVideoState(isInitialized: true));
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume * 100); // media_kit uses 0–100

  @override
  Future<void> setSpeed(double speed) => _player.setRate(speed);

  @override
  Future<void> setLooping(bool looping) => _player.setPlaylistMode(
        looping ? mk.PlaylistMode.single : mk.PlaylistMode.none,
      );

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    await _player.dispose();
    await _positionController.close();
    await _durationController.close();
    await _stateController.close();
  }

  // ---------------------------------------------------------------------------
  // Widget
  // ---------------------------------------------------------------------------

  @override
  Widget buildVideoWidget({bool showControls = true}) {
    return mkv.Video(
      controller: _videoController,
      controls: showControls
          ? (state) => mkv.MaterialDesktopVideoControls(state)
          : (state) => const SizedBox.shrink(),
    );
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _setupStreams() {
    _subs.add(_player.stream.position.listen((position) {
      if (!_disposed) _positionController.add(position);
    }));

    _subs.add(_player.stream.duration.listen((duration) {
      if (!_disposed) _durationController.add(duration);
    }));

    _subs.add(_player.stream.playing.listen((playing) {
      if (!_disposed) {
        _stateController.add(ChatVideoState(
          isPlaying: playing,
          isInitialized: _isInitialized,
        ));
      }
    }));

    _subs.add(_player.stream.buffering.listen((buffering) {
      if (!_disposed) {
        _stateController.add(ChatVideoState(
          isBuffering: buffering,
          isInitialized: _isInitialized,
          isPlaying: _player.state.playing,
        ));
      }
    }));

    _subs.add(_player.stream.completed.listen((completed) {
      if (!_disposed) {
        _stateController.add(ChatVideoState(
          isCompleted: completed,
          isInitialized: _isInitialized,
          isPlaying: false,
        ));
      }
    }));

    // Update aspect ratio when video dimensions change.
    _subs.add(_player.stream.width.listen((width) {
      final height = _player.state.height;
      if (width != null && height != null && width > 0 && height > 0) {
        _aspectRatio = width / height;
      }
    }));
  }
}
