import 'dart:async';
import 'dart:collection';

import 'package:flutter_chat_app/core/services/audio/chat_audio_player_factory.dart';
import 'package:flutter_chat_app/core/services/audio/i_chat_audio_player.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
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

/// Platform-agnostic audio player contract for voice notes.
///
/// Uses [ChatPlayerState] instead of package-specific types so that both
/// `just_audio` and `audioplayers` implementations can satisfy the interface.
abstract class VoiceNoteAudioPlayer {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<ChatPlayerState> get playerStateStream;

  Future<Duration?> setUrl(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}

/// Default [VoiceNoteAudioPlayer] that delegates to [IChatAudioPlayer] created
/// by the platform-conditional factory.
///
/// This replaces the old `JustAudioVoiceNotePlayer` which imported `just_audio`
/// directly and did not work on Windows.
class ChatAudioPlayerVoiceNoteAdapter implements VoiceNoteAudioPlayer {
  ChatAudioPlayerVoiceNoteAdapter([IChatAudioPlayer? delegate])
      : _delegate = delegate ?? createChatAudioPlayer();

  final IChatAudioPlayer _delegate;

  @override
  Stream<Duration> get positionStream => _delegate.positionStream;

  @override
  Stream<Duration?> get durationStream => _delegate.durationStream;

  @override
  Stream<ChatPlayerState> get playerStateStream =>
      _delegate.playerStateStream;

  @override
  Future<Duration?> setUrl(String url) => _delegate.setSource(url);

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
    VoiceNoteAudioPlayer? probeAudioPlayer,
    AppLogger? logger,
  })  : _player = audioPlayer ?? ChatAudioPlayerVoiceNoteAdapter(),
        _probePlayer = probeAudioPlayer ?? ChatAudioPlayerVoiceNoteAdapter(),
        _logger = logger {
    _positionSubscription = _player.positionStream.listen(_onPositionChanged);
    _durationSubscription = _player.durationStream.listen(_onDurationChanged);
    _playerStateSubscription =
        _player.playerStateStream.listen(_onPlayerStateChanged);
  }

  final VoiceNoteAudioPlayer _player;
  final VoiceNoteAudioPlayer _probePlayer;
  final AppLogger? _logger;

  final BehaviorSubject<_VoiceNotePlaybackSnapshot> _snapshotController =
      BehaviorSubject<_VoiceNotePlaybackSnapshot>.seeded(
    const _VoiceNotePlaybackSnapshot(),
  );
  static const int _maxDurationByMessageEntries = 800;
  static const int _maxDurationByUrlEntries = 800;
  static const Duration _probeTimeout = Duration(seconds: 4);
  static const Duration _probeBaseCooldown = Duration(seconds: 15);
  static const int _probeMaxCooldownFactor = 8;

  final LinkedHashMap<String, Duration> _durationCacheByMessage =
      LinkedHashMap<String, Duration>();
  final LinkedHashMap<String, Duration> _durationCacheByUrl =
      LinkedHashMap<String, Duration>();
  final Map<String, Future<Duration>> _inFlightProbeByUrl =
      <String, Future<Duration>>{};
  final Map<String, DateTime> _probeCooldownUntilByUrl = <String, DateTime>{};
  final Map<String, int> _probeFailureCountByUrl = <String, int>{};

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<ChatPlayerState>? _playerStateSubscription;

  String? _currentPlayingId;
  String? _currentPlayingUrl;
  String? get currentPlayingId => _currentPlayingId;

  Stream<VoiceNotePlaybackState> getPlaybackStream(String messageId) {
    return _snapshotController.stream.map((snapshot) {
      if (snapshot.messageId == messageId) {
        return snapshot.state;
      }
      return VoiceNotePlaybackState(
        isPlaying: false,
        position: Duration.zero,
        duration: _durationCacheByMessage[messageId] ?? Duration.zero,
      );
    }).distinct();
  }

  Duration getKnownDuration({
    required String messageId,
    String? audioUrl,
    Duration fallback = Duration.zero,
  }) {
    final cachedByMessage = _durationCacheByMessage[messageId];
    if (cachedByMessage != null && cachedByMessage > Duration.zero) {
      return cachedByMessage;
    }

    final normalizedUrl = _normalizeAudioUrl(audioUrl);
    if (normalizedUrl != null) {
      final cachedByUrl = _durationCacheByUrl[normalizedUrl];
      if (cachedByUrl != null && cachedByUrl > Duration.zero) {
        _writeLruDuration(
          cache: _durationCacheByMessage,
          key: messageId,
          value: cachedByUrl,
          maxEntries: _maxDurationByMessageEntries,
        );
        return cachedByUrl;
      }
    }

    return fallback;
  }

  void seedDuration({
    required String messageId,
    String? audioUrl,
    required Duration duration,
  }) {
    final changed = _cacheResolvedDuration(
      messageId: messageId,
      audioUrl: audioUrl,
      duration: duration,
    );
    if (changed) {
      _emitCacheRefresh();
    }
  }

  Future<Duration> prefetchDuration({
    required String messageId,
    required String audioUrl,
  }) async {
    final known = getKnownDuration(
      messageId: messageId,
      audioUrl: audioUrl,
    );
    if (known > Duration.zero) {
      return known;
    }

    final normalizedUrl = _normalizeAudioUrl(audioUrl);
    if (normalizedUrl == null) {
      return Duration.zero;
    }

    final cooldownUntil = _probeCooldownUntilByUrl[normalizedUrl];
    if (cooldownUntil != null && DateTime.now().isBefore(cooldownUntil)) {
      return Duration.zero;
    }

    final existingProbe = _inFlightProbeByUrl[normalizedUrl];
    final probeFuture = existingProbe ?? _startProbe(normalizedUrl);
    final resolvedDuration = await probeFuture;

    if (resolvedDuration <= Duration.zero) {
      _registerProbeFailure(normalizedUrl);
      return Duration.zero;
    }

    final changed = _cacheResolvedDuration(
      messageId: messageId,
      audioUrl: normalizedUrl,
      duration: resolvedDuration,
    );
    _clearProbeFailure(normalizedUrl);

    if (changed) {
      _emitCacheRefresh();
    }

    return resolvedDuration;
  }

  Future<void> play(String messageId, String audioUrl) async {
    try {
      final isNewMessage = _currentPlayingId != messageId;
      if (isNewMessage) {
        await _player.stop();

        final duration = await _setUrlWithLocalPathFallback(
          player: _player,
          audioUrl: audioUrl,
        );
        final resolvedDuration = duration ??
            getKnownDuration(
              messageId: messageId,
              audioUrl: audioUrl,
            );
        _cacheResolvedDuration(
          messageId: messageId,
          audioUrl: audioUrl,
          duration: resolvedDuration,
        );
        _currentPlayingId = messageId;
        _currentPlayingUrl = _normalizeAudioUrl(audioUrl);

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
    final duration = _durationCacheByMessage[messageId] ??
        _resolveCurrentState(messageId).duration;
    _emitState(
      messageId,
      VoiceNotePlaybackState(
        isPlaying: false,
        position: Duration.zero,
        duration: duration,
      ),
    );
    _currentPlayingId = null;
    _currentPlayingUrl = null;
  }

  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _player.dispose();
    await _probePlayer.dispose();
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

    _cacheResolvedDuration(
      messageId: messageId,
      audioUrl: _currentPlayingUrl,
      duration: duration,
    );
    final currentState = _resolveCurrentState(messageId);
    _emitState(messageId, currentState.copyWith(duration: duration));
  }

  void _onPlayerStateChanged(ChatPlayerState playerState) {
    final messageId = _currentPlayingId;
    if (messageId == null) return;

    final currentState = _resolveCurrentState(messageId);

    if (playerState.isCompleted) {
      unawaited(_player.seek(Duration.zero));
      unawaited(_player.pause());
      _emitState(
        messageId,
        VoiceNotePlaybackState(
          isPlaying: false,
          position: Duration.zero,
          duration: _durationCacheByMessage[messageId] ?? currentState.duration,
        ),
      );
      return;
    }

    if (playerState.isPlaying != currentState.isPlaying) {
      _emitState(
        messageId,
        currentState.copyWith(isPlaying: playerState.isPlaying),
      );
    }
  }

  VoiceNotePlaybackState _resolveCurrentState(String messageId) {
    final snapshot = _snapshotController.value;
    if (snapshot.messageId == messageId) return snapshot.state;
    return VoiceNotePlaybackState(
      duration: _durationCacheByMessage[messageId] ?? Duration.zero,
    );
  }

  void _emitState(String messageId, VoiceNotePlaybackState state) {
    _snapshotController.add(
      _VoiceNotePlaybackSnapshot(
        messageId: messageId,
        state: state,
      ),
    );
  }

  Future<Duration> _startProbe(String normalizedUrl) {
    final probeFuture = _probeDuration(normalizedUrl);
    _inFlightProbeByUrl[normalizedUrl] = probeFuture;
    probeFuture.whenComplete(() {
      _inFlightProbeByUrl.remove(normalizedUrl);
    });
    return probeFuture;
  }

  Future<Duration> _probeDuration(String normalizedUrl) async {
    try {
      final duration = await _setUrlWithLocalPathFallback(
        player: _probePlayer,
        audioUrl: normalizedUrl,
      ).timeout(_probeTimeout);
      if (duration != null && duration > Duration.zero) {
        return duration;
      }

      final streamedDuration = await _probePlayer.durationStream
          .whereType<Duration>()
          .firstWhere((value) => value > Duration.zero)
          .timeout(_probeTimeout);
      return streamedDuration;
    } catch (error, stackTrace) {
      _logger?.w(
        'VoiceNotePlaybackManager.prefetchDuration failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Duration.zero;
    } finally {
      unawaited(_probePlayer.stop());
    }
  }

  Future<Duration?> _setUrlWithLocalPathFallback({
    required VoiceNoteAudioPlayer player,
    required String audioUrl,
  }) async {
    try {
      return await player.setUrl(audioUrl);
    } catch (_) {
      final fileUri = _asFileUri(audioUrl);
      if (fileUri == null) rethrow;
      return player.setUrl(fileUri);
    }
  }

  bool _cacheResolvedDuration({
    required String messageId,
    String? audioUrl,
    required Duration duration,
  }) {
    if (duration <= Duration.zero) return false;

    final previousByMessage = _durationCacheByMessage[messageId];
    _writeLruDuration(
      cache: _durationCacheByMessage,
      key: messageId,
      value: duration,
      maxEntries: _maxDurationByMessageEntries,
    );
    var changed = previousByMessage != duration;

    final normalizedUrl = _normalizeAudioUrl(audioUrl);
    if (normalizedUrl != null) {
      final previousByUrl = _durationCacheByUrl[normalizedUrl];
      _writeLruDuration(
        cache: _durationCacheByUrl,
        key: normalizedUrl,
        value: duration,
        maxEntries: _maxDurationByUrlEntries,
      );
      changed = changed || previousByUrl != duration;
    }

    return changed;
  }

  void _writeLruDuration({
    required LinkedHashMap<String, Duration> cache,
    required String key,
    required Duration value,
    required int maxEntries,
  }) {
    cache.remove(key);
    cache[key] = value;

    while (cache.length > maxEntries) {
      final firstKey = cache.keys.first;
      cache.remove(firstKey);
    }
  }

  void _registerProbeFailure(String normalizedUrl) {
    final failureCount = (_probeFailureCountByUrl[normalizedUrl] ?? 0) + 1;
    _probeFailureCountByUrl[normalizedUrl] = failureCount;

    final normalizedFactor = failureCount < 1
        ? 1
        : failureCount > _probeMaxCooldownFactor
            ? _probeMaxCooldownFactor
            : failureCount;
    final cooldown = _probeBaseCooldown * normalizedFactor;
    _probeCooldownUntilByUrl[normalizedUrl] = DateTime.now().add(cooldown);
  }

  void _clearProbeFailure(String normalizedUrl) {
    _probeFailureCountByUrl.remove(normalizedUrl);
    _probeCooldownUntilByUrl.remove(normalizedUrl);
  }

  void _emitCacheRefresh() {
    if (_snapshotController.isClosed) return;
    _snapshotController.add(_snapshotController.value);
  }

  String? _normalizeAudioUrl(String? audioUrl) {
    if (audioUrl == null) return null;
    final normalized = audioUrl.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  String? _asFileUri(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) return null;
    if (normalized.startsWith('file://')) return normalized;

    final maybeUnixPath = normalized.startsWith('/');
    final maybeWindowsPath = normalized.length > 2 &&
        normalized[1] == ':' &&
        (normalized[2] == '\\' || normalized[2] == '/');
    if (!maybeUnixPath && !maybeWindowsPath) {
      return null;
    }

    return Uri.file(normalized, windows: maybeWindowsPath).toString();
  }
}
