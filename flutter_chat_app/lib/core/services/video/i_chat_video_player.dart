/// Platform-agnostic video player interface.
///
/// Abstracts away platform-specific video packages so that `video_player` +
/// `chewie` are used on mobile/macOS/Linux while `media_kit` is used on
/// Windows.
///
/// Instances are **per-widget** — create via [createChatVideoPlayer] factory.
library;

import 'package:flutter/widgets.dart';

/// Neutral video player state.
class ChatVideoState {
  const ChatVideoState({
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
    this.isInitialized = false,
  });

  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final bool isInitialized;

  ChatVideoState copyWith({
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
    bool? isInitialized,
  }) {
    return ChatVideoState(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isCompleted: isCompleted ?? this.isCompleted,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatVideoState &&
        other.isPlaying == isPlaying &&
        other.isBuffering == isBuffering &&
        other.isCompleted == isCompleted &&
        other.isInitialized == isInitialized;
  }

  @override
  int get hashCode =>
      Object.hash(isPlaying, isBuffering, isCompleted, isInitialized);

  @override
  String toString() =>
      'ChatVideoState(isPlaying: $isPlaying, isBuffering: $isBuffering, '
      'isCompleted: $isCompleted, isInitialized: $isInitialized)';
}

/// Platform-agnostic video player contract.
///
/// Implementations convert their native events into [ChatVideoState] /
/// [Duration] streams so widget code never touches package-specific types.
abstract class IChatVideoPlayer {
  /// Current playback position.
  Stream<Duration> get positionStream;

  /// Total duration (emitted once the source is loaded).
  Stream<Duration?> get durationStream;

  /// Aggregated player state.
  Stream<ChatVideoState> get stateStream;

  /// Aspect ratio of the loaded video (defaults to 16/9 before init).
  double get aspectRatio;

  /// Whether [initialize] has completed successfully.
  bool get isInitialized;

  /// Load and prepare a video from [url] (network URL or file path).
  Future<void> initialize(String url);

  /// Start / resume playback.
  Future<void> play();

  /// Pause playback (keeps position).
  Future<void> pause();

  /// Seek to [position].
  Future<void> seek(Duration position);

  /// Set volume in range `0.0` – `1.0`.
  Future<void> setVolume(double volume);

  /// Set playback speed (e.g. `0.5`, `1.0`, `1.5`, `2.0`).
  Future<void> setSpeed(double speed);

  /// Enable or disable looping.
  Future<void> setLooping(bool looping);

  /// Release all native resources.
  Future<void> dispose();

  /// Returns the platform-specific video widget.
  ///
  /// For `video_player`/`chewie`: returns [Chewie] widget with built-in
  /// controls.
  /// For `media_kit`: returns [Video] widget with material desktop controls.
  ///
  /// [showControls] determines whether built-in playback controls are shown.
  Widget buildVideoWidget({bool showControls = true});
}
