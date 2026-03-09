/// Platform-agnostic audio player interface.
///
/// Used by [AudioPlayerWidget], [VoiceNotePlaybackManager], and design system
/// [AppAudioPlayer]. Abstracts away platform-specific packages so that
/// `just_audio` is used on mobile/macOS/Linux while `audioplayers` is used on
/// Windows.
///
/// Instances are **per-widget** — create via [createChatAudioPlayer] factory.
library;

/// Neutral player state that both `just_audio` and `audioplayers` map into.
class ChatPlayerState {
  const ChatPlayerState({
    this.isPlaying = false,
    this.isCompleted = false,
    this.isBuffering = false,
  });

  final bool isPlaying;
  final bool isCompleted;
  final bool isBuffering;

  ChatPlayerState copyWith({
    bool? isPlaying,
    bool? isCompleted,
    bool? isBuffering,
  }) {
    return ChatPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isCompleted: isCompleted ?? this.isCompleted,
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatPlayerState &&
        other.isPlaying == isPlaying &&
        other.isCompleted == isCompleted &&
        other.isBuffering == isBuffering;
  }

  @override
  int get hashCode => Object.hash(isPlaying, isCompleted, isBuffering);

  @override
  String toString() =>
      'ChatPlayerState(isPlaying: $isPlaying, isCompleted: $isCompleted, '
      'isBuffering: $isBuffering)';
}

/// Platform-agnostic audio player contract.
///
/// Each platform implementation converts its native events into
/// [ChatPlayerState] / [Duration] streams so that widget code never touches
/// package-specific types.
abstract class IChatAudioPlayer {
  /// Current playback position.
  Stream<Duration> get positionStream;

  /// Total duration (emitted once the source is loaded, may re-emit on seek).
  Stream<Duration?> get durationStream;

  /// Aggregated player state.
  Stream<ChatPlayerState> get playerStateStream;

  /// Load an audio source from [url] (network URL or `file://` path).
  ///
  /// Returns the resolved duration when available, or `null` if the backend
  /// cannot determine it synchronously.
  Future<Duration?> setSource(String url);

  /// Start / resume playback.
  Future<void> play();

  /// Pause playback (keeps position).
  Future<void> pause();

  /// Seek to [position].
  Future<void> seek(Duration position);

  /// Stop playback and reset position to zero.
  Future<void> stop();

  /// Set volume in range `0.0` – `1.0`.
  Future<void> setVolume(double volume);

  /// Set playback speed (e.g. `0.5`, `1.0`, `1.5`, `2.0`).
  Future<void> setSpeed(double speed);

  /// Release all native resources.
  Future<void> dispose();
}
