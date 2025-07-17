
import 'package:logger/logger.dart';

import '../../monitoring/analytics_service.dart';
import 'socket_metric_types.dart';

/// Lớp theo dõi phân tích lỗi Socket
class SocketErrorAnalytics {
  final AnalyticsService _analyticsService;
  final Logger _logger;
  
  // Error tracking
  final Map<String, int> _failedEvents = {};
  final List<SocketErrorInfo> _recentErrors = [];
  
  // Maximum number of recent errors to keep
  final int _maxRecentErrors;
  
  // Total message count for error rate calculation
  int _totalMessageCount = 0;
  
  /// Constructor
  SocketErrorAnalytics({
    required AnalyticsService analyticsService,
    Logger? logger,
    int maxRecentErrors = 20,
  }) : 
    _analyticsService = analyticsService,
    _logger = logger ?? Logger(),
    _maxRecentErrors = maxRecentErrors;
  
  /// Track a failed socket event
  void trackEventFailure(String eventName, {
    String? errorMessage,
    SocketErrorType errorType = SocketErrorType.unknown,
  }) {
    _failedEvents[eventName] = (_failedEvents[eventName] ?? 0) + 1;
    
    // Create error info
    final errorInfo = SocketErrorInfo(
      eventName: eventName,
      message: errorMessage ?? 'unknown error',
      type: errorType,
      timestamp: DateTime.now(),
    );
    
    // Keep a limited list of recent errors
    if (_recentErrors.length >= _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }
    _recentErrors.add(errorInfo);
    
    // Log error to analytics
    _analyticsService.logEvent(
      AnalyticsEvent.custom,
      customEventName: 'socket_event_failure',
      parameters: {
        'event_type': eventName,
        'error': errorMessage ?? 'unknown error',
        'error_type': errorType.toString().split('.').last,
        'failure_count': _failedEvents[eventName],
      },
    );
  }
  
  /// Record total message count for error rate calculation
  void recordMessageCount(int count) {
    _totalMessageCount += count;
  }
  
  /// Get error rate percentage
  double get errorRate {
    final totalErrors = _failedEvents.values.fold(0, (sum, count) => sum + count);
    if (_totalMessageCount == 0) return 0.0;
    return (totalErrors / _totalMessageCount) * 100.0;
  }
  
  /// Get most frequent errors
  List<MapEntry<String, int>> getMostFrequentErrors({int limit = 5}) {
    final sortedEntries = _failedEvents.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return sortedEntries.take(limit).toList();
  }
  
  /// Get recent errors
  List<SocketErrorInfo> getRecentErrors() {
    return List.unmodifiable(_recentErrors.reversed);
  }
  
  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    return {
      'total_errors': _failedEvents.values.fold(0, (sum, count) => sum + count),
      'error_rate': errorRate,
      'failed_events': Map.unmodifiable(_failedEvents),
      'recent_errors': _recentErrors.map((e) => e.toJson()).toList(),
    };
  }
  
  /// Reset error stats
  void reset() {
    _failedEvents.clear();
    _recentErrors.clear();
    _totalMessageCount = 0;
  }
}

/// Class containing information about a socket error
class SocketErrorInfo {
  /// Event name
  final String eventName;
  
  /// Error message
  final String message;
  
  /// Error type
  final SocketErrorType type;
  
  /// Timestamp when the error occurred
  final DateTime timestamp;
  
  /// Constructor
  SocketErrorInfo({
    required this.eventName,
    required this.message,
    required this.type,
    required this.timestamp,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'event': eventName,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'SocketError[$type]: $message (event: $eventName)';
  }
} 