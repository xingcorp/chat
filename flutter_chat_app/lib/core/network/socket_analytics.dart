import 'dart:async';
import 'dart:math' as math;

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'monitoring/socket_connection_analytics.dart';
import 'monitoring/socket_message_analytics.dart';
import 'monitoring/socket_error_analytics.dart';
import 'monitoring/socket_rate_limit_analytics.dart';
import 'monitoring/socket_metric_types.dart';
import '../monitoring/analytics_service.dart';

/// Service tích hợp theo dõi phân tích dữ liệu Socket
@injectable
class SocketAnalytics {
  final Logger _logger;
  final AnalyticsService _analyticsService;
  
  // Tracking components
  late final SocketConnectionAnalytics _connectionAnalytics;
  late final SocketMessageAnalytics _messageAnalytics;
  late final SocketErrorAnalytics _errorAnalytics;
  late final SocketRateLimitAnalytics _rateLimitAnalytics;
  
  /// Constructor
  SocketAnalytics({
    required AnalyticsService analyticsService,
    Logger? logger,
  }) : 
    _analyticsService = analyticsService,
    _logger = logger ?? Logger() {
    // Initialize components
    _connectionAnalytics = SocketConnectionAnalytics(
      analyticsService: analyticsService,
      logger: _logger,
    );
    
    _messageAnalytics = SocketMessageAnalytics(
      analyticsService: analyticsService,
      logger: _logger,
    );
    
    _errorAnalytics = SocketErrorAnalytics(
      analyticsService: analyticsService,
      logger: _logger,
    );
    
    _rateLimitAnalytics = SocketRateLimitAnalytics(
      analyticsService: analyticsService, 
      logger: _logger,
    );
  }

  /// Track a new socket connection attempt
  void trackConnectionAttempt() {
    _connectionAnalytics.trackConnectionAttempt();
  }

  /// Track successful socket connection
  void trackConnection() {
    _connectionAnalytics.trackConnection();
  }

  /// Track socket disconnection
  void trackDisconnection({String? reason}) {
    _connectionAnalytics.trackDisconnection(reason: reason);
  }

  /// Track a socket event being sent
  void trackEventSent(String eventName, {int? byteSize}) {
    _messageAnalytics.trackEventSent(eventName, byteSize: byteSize);
  }

  /// Track a socket event being received
  void trackEventReceived(String eventName, {int? byteSize}) {
    _messageAnalytics.trackEventReceived(eventName, byteSize: byteSize);
  }

  /// Track latency for a socket event
  void trackEventLatency(String eventName, int latencyMs) {
    _messageAnalytics.trackEventLatency(eventName, latencyMs);
  }

  /// Track a failed socket event
  void trackEventFailure(String eventName, {String? errorMessage, SocketErrorType? errorType}) {
    _errorAnalytics.trackEventFailure(
      eventName, 
      errorMessage: errorMessage,
      errorType: errorType ?? SocketErrorType.unknown,
    );
    
    // Update message count for error rate calculation
    _errorAnalytics.recordMessageCount(1);
  }

  /// Track rate limited events
  void trackRateLimited(String eventName) {
    _rateLimitAnalytics.trackRateLimited(eventName);
  }

  /// Track queued event
  void trackQueuedEvent(String eventName) {
    _rateLimitAnalytics.trackQueuedEvent(eventName);
  }

  /// Track queue processed
  void trackQueueProcessed(String eventName, int count) {
    _rateLimitAnalytics.trackQueueProcessed(eventName, count);
  }
  
  /// Record message sent for metrics
  void recordMessageSent() {
    _messageAnalytics.trackEventSent('general');
  }
  
  /// Record message received for metrics
  void recordMessageReceived() {
    _messageAnalytics.trackEventReceived('general');
  }
  
  /// Record error for metrics
  void recordError(String errorType) {
    _errorAnalytics.trackEventFailure('general', errorMessage: errorType);
  }

  /// Check connection health
  Future<Map<String, dynamic>> checkConnectionHealth() async {
    // Calculate average latencies
    final avgLatency = _messageAnalytics.overallAverageLatency;
    
    // Calculate overall quality based on latency
    String quality;
    if (avgLatency < 100) {
      quality = 'excellent';
    } else if (avgLatency < 250) {
      quality = 'good';
    } else if (avgLatency < 500) {
      quality = 'fair';
    } else if (avgLatency < 1000) {
      quality = 'poor';
    } else {
      quality = 'critical';
    }
    
    return {
      'quality': quality,
      'latency': {
        'current': avgLatency.round(),
        'details': _messageAnalytics.getMessageStats()['average_latencies'],
      },
      'messages': {
        'sent': _messageAnalytics.messagesSent,
        'received': _messageAnalytics.messagesReceived,
        'ratio': _messageAnalytics.messagesSent > 0 
            ? _messageAnalytics.messagesReceived / _messageAnalytics.messagesSent 
            : 0,
      },
      'errors': {
        'count': _errorAnalytics.getErrorStats()['total_errors'],
        'rate': _errorAnalytics.errorRate,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
  
  /// Measure connection latency in milliseconds
  Future<int?> checkLatency() async {
    try {
      final startTime = DateTime.now().millisecondsSinceEpoch;
      final pingId = 'ping_${startTime}_${math.Random().nextInt(10000)}';
      
      // In a real implementation, you'd send a ping and wait for a pong
      // This is just a simulation for the example
      await Future.delayed(const Duration(milliseconds: 50));
      
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final latency = endTime - startTime;
      
      // Record the latency
      trackEventLatency('ping', latency);
      
      return latency;
    } catch (e) {
      _logger.e('Error measuring latency: $e');
      return null;
    }
  }

  /// Get socket metrics
  Map<String, dynamic> getMetrics() {
    return {
      ...(_connectionAnalytics.getConnectionStats()),
      ...(_messageAnalytics.getMessageStats()),
      ...(_errorAnalytics.getErrorStats()),
      ...(_rateLimitAnalytics.getRateLimitStats()),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Reset metrics
  void resetMetrics() {
    _messageAnalytics.reset();
    _errorAnalytics.reset();
    _rateLimitAnalytics.reset();
    // We don't reset connection stats as they are valuable for long-term tracking
  }

  // Alias methods for backward compatibility with test files

  /// Track message sent (alias for trackEventSent)
  void trackMessageSent([String? eventName]) {
    trackEventSent(eventName ?? 'message');
  }

  /// Track message received (alias for trackEventReceived)
  void trackMessageReceived([String? eventName]) {
    trackEventReceived(eventName ?? 'message');
  }

  /// Track latency (alias for checkLatency)
  Future<int?> trackLatency() {
    return checkLatency();
  }

  /// Track error (alias for recordError)
  void trackError(String errorType) {
    recordError(errorType);
  }
}