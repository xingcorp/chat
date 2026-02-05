import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';

import '../config/production_config.dart';

/// **ENTERPRISE PRODUCTION LOGGING SERVICE**
///
/// Comprehensive logging service for enterprise Flutter chat app with
/// file logging, remote logging, crash reporting, and performance monitoring.
///
/// **Features:**
/// - Environment-specific log levels
/// - File-based logging with rotation
/// - Remote logging for production monitoring
/// - Structured logging with context
/// - Performance and error tracking
/// - Crash reporting integration
///
/// **Architecture**: Production-ready logging with enterprise standards
/// 
/// Registered manually in core_module.dart
class ProductionLogger {
  static const String _logFileName = 'flutter_chat_app.log';
  static const int _maxLogFileSize = 10 * 1024 * 1024; // 10MB
  static const int _maxLogFiles = 5;

  late final Logger _logger;
  late final LoggingConfig _config;
  File? _logFile;
  int _currentLogSize = 0;

  /// **Initialize production logger**
  Future<void> initialize() async {
    _config = ProductionConfig.logging;
    
    // Configure logger based on environment
    _logger = Logger(
      level: _config.level,
      printer: _createLogPrinter(),
      output: _createLogOutput(),
    );

    // Initialize file logging if enabled
    if (_config.enableFileLogging && !kIsWeb) {
      await _initializeFileLogging();
    }

    // Log initialization
    info('ProductionLogger initialized', context: {
      'environment': ProductionConfig.environment.name,
      'level': _config.level.name,
      'fileLogging': _config.enableFileLogging,
      'remoteLogging': _config.enableRemoteLogging,
    });
  }

  /// **Create log printer based on environment**
  LogPrinter _createLogPrinter() {
    if (ProductionConfig.isProduction) {
      return ProductionLogPrinter();
    } else {
      return PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      );
    }
  }

  /// **Create log output based on configuration**
  LogOutput _createLogOutput() {
    final outputs = <LogOutput>[];

    // Console output
    if (_config.enableConsoleOutput) {
      outputs.add(ConsoleOutput());
    }

    // File output
    if (_config.enableFileLogging) {
      outputs.add(FileLogOutput(this));
    }

    // Remote output
    if (_config.enableRemoteLogging) {
      outputs.add(RemoteLogOutput());
    }

    return MultiOutput(outputs);
  }

  /// **Initialize file logging**
  Future<void> _initializeFileLogging() async {
    if (kIsWeb) {
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logFile = File('${logDir.path}/$_logFileName');
      
      if (await _logFile!.exists()) {
        _currentLogSize = await _logFile!.length();
      }

      // Rotate logs if needed
      await _rotateLogsIfNeeded();
    } catch (e) {
      debugPrint('Failed to initialize file logging: $e');
    }
  }

  /// **Rotate log files if needed**
  Future<void> _rotateLogsIfNeeded() async {
    if (_logFile == null || _currentLogSize < _maxLogFileSize) {
      return;
    }

    try {
      final directory = _logFile!.parent;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rotatedFile = File('${directory.path}/flutter_chat_app_$timestamp.log');
      
      await _logFile!.rename(rotatedFile.path);
      _logFile = File('${directory.path}/$_logFileName');
      _currentLogSize = 0;

      // Clean up old log files
      await _cleanupOldLogs();
    } catch (e) {
      debugPrint('Failed to rotate logs: $e');
    }
  }

  /// **Clean up old log files**
  Future<void> _cleanupOldLogs() async {
    try {
      final directory = _logFile!.parent;
      final logFiles = await directory
          .list()
          .where((entity) => entity is File && entity.path.contains('flutter_chat_app_'))
          .cast<File>()
          .toList();

      // Sort by modification time (newest first)
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Keep only the most recent files
      if (logFiles.length > _maxLogFiles) {
        for (int i = _maxLogFiles; i < logFiles.length; i++) {
          await logFiles[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old logs: $e');
    }
  }

  /// **Write log to file**
  Future<void> _writeToFile(String message) async {
    if (_logFile == null) return;

    try {
      await _logFile!.writeAsString(
        '$message\n',
        mode: FileMode.append,
        encoding: utf8,
      );
      
      _currentLogSize += message.length + 1;
      
      // Rotate if needed
      if (_currentLogSize >= _maxLogFileSize) {
        await _rotateLogsIfNeeded();
      }
    } catch (e) {
      debugPrint('Failed to write to log file: $e');
    }
  }

  /// **Debug level logging**
  void debug(String message, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
    _logWithContext(Level.debug, message, context, error, stackTrace);
  }

  /// **Info level logging**
  void info(String message, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
    _logWithContext(Level.info, message, context, error, stackTrace);
  }

  /// **Warning level logging**
  void warning(String message, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
    _logWithContext(Level.warning, message, context, error, stackTrace);
  }

  /// **Error level logging**
  void error(String message, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _logWithContext(Level.error, message, context, error, stackTrace);
  }

  /// **Fatal level logging**
  void fatal(String message, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    _logWithContext(Level.fatal, message, context, error, stackTrace);
  }

  /// **Log with context information**
  void _logWithContext(Level level, String message, Map<String, dynamic>? context, Object? error, StackTrace? stackTrace) {
    if (_config.enableRemoteLogging && level.index >= Level.warning.index) {
      _sendToRemoteLogging(level, message, context, error, stackTrace);
    }
  }

  /// **Send log to remote logging service**
  Future<void> _sendToRemoteLogging(Level level, String message, Map<String, dynamic>? context, Object? error, StackTrace? stackTrace) async {
    try {
      final platformName = kIsWeb ? 'web' : Platform.operatingSystem;
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'level': level.name,
        'message': message,
        'environment': ProductionConfig.environment.name,
        'platform': platformName,
        'version': '1.0.0', // TODO: Get from package info
        if (context != null) 'context': context,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      };

      // TODO: Send to remote logging service (e.g., Firebase, Sentry, etc.)
      // This would be implemented based on the chosen remote logging solution
      debugPrint('Remote log: ${jsonEncode(logData)}');
    } catch (e) {
      debugPrint('Failed to send remote log: $e');
    }
  }

  /// **Log performance metrics**
  void logPerformance(String operation, Duration duration, {Map<String, dynamic>? context}) {
    final performanceData = {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    };

    info('Performance: $operation took ${duration.inMilliseconds}ms', context: performanceData);
  }

  /// **Log user action**
  void logUserAction(String action, {Map<String, dynamic>? context}) {
    final actionData = {
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': context?['user_id'] ?? 'anonymous',
      ...?context,
    };

    info('User action: $action', context: actionData);
  }

  /// **Log network request**
  void logNetworkRequest(String method, String url, int statusCode, Duration duration, {Map<String, dynamic>? context}) {
    final networkData = {
      'method': method,
      'url': url,
      'status_code': statusCode,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    };

    if (statusCode >= 400) {
      warning('Network request failed: $method $url ($statusCode)', context: networkData);
    } else {
      info('Network request: $method $url ($statusCode)', context: networkData);
    }
  }

  /// **Log crash or fatal error**
  void logCrash(Object error, StackTrace stackTrace, {Map<String, dynamic>? context}) {
    final platformName = kIsWeb ? 'web' : Platform.operatingSystem;
    final crashData = {
      'error': error.toString(),
      'stack_trace': stackTrace.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'environment': ProductionConfig.environment.name,
      'platform': platformName,
      ...?context,
    };

    fatal('Application crash', context: crashData, error: error, stackTrace: stackTrace);
    
    // TODO: Send to crash reporting service (e.g., Firebase Crashlytics, Sentry)
  }

  /// **Get log file path**
  String? get logFilePath => _logFile?.path;

  /// **Get current log size**
  int get currentLogSize => _currentLogSize;
}

/// **Production log printer**
class ProductionLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final timestamp = DateTime.now().toIso8601String();
    final level = event.level.name.toUpperCase();
    final message = event.message;
    
    return ['[$timestamp] [$level] $message'];
  }
}

/// **File log output**
class FileLogOutput extends LogOutput {
  final ProductionLogger logger;

  FileLogOutput(this.logger);

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      logger._writeToFile(line);
    }
  }
}

/// **Remote log output**
class RemoteLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // TODO: Implement remote logging output
    // This would send logs to a remote service
  }
}
