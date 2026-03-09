/// [IChatAudioPlayer] implementation backed by `just_audio`.
///
/// Used on Android, iOS, macOS, and Linux where `just_audio` is fully
/// supported. Windows uses [AudioPlayersChatPlayer] instead.
library;

import 'dart:async';

import 'package:flutter_chat_app/core/services/audio/i_chat_audio_player.dart';
import 'package:just_audio/just_audio.dart' as ja;

class JustAudioChatPlayer implements IChatAudioPlayer {
  JustAudioChatPlayer() : _delegate = ja.AudioPlayer();

  final ja.AudioPlayer _delegate;

  late final StreamController<ChatPlayerState> _stateController =
      StreamController<ChatPlayerState>.broadcast();

  StreamSubscription<ja.PlayerState>? _stateSub;
  bool _disposed = false;

  void _ensureStateSubscription() {
    if (_stateSub != null) return;
    _stateSub = _delegate.playerStateStream.listen((jaState) {
      if (_disposed) return;
      _stateController.add(ChatPlayerState(
        isPlaying: jaState.playing,
        isCompleted:
            jaState.processingState == ja.ProcessingState.completed,
        isBuffering:
            jaState.processingState == ja.ProcessingState.buffering ||
                jaState.processingState == ja.ProcessingState.loading,
      ));
    });
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  @override
  Stream<Duration> get positionStream => _delegate.positionStream;

  @override
  Stream<Duration?> get durationStream => _delegate.durationStream;

  @override
  Stream<ChatPlayerState> get playerStateStream {
    _ensureStateSubscription();
    return _stateController.stream;
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  @override
  Future<Duration?> setSource(String url) async {
    _ensureStateSubscription();

    try {
      return await _delegate.setUrl(url);
    } catch (_) {
      // Attempt file URI fallback for local paths.
      final fileUri = _asFileUri(url);
      if (fileUri == null) rethrow;
      return _delegate.setUrl(fileUri);
    }
  }

  @override
  Future<void> play() => _delegate.play();

  @override
  Future<void> pause() => _delegate.pause();

  @override
  Future<void> seek(Duration position) => _delegate.seek(position);

  @override
  Future<void> stop() => _delegate.stop();

  @override
  Future<void> setVolume(double volume) => _delegate.setVolume(volume);

  @override
  Future<void> setSpeed(double speed) => _delegate.setSpeed(speed);

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _stateSub?.cancel();
    await _stateController.close();
    await _delegate.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String? _asFileUri(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) return null;
    if (normalized.startsWith('file://')) return normalized;

    final maybeUnixPath = normalized.startsWith('/');
    final maybeWindowsPath = normalized.length > 2 &&
        normalized[1] == ':' &&
        (normalized[2] == '\\' || normalized[2] == '/');
    if (!maybeUnixPath && !maybeWindowsPath) return null;

    return Uri.file(normalized, windows: maybeWindowsPath).toString();
  }
}
