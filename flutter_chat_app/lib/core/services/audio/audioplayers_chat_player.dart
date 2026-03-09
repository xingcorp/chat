/// [IChatAudioPlayer] implementation backed by `audioplayers`.
///
/// Used on **Windows** where `just_audio` is not supported.
/// On other platforms [JustAudioChatPlayer] is used instead.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_chat_app/core/services/audio/i_chat_audio_player.dart';

class AudioPlayersChatPlayer implements IChatAudioPlayer {
  AudioPlayersChatPlayer() : _delegate = ap.AudioPlayer();

  final ap.AudioPlayer _delegate;

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<ChatPlayerState> _stateController =
      StreamController<ChatPlayerState>.broadcast();

  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];
  bool _subscribed = false;
  bool _disposed = false;

  void _ensureSubscriptions() {
    if (_subscribed) return;
    _subscribed = true;

    _subs.add(
      _delegate.onPositionChanged.listen((position) {
        if (!_disposed) _positionController.add(position);
      }),
    );

    _subs.add(
      _delegate.onDurationChanged.listen((duration) {
        if (!_disposed) _durationController.add(duration);
      }),
    );

    _subs.add(
      _delegate.onPlayerStateChanged.listen((apState) {
        if (_disposed) return;
        _stateController.add(ChatPlayerState(
          isPlaying: apState == ap.PlayerState.playing,
          isCompleted: apState == ap.PlayerState.completed,
          isBuffering: false, // audioplayers does not expose buffering
        ));
      }),
    );

    _subs.add(
      _delegate.onPlayerComplete.listen((_) {
        if (_disposed) return;
        _positionController.add(Duration.zero);
        _stateController.add(const ChatPlayerState(
          isPlaying: false,
          isCompleted: true,
        ));
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  @override
  Stream<Duration> get positionStream {
    _ensureSubscriptions();
    return _positionController.stream;
  }

  @override
  Stream<Duration?> get durationStream {
    _ensureSubscriptions();
    return _durationController.stream;
  }

  @override
  Stream<ChatPlayerState> get playerStateStream {
    _ensureSubscriptions();
    return _stateController.stream;
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  @override
  Future<Duration?> setSource(String url) async {
    _ensureSubscriptions();

    final ap.Source source = _resolveSource(url);
    await _delegate.setSource(source);

    // audioplayers may not return duration synchronously — try getting it.
    try {
      final duration = await _delegate.getDuration();
      if (duration != null && duration > Duration.zero) {
        _durationController.add(duration);
        return duration;
      }
    } catch (_) {
      // Ignored — duration will be emitted via onDurationChanged later.
    }
    return null;
  }

  @override
  Future<void> play() => _delegate.resume();

  @override
  Future<void> pause() => _delegate.pause();

  @override
  Future<void> seek(Duration position) => _delegate.seek(position);

  @override
  Future<void> stop() => _delegate.stop();

  @override
  Future<void> setVolume(double volume) => _delegate.setVolume(volume);

  @override
  Future<void> setSpeed(double speed) =>
      _delegate.setPlaybackRate(speed);

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    await _positionController.close();
    await _durationController.close();
    await _stateController.close();
    await _delegate.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ap.Source _resolveSource(String url) {
    final trimmed = url.trim();

    // Local file path
    if (trimmed.startsWith('/') ||
        (trimmed.length > 2 &&
            trimmed[1] == ':' &&
            (trimmed[2] == '\\' || trimmed[2] == '/'))) {
      return ap.DeviceFileSource(trimmed);
    }

    // file:// URI
    if (trimmed.startsWith('file://')) {
      final filePath = Uri.parse(trimmed).toFilePath();
      return ap.DeviceFileSource(filePath);
    }

    // Network URL (http / https)
    return ap.UrlSource(trimmed);
  }
}
