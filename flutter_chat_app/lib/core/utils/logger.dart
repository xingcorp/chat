import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Cấp độ log
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  wtf,
}

/// Class tiện ích để ghi log trong ứng dụng
class LogUtils {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    level: kDebugMode ? Level.verbose : Level.error,
  );
  
  static bool _enabledConsoleLog = kDebugMode;
  static bool _enabledFileLog = false;

  /// Bật/tắt ghi log ra console
  static set enabledConsoleLog(bool enabled) {
    _enabledConsoleLog = enabled;
  }

  /// Bật/tắt ghi log ra file
  static set enabledFileLog(bool enabled) {
    _enabledFileLog = enabled;
  }

  /// Ghi log với mức độ verbose
  static void v(String tag, String message) {
    _log(LogLevel.verbose, tag, message);
  }

  /// Ghi log với mức độ debug
  static void d(String tag, String message) {
    _log(LogLevel.debug, tag, message);
  }

  /// Ghi log với mức độ info
  static void i(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  /// Ghi log với mức độ warning
  static void w(String tag, String message) {
    _log(LogLevel.warning, tag, message);
  }

  /// Ghi log với mức độ error
  static void e(String tag, String message) {
    _log(LogLevel.error, tag, message);
  }

  /// Ghi log với mức độ wtf (what a terrible failure)
  static void wtf(String tag, String message) {
    _log(LogLevel.wtf, tag, message);
  }

  /// Phương thức ghi log chung
  static void _log(LogLevel level, String tag, String message) {
    if (!_enabledConsoleLog && !_enabledFileLog) return;

    final String logMessage = '[$tag] $message';

    if (_enabledConsoleLog) {
      switch (level) {
        case LogLevel.verbose:
          _logger.t(logMessage);
          break;
        case LogLevel.debug:
          _logger.d(logMessage);
          break;
        case LogLevel.info:
          _logger.i(logMessage);
          break;
        case LogLevel.warning:
          _logger.w(logMessage);
          break;
        case LogLevel.error:
          _logger.e(logMessage);
          break;
        case LogLevel.wtf:
          _logger.wtf(logMessage);
          break;
      }
    }
    
    // Log sử dụng dart:developer để có thể xem trong DevTools
    developer.log(
      message,
      name: tag,
      level: _getLogLevel(level),
    );
    
    // TODO: Implement file logging if needed
    if (_enabledFileLog) {
      // Write log to file
    }
  }
  
  /// Chuyển đổi LogLevel thành level của dart:developer
  static int _getLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 500;
      case LogLevel.debug:
        return 700;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.wtf:
        return 1200;
    }
  }
}

/// Enterprise-grade AppLogger for permissions service
/// Provides structured logging với performance tracking
/// 
/// Registered manually in core_module.dart
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 3,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.trace : Level.error,
  );

  /// Log info message
  void info(String message, [Map<String, dynamic>? context]) {
    _logWithContext(Level.info, message, context);
  }
  
  /// Log info message (alias for info)
  void i(String message, [Map<String, dynamic>? context]) {
    info(message, context);
  }

  /// Log debug message
  void debug(String message, [Map<String, dynamic>? context]) {
    _logWithContext(Level.debug, message, context);
  }
  
  /// Log debug message (alias for debug)
  void d(String message, [Map<String, dynamic>? context]) {
    debug(message, context);
  }

  /// Log warning message
  void warning(String message, [Map<String, dynamic>? context]) {
    _logWithContext(Level.warning, message, context);
  }

  /// Log warning message (compat alias for legacy callers)
  void warn(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.w(message, error: error, stackTrace: stackTrace);
    } else {
      _logger.w(message);
    }
  }
  
  /// Log warning message (alias for warning)
  void w(String message, [Map<String, dynamic>? context]) {
    warning(message, context);
  }

  /// Log error message
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    } else {
      _logger.e(message);
    }
  }
  
  /// Log error message (alias for error)
  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    this.error(message, error, stackTrace);
  }

  /// Log trace message
  void trace(String message, [Map<String, dynamic>? context]) {
    _logWithContext(Level.trace, message, context);
  }

  /// Log fatal message
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.f(message, error: error, stackTrace: stackTrace);
    } else {
      _logger.f(message);
    }
  }

  /// Private method để log với context
  void _logWithContext(Level level, String message, Map<String, dynamic>? context) {
    final contextStr = context != null ? ' | Context: $context' : '';
    final fullMessage = '$message$contextStr';

    switch (level) {
      case Level.trace:
        _logger.t(fullMessage);
        break;
      case Level.debug:
        _logger.d(fullMessage);
        break;
      case Level.info:
        _logger.i(fullMessage);
        break;
      case Level.warning:
        _logger.w(fullMessage);
        break;
      case Level.error:
        _logger.e(fullMessage);
        break;
      case Level.fatal:
        _logger.f(fullMessage);
        break;
      default:
        _logger.i(fullMessage);
    }
  }
}


/// Global logger instance for convenience
/// Use this for quick logging without dependency injection
final logger = AppLogger();
