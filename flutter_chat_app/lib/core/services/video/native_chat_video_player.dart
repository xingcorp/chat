/// [IChatVideoPlayer] implementation backed by `video_player` + `chewie`.
///
/// Used on Android, iOS, macOS, and Linux where the native `video_player`
/// plugin is fully supported. Windows uses [MediaKitChatVideoPlayer] instead.
library;

import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/services/video/i_chat_video_player.dart';
import 'package:video_player/video_player.dart' as vp;

class NativeChatVideoPlayer implements IChatVideoPlayer {
  vp.VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<ChatVideoState> _stateController =
      StreamController<ChatVideoState>.broadcast();

  Timer? _positionTimer;
  bool _disposed = false;
  double _aspectRatio = 16 / 9;
  bool _isInitialized = false;

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
    await _disposeControllers();

    final controller = vp.VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();

    if (_disposed) {
      controller.dispose();
      return;
    }

    _videoController = controller;

    final ratio = controller.value.aspectRatio;
    _aspectRatio =
        (ratio.isNaN || ratio.isInfinite || ratio <= 0) ? 16 / 9 : ratio;

    _isInitialized = true;

    _durationController.add(controller.value.duration);

    // video_player does not provide a position stream — poll every 200ms.
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _emitPosition(),
    );

    controller.addListener(_onVideoValueChanged);

    _stateController.add(const ChatVideoState(isInitialized: true));
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() async {
    await _videoController?.play();
  }

  @override
  Future<void> pause() async {
    await _videoController?.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _videoController?.seekTo(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _videoController?.setVolume(volume);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _videoController?.setPlaybackSpeed(speed);
  }

  @override
  Future<void> setLooping(bool looping) async {
    await _videoController?.setLooping(looping);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _positionTimer?.cancel();
    _videoController?.removeListener(_onVideoValueChanged);
    await _disposeControllers();
    await _positionController.close();
    await _durationController.close();
    await _stateController.close();
  }

  // ---------------------------------------------------------------------------
  // Widget
  // ---------------------------------------------------------------------------

  @override
  Widget buildVideoWidget({bool showControls = true}) {
    final vc = _videoController;
    if (vc == null || !vc.value.isInitialized) {
      return const SizedBox.shrink();
    }

    if (showControls) {
      _chewieController ??= ChewieController(
        videoPlayerController: vc,
        autoPlay: false,
        looping: false,
        autoInitialize: false,
        showControls: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        aspectRatio: _aspectRatio,
      );
      return Chewie(controller: _chewieController!);
    }

    // Raw video without controls.
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: vp.VideoPlayer(vc),
    );
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _onVideoValueChanged() {
    if (_disposed) return;
    final value = _videoController?.value;
    if (value == null) return;

    _stateController.add(ChatVideoState(
      isPlaying: value.isPlaying,
      isBuffering: value.isBuffering,
      isCompleted: value.isCompleted,
      isInitialized: value.isInitialized,
    ));
  }

  void _emitPosition() {
    if (_disposed) return;
    final position = _videoController?.value.position;
    if (position != null) {
      _positionController.add(position);
    }
  }

  Future<void> _disposeControllers() async {
    _positionTimer?.cancel();
    _positionTimer = null;

    _chewieController?.dispose();
    _chewieController = null;

    _videoController?.removeListener(_onVideoValueChanged);
    _videoController?.dispose();
    _videoController = null;
  }
}
