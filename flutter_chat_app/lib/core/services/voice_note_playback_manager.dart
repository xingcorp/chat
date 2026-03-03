import 'dart:async';

import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class VoiceNotePlaybackState {
  const VoiceNotePlaybackState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;

  VoiceNotePlaybackState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return VoiceNotePlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceNotePlaybackState &&
        other.isPlaying == isPlaying &&
        other.position == position &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(isPlaying, position, duration);
}

class _VoiceNotePlaybackSnapshot {
  const _VoiceNotePlaybackSnapshot({
    this.messageId,
    this.state = const VoiceNotePlaybackState(),
  });

  final String? messageId;
  final VoiceNotePlaybackState state;
}

abstract class VoiceNoteAudioPlayer {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<PlayerState> get playerStateStream;

  Future<Duration?> setUrl(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioVoiceNotePlayer implements VoiceNoteAudioPlayer {
  JustAudioVoiceNotePlayer([AudioPlayer? delegate])
      : _delegate = delegate ?? AudioPlayer();

  final AudioPlayer _delegate;

  @override
  Stream<Duration> get positionStream => _delegate.positionStream;

  @override
  Stream<Duration?> get durationStream => _delegate.durationStream;

  @override
  Stream<PlayerState> get playerStateStream => _delegate.playerStateStream;

  @override
  Future<Duration?> setUrl(String url) => _delegate.setUrl(url);

  @override
  Future<void> play() => _delegate.play();

  @override
  Future<void> pause() => _delegate.pause();

  @override
  Future<void> seek(Duration position) => _delegate.seek(position);

  @override
  Future<void> stop() => _delegate.stop();

  @override
  Future<void> dispose() => _delegate.dispose();
}

class VoiceNotePlaybackManager {
  VoiceNotePlaybackManager({
    VoiceNoteAudioPlayer? audioPlayer,
    AppLogger? logger,
  })  : _player = audioPlayer ?? JustAudioVoiceNotePlayer(),
        _logger = logger {
    _positionSubscription = _player.positionStream.listen(_onPositionChanged);
    _durationSubscription = _player.durationStream.listen(_onDurationChanged);
    _playerStateSubscription =
        _player.playerStateStream.listen(_onPlayerStateChanged);
  }

  final VoiceNoteAudioPlayer _player;
  final AppLogger? _logger;

  final BehaviorSubject<_VoiceNotePlaybackSnapshot> _snapshotController =
      BehaviorSubject<_VoiceNotePlaybackSnapshot>.seeded(
    const _VoiceNotePlaybackSnapshot(),
  );
  final Map<String, Duration> _durationCache = <String, Duration>{};

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  String? _currentPlayingId;
  String? get currentPlayingId => _currentPlayingId;

  Stream<VoiceNotePlaybackState> getPlaybackStream(String messageId) {
    return _snapshotController.stream.map((snapshot) {
      if (snapshot.messageId == messageId) {
        return snapshot.state;
      }
      return VoiceNotePlaybackState(
        isPlaying: false,
        position: Duration.zero,
        duration: _durationCache[messageId] ?? Duration.zero,
      );
    }).distinct();
  }

  Future<void> play(String messageId, String audioUrl) async {
    try {
      final isNewMessage = _currentPlayingId != messageId;
      if (isNewMessage) {
        await _player.stop();

        final duration = await _player.setUrl(audioUrl);
        final resolvedDuration =
            duration ?? _durationCache[messageId] ?? Duration.zero;
        _durationCache[messageId] = resolvedDuration;
        _currentPlayingId = messageId;

        _emitState(
          messageId,
          VoiceNotePlaybackState(
            isPlaying: false,
            position: Duration.zero,
            duration: resolvedDuration,
          ),
        );
      }

      await _player.play();

      final currentState = _resolveCurrentState(messageId);
      _emitState(messageId, currentState.copyWith(isPlaying: true));
    } catch (error, stackTrace) {
      _logger?.e(
        'VoiceNotePlaybackManager.play failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> pause() async {
    final messageId = _currentPlayingId;
    if (messageId == null) return;

    await _player.pause();
    final currentState = _resolveCurrentState(messageId);
    _emitState(messageId, currentState.copyWith(isPlaying: false));
  }

  Future<void> seek(Duration position) async {
    final messageId = _currentPlayingId;
    if (messageId == null) return;

    await _player.seek(position);
    final currentState = _resolveCurrentState(messageId);
    _emitState(messageId, currentState.copyWith(position: position));
  }

  Future<void> stop() async {
    final messageId = _currentPlayingId;
    if (messageId == null) return;

    await _player.stop();
    final duration =
        _durationCache[messageId] ?? _resolveCurrentState(messageId).duration;
    _emitState(
      messageId,
      VoiceNotePlaybackState(
        isPlaying: false,
        position: Duration.zero,
        duration: duration,
      ),
    );
    _currentPlayingId = null;
  }

  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _player.dispose();
    await _snapshotController.close();
  }

  void _onPositionChanged(Duration position) {
    final messageId = _currentPlayingId;
    if (messageId == null) return;

    final currentState = _resolveCurrentState(messageId);
    _emitState(messageId, currentState.copyWith(position: position));
  }

  void _onDurationChanged(Duration? duration) {
    final messageId = _currentPlayingId;
    if (messageId == null || duration == null) return;

    _durationCache[messageId] = duration;
    final currentState = _resolveCurrentState(messageId);
    _emitState(messageId, currentState.copyWith(duration: duration));
  }

  void _onPlayerStateChanged(PlayerState playerState) {
    final messageId = _currentPlayingId;
    if (messageId == null) return;

    final currentState = _resolveCurrentState(messageId);

    if (playerState.processingState == ProcessingState.completed) {
      unawaited(_player.seek(Duration.zero));
      unawaited(_player.pause());
      _emitState(
        messageId,
        VoiceNotePlaybackState(
          isPlaying: false,
          position: Duration.zero,
          duration: _durationCache[messageId] ?? currentState.duration,
        ),
      );
      return;
    }

    if (playerState.playing != currentState.isPlaying) {
      _emitState(
        messageId,
        currentState.copyWith(isPlaying: playerState.playing),
      );
    }
  }

  VoiceNotePlaybackState _resolveCurrentState(String messageId) {
    final snapshot = _snapshotController.value;
    if (snapshot.messageId == messageId) return snapshot.state;
    return VoiceNotePlaybackState(
        duration: _durationCache[messageId] ?? Duration.zero);
  }

  void _emitState(String messageId, VoiceNotePlaybackState state) {
    _snapshotController.add(
      _VoiceNotePlaybackSnapshot(
        messageId: messageId,
        state: state,
      ),
    );
  }
}
