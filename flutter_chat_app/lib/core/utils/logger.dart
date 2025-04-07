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
          _logger.v(logMessage);
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