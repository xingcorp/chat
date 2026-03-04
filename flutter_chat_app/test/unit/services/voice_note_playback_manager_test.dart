import 'dart:async';

import 'package:flutter_chat_app/core/services/voice_note_playback_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

class _FakeVoiceNoteAudioPlayer implements VoiceNoteAudioPlayer {
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();

  Duration resolvedDuration = const Duration(seconds: 18);
  Duration setUrlDelay = Duration.zero;
  int setUrlCallCount = 0;
  bool _isPlaying = false;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _playerStateController.add(
      PlayerState(false, ProcessingState.ready),
    );
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    _playerStateController.add(
      PlayerState(true, ProcessingState.ready),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    _positionController.add(position);
  }

  @override
  Future<Duration?> setUrl(String url) async {
    setUrlCallCount += 1;
    if (setUrlDelay > Duration.zero) {
      await Future<void>.delayed(setUrlDelay);
    }
    _durationController.add(resolvedDuration);
    _playerStateController.add(
      PlayerState(_isPlaying, ProcessingState.ready),
    );
    return resolvedDuration;
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _positionController.add(Duration.zero);
    _playerStateController.add(
      PlayerState(false, ProcessingState.idle),
    );
  }

  @override
  Future<void> dispose() async {
    await _positionController.close();
    await _durationController.close();
    await _playerStateController.close();
  }

  void emitCompleted() {
    _playerStateController.add(
      PlayerState(false, ProcessingState.completed),
    );
  }
}

void main() {
  group('VoiceNotePlaybackManager', () {
    late _FakeVoiceNoteAudioPlayer fakePlaybackPlayer;
    late _FakeVoiceNoteAudioPlayer fakeProbePlayer;
    late VoiceNotePlaybackManager manager;

    setUp(() {
      fakePlaybackPlayer = _FakeVoiceNoteAudioPlayer();
      fakeProbePlayer = _FakeVoiceNoteAudioPlayer();
      manager = VoiceNotePlaybackManager(
        audioPlayer: fakePlaybackPlayer,
        probeAudioPlayer: fakeProbePlayer,
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('plays selected message and exposes playing state', () async {
      final states = <VoiceNotePlaybackState>[];
      final subscription =
          manager.getPlaybackStream('message_1').listen(states.add);

      await manager.play('message_1', 'https://example.com/voice-note-1.m4a');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(states, isNotEmpty);
      final latest = states.last;
      expect(latest.isPlaying, isTrue);
      expect(latest.duration, const Duration(seconds: 18));

      await subscription.cancel();
    });

    test('starting another message stops previous message playback state',
        () async {
      final message1States = <VoiceNotePlaybackState>[];
      final message2States = <VoiceNotePlaybackState>[];
      final sub1 =
          manager.getPlaybackStream('message_1').listen(message1States.add);
      final sub2 =
          manager.getPlaybackStream('message_2').listen(message2States.add);

      await manager.play('message_1', 'https://example.com/voice-note-1.m4a');
      await manager.play('message_2', 'https://example.com/voice-note-2.m4a');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(message2States.last.isPlaying, isTrue);
      expect(message1States.last.isPlaying, isFalse);

      await sub1.cancel();
      await sub2.cancel();
    });

    test('completed playback resets position and playing flag', () async {
      final states = <VoiceNotePlaybackState>[];
      final subscription =
          manager.getPlaybackStream('message_1').listen(states.add);

      await manager.play('message_1', 'https://example.com/voice-note-1.m4a');
      fakePlaybackPlayer.emitCompleted();

      await Future<void>.delayed(const Duration(milliseconds: 20));

      final latest = states.last;
      expect(latest.isPlaying, isFalse);
      expect(latest.position, Duration.zero);
      expect(latest.duration, const Duration(seconds: 18));

      await subscription.cancel();
    });

    test('prefetch duration updates non-playing message stream', () async {
      final states = <VoiceNotePlaybackState>[];
      final subscription =
          manager.getPlaybackStream('message_1').listen(states.add);

      final resolved = await manager.prefetchDuration(
        messageId: 'message_1',
        audioUrl: 'https://example.com/voice-note-1.m4a',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(resolved, const Duration(seconds: 18));
      expect(states, isNotEmpty);
      expect(states.last.duration, const Duration(seconds: 18));

      await subscription.cancel();
    });

    test('prefetch deduplicates concurrent probes for same URL', () async {
      fakeProbePlayer.setUrlDelay = const Duration(milliseconds: 40);

      const url = 'https://example.com/voice-note-shared.m4a';
      await Future.wait([
        manager.prefetchDuration(messageId: 'message_1', audioUrl: url),
        manager.prefetchDuration(messageId: 'message_2', audioUrl: url),
      ]);

      expect(fakeProbePlayer.setUrlCallCount, 1);
      expect(
        manager.getKnownDuration(messageId: 'message_2', audioUrl: url),
        const Duration(seconds: 18),
      );
    });
  });
}
