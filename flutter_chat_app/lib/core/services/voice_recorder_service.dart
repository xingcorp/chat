import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

enum VoiceRecorderPermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

abstract class IAudioRecorder {
  Future<bool> isRecording();
  Future<bool> hasPermission();
  Future<void> start(RecordConfig config, {required String path});
  Future<String?> stop();
  Future<Amplitude> getAmplitude();
  Future<void> dispose();
}

class RecordAudioRecorder implements IAudioRecorder {
  RecordAudioRecorder([AudioRecorder? delegate])
      : _delegate = delegate ?? AudioRecorder();

  final AudioRecorder _delegate;

  @override
  Future<bool> isRecording() => _delegate.isRecording();

  @override
  Future<bool> hasPermission() => _delegate.hasPermission();

  @override
  Future<void> start(RecordConfig config, {required String path}) {
    return _delegate.start(config, path: path);
  }

  @override
  Future<String?> stop() => _delegate.stop();

  @override
  Future<Amplitude> getAmplitude() => _delegate.getAmplitude();

  @override
  Future<void> dispose() => _delegate.dispose();
}

class VoiceRecorderService {
  VoiceRecorderService({
    required AppLogger logger,
    IAudioRecorder? recorder,
    Future<PermissionStatus> Function()? microphoneStatusProvider,
    Future<PermissionStatus> Function()? microphoneRequestProvider,
    Future<Directory> Function()? tempDirectoryProvider,
    Duration maxRecordingDuration = const Duration(minutes: 5),
  })  : _logger = logger,
        _recorder = recorder ?? RecordAudioRecorder(),
        _microphoneStatusProvider =
            microphoneStatusProvider ?? (() => Permission.microphone.status),
        _microphoneRequestProvider = microphoneRequestProvider ??
            (() => Permission.microphone.request()),
        _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory,
        _maxRecordingDuration = maxRecordingDuration;

  final AppLogger _logger;
  final IAudioRecorder _recorder;
  final Future<PermissionStatus> Function() _microphoneStatusProvider;
  final Future<PermissionStatus> Function() _microphoneRequestProvider;
  final Future<Directory> Function() _tempDirectoryProvider;
  final Duration _maxRecordingDuration;

  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  final StreamController<String> _recordingLimitReachedController =
      StreamController<String>.broadcast();

  Timer? _maxDurationTimer;
  Timer? _amplitudeTimer;
  String? _recordingFilePath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  Stream<String> get recordingLimitReachedStream =>
      _recordingLimitReachedController.stream;

  Future<VoiceRecorderPermissionResult> ensurePermission() async {
    if (kIsWeb) {
      final granted = await _recorder.hasPermission();
      return granted
          ? VoiceRecorderPermissionResult.granted
          : VoiceRecorderPermissionResult.denied;
    }

    final currentStatus = await _microphoneStatusProvider();
    if (currentStatus.isGranted) {
      return VoiceRecorderPermissionResult.granted;
    }

    if (currentStatus.isPermanentlyDenied || currentStatus.isRestricted) {
      return VoiceRecorderPermissionResult.permanentlyDenied;
    }

    final requestedStatus = await _microphoneRequestProvider();
    if (requestedStatus.isGranted) {
      return VoiceRecorderPermissionResult.granted;
    }

    if (requestedStatus.isPermanentlyDenied || requestedStatus.isRestricted) {
      return VoiceRecorderPermissionResult.permanentlyDenied;
    }

    return VoiceRecorderPermissionResult.denied;
  }

  Future<bool> requestPermission() async {
    final result = await ensurePermission();
    return result == VoiceRecorderPermissionResult.granted;
  }

  Future<bool> startRecording() async {
    if (_isRecording || await _recorder.isRecording()) return false;

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      _logger.w('VoiceRecorderService.startRecording denied by permission');
      return false;
    }

    final directory = await _tempDirectoryProvider();
    final fileName = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final filePath = p.join(directory.path, fileName);

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );

      _recordingFilePath = filePath;
      _isRecording = true;
      _startAmplitudeMonitoring();
      _startMaxDurationTimer();
      return true;
    } catch (error, stackTrace) {
      _logger.e(
        'VoiceRecorderService.startRecording failed',
        error: error,
        stackTrace: stackTrace,
      );
      _cleanupTimers();
      _isRecording = false;
      _recordingFilePath = null;
      await _deleteFileIfExists(filePath);
      return false;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording && !await _recorder.isRecording()) return null;

    try {
      final stoppedPath = await _recorder.stop();
      final filePath = stoppedPath ?? _recordingFilePath;

      _cleanupTimers();
      _isRecording = false;
      _recordingFilePath = null;
      _amplitudeController.add(0.0);

      return filePath;
    } catch (error, stackTrace) {
      _logger.e(
        'VoiceRecorderService.stopRecording failed',
        error: error,
        stackTrace: stackTrace,
      );
      _cleanupTimers();
      _isRecording = false;
      _recordingFilePath = null;
      return null;
    }
  }

  Future<void> cancelRecording() async {
    String? filePath;

    if (_isRecording || await _recorder.isRecording()) {
      try {
        filePath = await _recorder.stop();
      } catch (error, stackTrace) {
        _logger.e(
          'VoiceRecorderService.cancelRecording stop failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _cleanupTimers();
    _isRecording = false;
    _amplitudeController.add(0.0);

    final targetPath = filePath ?? _recordingFilePath;
    _recordingFilePath = null;
    await _deleteFileIfExists(targetPath);
  }

  Future<void> deleteTempFile(String? filePath) async {
    await _deleteFileIfExists(filePath);
  }

  Future<void> dispose() async {
    _cleanupTimers();
    await _recorder.dispose();
    await _amplitudeController.close();
    await _recordingLimitReachedController.close();
  }

  void _startMaxDurationTimer() {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(_maxRecordingDuration, () {
      unawaited(_handleMaxDurationReached());
    });
  }

  Future<void> _handleMaxDurationReached() async {
    final path = await stopRecording();
    if (path != null) {
      _recordingLimitReachedController.add(path);
    }
  }

  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) async {
        final recorderIsRecording = await _recorder.isRecording();
        if (!_isRecording && !recorderIsRecording) return;
        try {
          final amplitude = await _recorder.getAmplitude();
          _amplitudeController.add(_normalizeAmplitude(amplitude.current));
        } catch (_) {
          _amplitudeController.add(0.0);
        }
      },
    );
  }

  double _normalizeAmplitude(double decibel) {
    if (decibel.isNaN || decibel.isInfinite) return 0.0;
    const minDecibel = -45.0;
    final normalized = (decibel - minDecibel) / (0 - minDecibel);
    return normalized.clamp(0.0, 1.0);
  }

  void _cleanupTimers() {
    _maxDurationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _maxDurationTimer = null;
    _amplitudeTimer = null;
  }

  Future<void> _deleteFileIfExists(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;

    try {
      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (error, stackTrace) {
      _logger.w(
        'VoiceRecorderService.deleteFile failed for $filePath',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
