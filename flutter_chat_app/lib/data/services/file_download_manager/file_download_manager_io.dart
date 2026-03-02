import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/services/file_download_state.dart';
import 'package:flutter_chat_app/domain/services/i_file_download_manager.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

const String _downloadPortName = 'oxii_file_download_port';

@pragma('vm:entry-point')
void fileDownloadManagerCallback(String id, int status, int progress) {
  final SendPort? sendPort =
      IsolateNameServer.lookupPortByName(_downloadPortName);
  sendPort?.send(<dynamic>[id, status, progress]);
}

IFileDownloadManager createFileDownloadManagerImpl(AppLogger logger) {
  return _IoFileDownloadManager(logger);
}

class _IoFileDownloadManager implements IFileDownloadManager {
  _IoFileDownloadManager(this._logger) {
    unawaited(_initialize());
  }

  final AppLogger _logger;
  final ReceivePort _receivePort = ReceivePort();
  final Completer<void> _initializationCompleter = Completer<void>();
  final Map<String, FileDownloadState> _states = <String, FileDownloadState>{};
  final Map<String, StreamController<FileDownloadState>> _controllers =
      <String, StreamController<FileDownloadState>>{};
  final Map<String, String> _taskIdByKey = <String, String>{};
  final Map<String, String> _keyByTaskId = <String, String>{};

  static bool _callbackRegistered = false;

  static const List<TargetPlatform> _backgroundDownloadPlatforms =
      <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ];

  @override
  FileDownloadState stateOf(String key) {
    return _states[key] ?? FileDownloadState.idle(key);
  }

  @override
  Stream<FileDownloadState> watch(String key) async* {
    yield stateOf(key);
    yield* _controllerFor(key).stream;
  }

  @override
  Future<Either<Failure, FileDownloadState>> startDownload({
    required String key,
    required String url,
    String? fileName,
    Map<String, String>? headers,
  }) async {
    await _ensureInitialized();

    final Uri? uri = _resolveUri(url);
    if (uri == null) {
      return const Left(
        ValidationFailure(
          message: 'Invalid file URL.',
          code: 'invalid_input',
        ),
      );
    }

    final FileDownloadState current = stateOf(key);
    if (current.isInProgress) {
      return Right(current);
    }

    if (_backgroundDownloadPlatforms.contains(defaultTargetPlatform)) {
      return _startBackgroundDownload(
        key: key,
        uri: uri,
        fileName: fileName,
        headers: headers,
        currentState: current,
      );
    }

    return _startExternalDownload(
      key: key,
      uri: uri,
      fileName: fileName,
      currentState: current,
    );
  }

  @override
  Future<Either<Failure, void>> cancelDownload(String key) async {
    await _ensureInitialized();

    final FileDownloadState current = stateOf(key);
    if (!current.isInProgress) {
      return const Right(null);
    }

    final String? taskId = current.taskId ?? _taskIdByKey[key];
    if (taskId == null || taskId.isEmpty) {
      _emit(current.copyWith(status: FileDownloadStatus.canceled, progress: 0));
      return const Right(null);
    }

    try {
      await FlutterDownloader.cancel(taskId: taskId);
      _emit(current.copyWith(status: FileDownloadStatus.canceled, progress: 0));
      return const Right(null);
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to cancel download task',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        DownloadFailure(
          message: 'Failed to cancel download task: $error',
          code: 'download_failed',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> openDownloadedFile(String key) async {
    await _ensureInitialized();

    final FileDownloadState current = stateOf(key);
    if (!current.canOpen) {
      return const Left(
        ValidationFailure(
          message: 'No downloaded file available to open.',
          code: 'invalid_input',
        ),
      );
    }

    final String? taskId = current.taskId ?? _taskIdByKey[key];
    if (_backgroundDownloadPlatforms.contains(defaultTargetPlatform) &&
        taskId != null &&
        taskId.isNotEmpty) {
      final bool opened = await FlutterDownloader.open(taskId: taskId);
      if (opened) {
        return const Right(null);
      }
    }

    final String? localPath = current.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      try {
        final bool launched = await launchUrl(
          Uri.file(localPath),
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return const Right(null);
        }
      } catch (error, stackTrace) {
        _logger.e(
          'Failed to open local downloaded file',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final String? sourceUrl = current.sourceUrl;
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      final Uri? uri = _resolveUri(sourceUrl);
      if (uri != null) {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return const Right(null);
        }
      }
    }

    return const Left(
      DownloadFailure(
        message: 'Unable to open downloaded file.',
        code: 'download_failed',
      ),
    );
  }

  Future<void> _initialize() async {
    try {
      _bindBackgroundPort();

      if (_backgroundDownloadPlatforms.contains(defaultTargetPlatform) &&
          !_callbackRegistered) {
        await FlutterDownloader.registerCallback(fileDownloadManagerCallback);
        _callbackRegistered = true;
      }
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to initialize file download manager',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
    }
  }

  Future<void> _ensureInitialized() {
    return _initializationCompleter.future;
  }

  void _bindBackgroundPort() {
    IsolateNameServer.removePortNameMapping(_downloadPortName);
    final bool registered = IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      _downloadPortName,
    );
    if (!registered) {
      IsolateNameServer.removePortNameMapping(_downloadPortName);
      IsolateNameServer.registerPortWithName(
        _receivePort.sendPort,
        _downloadPortName,
      );
    }

    _receivePort.listen((dynamic data) {
      if (data is! List<dynamic> || data.length < 3) {
        return;
      }

      final String taskId = data[0].toString();
      final int? statusValue = data[1] as int?;
      final int? progressValue = data[2] as int?;
      if (statusValue == null || progressValue == null) {
        return;
      }

      unawaited(
        _onTaskStatusChanged(
          taskId: taskId,
          statusValue: statusValue,
          progress: progressValue,
        ),
      );
    });
  }

  Future<void> _onTaskStatusChanged({
    required String taskId,
    required int statusValue,
    required int progress,
  }) async {
    final String? key = _keyByTaskId[taskId];
    if (key == null) {
      return;
    }

    final FileDownloadState current = stateOf(key);
    final int normalizedProgress = _normalizeProgress(progress);

    DownloadTaskStatus nativeStatus;
    try {
      nativeStatus = DownloadTaskStatus.fromInt(statusValue);
    } catch (_) {
      nativeStatus = DownloadTaskStatus.undefined;
    }

    switch (nativeStatus) {
      case DownloadTaskStatus.enqueued:
        _emit(
          current.copyWith(
            status: FileDownloadStatus.enqueued,
            progress: normalizedProgress,
            clearErrorMessage: true,
          ),
        );
        return;
      case DownloadTaskStatus.running:
        _emit(
          current.copyWith(
            status: FileDownloadStatus.downloading,
            progress: normalizedProgress,
            clearErrorMessage: true,
          ),
        );
        return;
      case DownloadTaskStatus.complete:
        final DownloadTask? task = await _loadTask(taskId);
        final String? resolvedFileName = task?.filename ?? current.fileName;
        final String? resolvedPath =
            _resolveTaskFilePath(task, resolvedFileName);
        _emit(
          current.copyWith(
            status: FileDownloadStatus.completed,
            progress: 100,
            fileName: resolvedFileName,
            localPath: resolvedPath,
            clearErrorMessage: true,
          ),
        );
        return;
      case DownloadTaskStatus.failed:
        _emit(
          current.copyWith(
            status: FileDownloadStatus.failed,
            progress: normalizedProgress,
            errorMessage: 'Download failed.',
          ),
        );
        return;
      case DownloadTaskStatus.canceled:
        _emit(
          current.copyWith(
            status: FileDownloadStatus.canceled,
            progress: 0,
            errorMessage: 'Download canceled.',
          ),
        );
        return;
      case DownloadTaskStatus.paused:
      case DownloadTaskStatus.undefined:
        _emit(
          current.copyWith(
            status: FileDownloadStatus.enqueued,
            progress: normalizedProgress,
          ),
        );
        return;
    }
  }

  Future<Either<Failure, FileDownloadState>> _startBackgroundDownload({
    required String key,
    required Uri uri,
    required FileDownloadState currentState,
    String? fileName,
    Map<String, String>? headers,
  }) async {
    try {
      final String saveDir = await _resolveDownloadDirectory();
      await Directory(saveDir).create(recursive: true);

      final String normalizedFileName = _normalizeFileName(
        fileName ?? _inferFileNameFromUri(uri),
      );
      final String? taskId = await FlutterDownloader.enqueue(
        url: uri.toString(),
        headers: headers ?? const <String, String>{},
        savedDir: saveDir,
        fileName: normalizedFileName,
        showNotification: true,
        openFileFromNotification: false,
      );

      if (taskId == null || taskId.isEmpty) {
        return const Left(
          DownloadFailure(
            message: 'Failed to enqueue download task.',
            code: 'download_failed',
          ),
        );
      }

      final String? previousTaskId = currentState.taskId;
      if (previousTaskId != null && previousTaskId.isNotEmpty) {
        _keyByTaskId.remove(previousTaskId);
      }
      _taskIdByKey[key] = taskId;
      _keyByTaskId[taskId] = key;

      final FileDownloadState enqueuedState = FileDownloadState(
        key: key,
        status: FileDownloadStatus.enqueued,
        progress: 0,
        sourceUrl: uri.toString(),
        taskId: taskId,
        fileName: normalizedFileName,
      );
      _emit(enqueuedState);

      _logger.i(
        'File download task enqueued',
        <String, dynamic>{
          'key': key,
          'taskId': taskId,
          'savedDir': saveDir,
          'fileName': normalizedFileName,
        },
      );
      return Right(enqueuedState);
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to enqueue file download',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        DownloadFailure(
          message: 'Failed to enqueue download: $error',
          code: 'download_failed',
        ),
      );
    }
  }

  Future<Either<Failure, FileDownloadState>> _startExternalDownload({
    required String key,
    required Uri uri,
    required FileDownloadState currentState,
    String? fileName,
  }) async {
    final FileDownloadState downloadingState = currentState.copyWith(
      status: FileDownloadStatus.downloading,
      progress: 0,
      sourceUrl: uri.toString(),
      fileName: fileName ?? currentState.fileName,
      clearErrorMessage: true,
    );
    _emit(downloadingState);

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final FileDownloadState failed = downloadingState.copyWith(
          status: FileDownloadStatus.failed,
          progress: 0,
          errorMessage: 'Unable to open file URL for download.',
        );
        _emit(failed);
        return const Left(
          DownloadFailure(
            message: 'Unable to open file URL for download.',
            code: 'download_failed',
          ),
        );
      }

      final FileDownloadState completed = downloadingState.copyWith(
        status: FileDownloadStatus.completed,
        progress: 100,
        clearErrorMessage: true,
      );
      _emit(completed);
      return Right(completed);
    } catch (error, stackTrace) {
      _logger.e(
        'External download launch failed',
        error: error,
        stackTrace: stackTrace,
      );
      final FileDownloadState failed = downloadingState.copyWith(
        status: FileDownloadStatus.failed,
        progress: 0,
        errorMessage: 'Failed to launch download URL: $error',
      );
      _emit(failed);
      return Left(
        DownloadFailure(
          message: 'Failed to launch download URL: $error',
          code: 'download_failed',
        ),
      );
    }
  }

  Future<String> _resolveDownloadDirectory() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir.path;
      }
    }

    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final Directory downloadsDir =
        Directory('${documentsDir.path}${Platform.pathSeparator}downloads');
    return downloadsDir.path;
  }

  Future<DownloadTask?> _loadTask(String taskId) async {
    final String escapedTaskId = taskId.replaceAll("'", "''");
    final List<DownloadTask>? tasks =
        await FlutterDownloader.loadTasksWithRawQuery(
      query: "SELECT * FROM task WHERE task_id = '$escapedTaskId' LIMIT 1",
    );
    if (tasks == null || tasks.isEmpty) {
      return null;
    }
    return tasks.first;
  }

  String? _resolveTaskFilePath(DownloadTask? task, String? fallbackFileName) {
    if (task == null) {
      return null;
    }

    final String? fileName =
        (task.filename != null && task.filename!.trim().isNotEmpty)
            ? task.filename!.trim()
            : fallbackFileName;
    if (fileName == null || fileName.isEmpty) {
      return null;
    }

    return p.join(task.savedDir, fileName);
  }

  String _inferFileNameFromUri(Uri uri) {
    if (uri.pathSegments.isEmpty) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }

    final String lastSegment = uri.pathSegments.last.trim();
    if (lastSegment.isEmpty) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }

    return Uri.decodeComponent(lastSegment);
  }

  String _normalizeFileName(String value) {
    final String sanitized =
        value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (sanitized.isEmpty) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
    return sanitized;
  }

  Uri? _resolveUri(String rawUrl) {
    if (rawUrl.trim().isEmpty) {
      return null;
    }

    final Uri? parsed = Uri.tryParse(rawUrl.trim());
    if (parsed == null || !parsed.hasScheme) {
      return null;
    }
    return parsed;
  }

  int _normalizeProgress(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > 100) {
      return 100;
    }
    return value;
  }

  StreamController<FileDownloadState> _controllerFor(String key) {
    return _controllers.putIfAbsent(
      key,
      StreamController<FileDownloadState>.broadcast,
    );
  }

  void _emit(FileDownloadState state) {
    _states[state.key] = state;
    _controllerFor(state.key).add(state);
  }
}
