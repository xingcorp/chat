import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// A service for logging with different severity levels,
/// stacktrace support, and configurable outputs.
class LoggerService {
  /// The logger instance
  final Logger _logger;
  
  /// Tag for identifying this logger's output
  final String _tag;
  
  /// Whether to enable debug logs
  final bool _enableDebugLogs;
  
  /// Create a new logger service
  LoggerService({
    required String tag,
    bool enableDebugLogs = kDebugMode,
    Logger? logger,
  }) : _tag = tag,
       _enableDebugLogs = enableDebugLogs,
       _logger = logger ?? Logger(
         printer: PrettyPrinter(
           methodCount: 2,
           errorMethodCount: 8,
           lineLength: 120,
           colors: true,
           printEmojis: true,
           dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
         ),
         level: kDebugMode ? Level.trace : Level.info,
       );
  
  /// Log a debug message
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_enableDebugLogs) return;
    if (error != null) {
      _logger.d('[$_tag] $message', error: error, stackTrace: stackTrace);
    } else {
      _logger.d('[$_tag] $message');
    }
  }
  
  /// Log an info message
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.i('[$_tag] $message', error: error, stackTrace: stackTrace);
    } else {
      _logger.i('[$_tag] $message');
    }
  }
  
  /// Log a warning message
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.w('[$_tag] $message', error: error, stackTrace: stackTrace);
    } else {
      _logger.w('[$_tag] $message');
    }
  }
  
  /// Log an error message
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.e('[$_tag] $message', error: error, stackTrace: stackTrace);
    } else {
      _logger.e('[$_tag] $message');
    }
  }
  
  /// Log a fatal error message
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.f('[$_tag] $message', error: error, stackTrace: stackTrace);
    } else {
      _logger.f('[$_tag] $message');
    }
  }
  
  /// Log a critical message that should always be shown
  void critical(String message, [dynamic error, StackTrace? stackTrace]) {
    // Log to console regardless of config using logger
    _logger.f('CRITICAL [$_tag] $message', error: error, stackTrace: stackTrace);
    
    // Also log through the logger
    if (error != null) {
      _logger.f('CRITICAL [$_tag] $message', error: error, stackTrace: stackTrace);
    } else {
      _logger.f('CRITICAL [$_tag] $message');
    }
  }
} 