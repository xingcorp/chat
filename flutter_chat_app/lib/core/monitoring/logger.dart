import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Lớp cung cấp chức năng ghi log cho ứng dụng
class AppLogger {
  static AppLogger? _instance;
  static AppLogger get instance => _instance!;
  
  /// Logger instance từ package logger
  late final Logger _logger;
  
  /// Cấp độ log hiện tại
  LogLevel _currentLevel = LogLevel.debug;
  
  /// Danh sách các log gần đây để hiển thị trong debug UI
  final List<LogEntry> _recentLogs = [];
  
  /// Số lượng log tối đa lưu trong bộ nhớ
  static const int _maxLogEntries = 1000;
  
  /// Khởi tạo logger
  static void init({LogLevel level = LogLevel.debug}) {
    if (_instance != null) return;
    
    _instance = AppLogger._();
    _instance!._currentLevel = level;
    
    _instance!.debug('AppLogger: Đã khởi tạo với level ${level.name}');
  }
  
  AppLogger._() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      filter: _CustomLogFilter(_currentLevel),
      output: _MultiOutput([
        ConsoleOutput(),
        _MemoryOutput(_addLogEntry),
      ]),
    );
  }

  /// Log debug message
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log warning message
  void warn(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log critical error message
  void critical(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
  
  /// Cập nhật cấp độ log
  void setLogLevel(LogLevel level) {
    _currentLevel = level;
    // Note: Logger package không còn hỗ trợ dynamic filter update
    // Cần tạo lại logger instance với filter mới
    info('Đã cập nhật log level thành: ${level.name}');
  }
  
  /// Lấy cấp độ log hiện tại
  LogLevel getLogLevel() {
    return _currentLevel;
  }
  
  /// Lấy danh sách log gần đây
  List<LogEntry> getRecentLogs() {
    return List.from(_recentLogs);
  }
  
  /// Lấy danh sách log gần đây theo cấp độ
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _recentLogs.where((log) => log.level.index >= level.index).toList();
  }
  
  /// Xóa tất cả log
  void clearLogs() {
    _recentLogs.clear();
    debug('Đã xóa tất cả log');
  }
  
  /// Thêm một log vào danh sách gần đây
  void _addLogEntry(LogEntry entry) {
    _recentLogs.insert(0, entry);
    
    // Đảm bảo số lượng log không vượt quá giới hạn
    if (_recentLogs.length > _maxLogEntries) {
      _recentLogs.removeLast();
    }
  }
}

/// Các cấp độ log
enum LogLevel {
  verbose,  // Mọi log
  debug,    // Debug
  info,     // Thông tin
  warning,  // Cảnh báo
  error,    // Lỗi
  critical, // Lỗi nghiêm trọng
  nothing,  // Không log gì
}

/// Mục nhập log
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  
  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });
}

/// Bộ lọc log tùy chỉnh
class _CustomLogFilter extends LogFilter {
  final LogLevel _logLevel;

  _CustomLogFilter(this._logLevel);

  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode && _logLevel.index < LogLevel.info.index) {
      return false;
    }

    var logLevel = _mapLevelToLogLevel(event.level);
    return logLevel.index >= _logLevel.index;
  }
  
  LogLevel _mapLevelToLogLevel(Level level) {
    switch (level) {
      case Level.trace:
        return LogLevel.verbose;
      case Level.debug:
        return LogLevel.debug;
      case Level.info:
        return LogLevel.info;
      case Level.warning:
        return LogLevel.warning;
      case Level.error:
        return LogLevel.error;
      case Level.fatal:
        return LogLevel.critical;
      default:
        return LogLevel.debug;
    }
  }
}

/// Đầu ra log đến nhiều nơi
class _MultiOutput extends LogOutput {
  final List<LogOutput> outputs;
  
  _MultiOutput(this.outputs);
  
  @override
  void output(OutputEvent event) {
    for (var output in outputs) {
      output.output(event);
    }
  }
}

/// Đầu ra log vào bộ nhớ
class _MemoryOutput extends LogOutput {
  final Function(LogEntry) onLogAdded;
  
  _MemoryOutput(this.onLogAdded);
  
  @override
  void output(OutputEvent event) {
    for (var i = 0; i < event.lines.length; i++) {
      final logLevel = _mapLevelToLogLevel(event.level);

      onLogAdded(LogEntry(
        timestamp: DateTime.now(),
        level: logLevel,
        message: event.lines[i],
        error: null, // OutputEvent không còn có error property
        stackTrace: null, // OutputEvent không còn có stackTrace property
      ));
    }
  }
  
  LogLevel _mapLevelToLogLevel(Level level) {
    switch (level) {
      case Level.trace:
        return LogLevel.verbose;
      case Level.debug:
        return LogLevel.debug;
      case Level.info:
        return LogLevel.info;
      case Level.warning:
        return LogLevel.warning;
      case Level.error:
        return LogLevel.error;
      case Level.fatal:
        return LogLevel.critical;
      default:
        return LogLevel.debug;


    }
  }
} 