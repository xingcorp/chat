import 'dart:io';

import 'package:flutter_chat_app/core/services/voice_recorder_service.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class _FakeAudioRecorder implements IAudioRecorder {
  bool _isRecording = false;
  String? _lastPath;
  double amplitude = -10;
  bool permissionGranted = true;

  @override
  Future<bool> isRecording() async => _isRecording;

  @override
  Future<bool> hasPermission({bool request = true}) async => permissionGranted;

  @override
  Future<Amplitude> getAmplitude() async {
    return Amplitude(current: amplitude, max: amplitude);
  }

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    _isRecording = true;
    _lastPath = path;
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(const [1, 2, 3, 4], flush: true);
  }

  @override
  Future<String?> stop() async {
    _isRecording = false;
    return _lastPath;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('VoiceRecorderService', () {
    late Directory tempDir;
    late _FakeAudioRecorder recorder;
    late VoiceRecorderService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('voice-recorder-test');
      recorder = _FakeAudioRecorder();
      service = VoiceRecorderService(
        logger: AppLogger(),
        recorder: recorder,
        microphoneStatusProvider: () async => PermissionStatus.granted,
        microphoneRequestProvider: () async => PermissionStatus.granted,
        tempDirectoryProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      await service.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('starts and stops recording with granted permission', () async {
      final started = await service.startRecording();
      expect(started, isTrue);
      expect(service.isRecording, isTrue);

      final path = await service.stopRecording();
      expect(path, isNotNull);
      expect(path!.endsWith('.m4a'), isTrue);
      expect(await File(path).exists(), isTrue);
      expect(service.isRecording, isFalse);
    });

    test('does not start recording when permission is denied', () async {
      recorder.permissionGranted = false;
      service = VoiceRecorderService(
        logger: AppLogger(),
        recorder: recorder,
        microphoneStatusProvider: () async => PermissionStatus.denied,
        microphoneRequestProvider: () async => PermissionStatus.denied,
        tempDirectoryProvider: () async => tempDir,
      );

      final started = await service.startRecording();
      expect(started, isFalse);
      expect(service.isRecording, isFalse);
    });

    test('cancelling recording removes temp file', () async {
      final started = await service.startRecording();
      expect(started, isTrue);

      final filesBeforeCancel =
          tempDir.listSync().whereType<File>().toList(growable: false);
      expect(filesBeforeCancel, isNotEmpty);

      await service.cancelRecording();

      final filesAfterCancel =
          tempDir.listSync().whereType<File>().toList(growable: false);
      expect(filesAfterCancel, isEmpty);
    });

    test('emits recording limit event and auto-stops', () async {
      service = VoiceRecorderService(
        logger: AppLogger(),
        recorder: recorder,
        microphoneStatusProvider: () async => PermissionStatus.granted,
        microphoneRequestProvider: () async => PermissionStatus.granted,
        tempDirectoryProvider: () async => tempDir,
        maxRecordingDuration: const Duration(milliseconds: 60),
      );

      final started = await service.startRecording();
      expect(started, isTrue);

      final path = await service.recordingLimitReachedStream.first
          .timeout(const Duration(seconds: 1));
      expect(path, isNotEmpty);
      expect(service.isRecording, isFalse);
    });
  });
}
