import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:injectable/injectable.dart';

import 'socket_manager.dart';
import '../monitoring/analytics_service.dart';

/// Loại metric theo dõi hiệu suất Socket.IO
enum SocketMetricType {
  /// Độ trễ của kết nối
  latency,
  
  /// Số lượng tin nhắn gửi đi
  messagesSent,
  
  /// Số lượng tin nhắn nhận được
  messagesReceived,
  
  /// Số lượng lần kết nối lại
  reconnections,
  
  /// Thời gian hoạt động
  uptime,
  
  /// Thời gian không hoạt động
  downtime,
  
  /// Tỷ lệ lỗi
  errorRate,
}

/// Loại lỗi kết nối Socket.IO
enum SocketErrorType {
  /// Lỗi kết nối mạng
  networkError,
  
  /// Lỗi timeout
  timeout,
  
  /// Lỗi xác thực
  authError,
  
  /// Lỗi từ server
  serverError,
  
  /// Lỗi transport
  transportError,
  
  /// Lỗi khi gửi tin nhắn
  messagingError,
  
  /// Lỗi không xác định
  unknown,
}

/// Service for tracking socket analytics data
@injectable
class SocketAnalytics {
  final AnalyticsService _analyticsService;
  final Logger _logger;

  // Performance tracking
  final Map<String, int> _eventCounts = {};
  final Map<String, List<int>> _eventLatencies = {};
  final Map<String, int> _failedEvents = {};
  
  // Connection tracking
  int _disconnectionCount = 0;
  int _reconnectionCount = 0;
  int _connectionsInitiated = 0;
  DateTime? _lastDisconnection;
  DateTime? _lastConnection;
  
  // Errors and metrics
  final List<String> _recentErrors = [];
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _bytesSent = 0;
  int _bytesReceived = 0;
  
  // Rate limiting analytics
  final Map<String, int> _rateLimitedEvents = {};
  final Map<String, int> _queuedEvents = {};

  /// Constructor
  SocketAnalytics({
    required AnalyticsService analyticsService,
    Logger? logger,
  }) : 
    _analyticsService = analyticsService,
    _logger = logger ?? Logger();

  /// Track a new socket connection attempt
  void trackConnectionAttempt() {
    _connectionsInitiated++;
    _logger.d('Socket connection attempt initiated (total: $_connectionsInitiated)');
  }

  /// Track successful socket connection
  void trackConnection() {
    _lastConnection = DateTime.now();
    _logger.d('Socket connected successfully');
    
    // Only log reconnection if we had a previous disconnection
    if (_lastDisconnection != null) {
      _reconnectionCount++;
      
      // Calculate time between disconnection and reconnection
      final downtime = _lastConnection!.difference(_lastDisconnection!);
      
      _logger.d('Socket reconnected after ${downtime.inMilliseconds}ms (count: $_reconnectionCount)');
      
      // Log reconnection to analytics if downtime was significant (> 1 second)
      if (downtime.inSeconds > 1) {
        _analyticsService.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'socket_reconnected',
          parameters: {
            'downtime_ms': downtime.inMilliseconds,
            'reconnection_count': _reconnectionCount,
          },
        );
      }
    }
  }

  /// Track socket disconnection
  void trackDisconnection({String? reason}) {
    _lastDisconnection = DateTime.now();
    _disconnectionCount++;
    
    _logger.d('Socket disconnected (count: $_disconnectionCount, reason: $reason)');
    
    // Log disconnection to analytics
    _analyticsService.logEvent(
      AnalyticsEvent.custom,
      customEventName: 'socket_disconnected',
      parameters: {
        'disconnection_count': _disconnectionCount,
        'reason': reason ?? 'unknown',
        'uptime': _lastConnection != null 
            ? DateTime.now().difference(_lastConnection!).inSeconds 
            : 0,
      },
    );
  }

  /// Track a socket event being sent
  void trackEventSent(String eventName, {int? byteSize}) {
    _messagesSent++;
    if (byteSize != null) {
      _bytesSent += byteSize;
    }
    
    _eventCounts[eventName] = (_eventCounts[eventName] ?? 0) + 1;
    
    // Only log detailed analytics for every 100th message to reduce overhead
    if (_messagesSent % 100 == 0) {
      _analyticsService.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_messages_sent_milestone',
        parameters: {
          'count': _messagesSent,
          'bytes_sent': _bytesSent,
        },
      );
    }
  }

  /// Track a socket event being received
  void trackEventReceived(String eventName, {int? byteSize}) {
    _messagesReceived++;
    if (byteSize != null) {
      _bytesReceived += byteSize;
    }
    
    // Only log detailed analytics for every 100th message to reduce overhead
    if (_messagesReceived % 100 == 0) {
      _analyticsService.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_messages_received_milestone',
        parameters: {
          'count': _messagesReceived,
          'bytes_received': _bytesReceived,
        },
      );
    }
  }

  /// Track latency for a socket event
  void trackEventLatency(String eventName, int latencyMs) {
    if (!_eventLatencies.containsKey(eventName)) {
      _eventLatencies[eventName] = [];
    }
    
    // Keep only last 100 latency measurements per event to save memory
    final latencies = _eventLatencies[eventName]!;
    if (latencies.length >= 100) {
      latencies.removeAt(0);
    }
    
    latencies.add(latencyMs);
    
    // Log high latency events to analytics
    if (latencyMs > 1000) {
      _analyticsService.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_high_latency',
        parameters: {
          'event_type': eventName,
          'latency_ms': latencyMs,
        },
      );
    }
  }

  /// Track a failed socket event
  void trackEventFailure(String eventName, {String? errorMessage}) {
    _failedEvents[eventName] = (_failedEvents[eventName] ?? 0) + 1;
    
    // Keep a limited list of recent errors
    if (_recentErrors.length >= 20) {
      _recentErrors.removeAt(0);
    }
    _recentErrors.add('$eventName: ${errorMessage ?? 'unknown error'}');
    
    // Log error to analytics
    _analyticsService.logEvent(
      AnalyticsEvent.custom,
      customEventName: 'socket_event_failure',
      parameters: {
        'event_type': eventName,
        'error': errorMessage ?? 'unknown error',
        'failure_count': _failedEvents[eventName],
      },
    );
  }

  /// Track rate limited events
  void trackRateLimited(String eventName) {
    _rateLimitedEvents[eventName] = (_rateLimitedEvents[eventName] ?? 0) + 1;
    
    // Log rate limiting to analytics when significant
    if (_rateLimitedEvents[eventName]! % 10 == 0) {
      _analyticsService.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_rate_limited',
        parameters: {
          'event_type': eventName,
          'count': _rateLimitedEvents[eventName],
        },
      );
    }
  }

  /// Track queued event
  void trackQueuedEvent(String eventName) {
    _queuedEvents[eventName] = (_queuedEvents[eventName] ?? 0) + 1;
  }

  /// Track queue processed
  void trackQueueProcessed(String eventName, int count) {
    if (count > 0) {
      _analyticsService.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_queue_processed',
        parameters: {
          'event_type': eventName,
          'count': count,
        },
      );
    }
  }

  /// Check connection health
  Future<Map<String, dynamic>> checkConnectionHealth() async {
    // Calculate average latencies
    final Map<String, double> avgLatencies = {};
    _eventLatencies.forEach((event, latencies) {
      if (latencies.isNotEmpty) {
        avgLatencies[event] = latencies.reduce((a, b) => a + b) / latencies.length;
      }
    });
    
    // Calculate overall quality based on latency
    final avgLatency = avgLatencies.isEmpty 
        ? 0.0 
        : avgLatencies.values.reduce((a, b) => a + b) / avgLatencies.length;
    
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
        'details': avgLatencies,
      },
      'messages': {
        'sent': _messagesSent,
        'received': _messagesReceived,
        'ratio': _messagesSent > 0 ? _messagesReceived / _messagesSent : 0,
      },
      'errors': {
        'count': _recentErrors.length,
        'rate': _messagesSent > 0 ? _recentErrors.length / _messagesSent : 0,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Get socket metrics
  Map<String, dynamic> getMetrics() {
    // Calculate average latencies
    final Map<String, double> avgLatencies = {};
    _eventLatencies.forEach((event, latencies) {
      if (latencies.isNotEmpty) {
        avgLatencies[event] = latencies.reduce((a, b) => a + b) / latencies.length;
      }
    });
    
    return {
      'messages_sent': _messagesSent,
      'messages_received': _messagesReceived,
      'bytes_sent': _bytesSent,
      'bytes_received': _bytesReceived,
      'disconnection_count': _disconnectionCount,
      'reconnection_count': _reconnectionCount,
      'last_disconnection': _lastDisconnection?.toIso8601String(),
      'last_connection': _lastConnection?.toIso8601String(),
      'event_counts': _eventCounts,
      'failed_events': _failedEvents,
      'average_latencies': avgLatencies,
      'rate_limited_events': _rateLimitedEvents,
      'queued_events': _queuedEvents,
      'recent_errors': _recentErrors,
    };
  }

  /// Reset metrics
  void resetMetrics() {
    _eventCounts.clear();
    _eventLatencies.clear();
    _failedEvents.clear();
    _recentErrors.clear();
    _rateLimitedEvents.clear();
    _queuedEvents.clear();
    _messagesSent = 0;
    _messagesReceived = 0;
    _bytesSent = 0;
    _bytesReceived = 0;
    // We don't reset connection counts as they are valuable for long-term statistics
  }
}

/// Optimized WebSocket metrics tracking with minimal overhead
@injectable
class WebSocketMetrics {
  final AnalyticsService _analytics;
  
  // Tracking metrics
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _reconnectAttempts = 0;
  int _errors = 0;
  int _droppedMessages = 0;
  
  // Connection times
  final List<int> _connectionTimes = [];
  
  // Message lag times
  final List<int> _messageLagTimes = [];
  
  // Last activity timestamp
  int _lastActivityTime = 0;
  
  WebSocketMetrics(this._analytics);
  
  /// Record WebSocket connection time
  void recordConnectionTime(int milliseconds) {
    _connectionTimes.add(milliseconds);
    if (_connectionTimes.length > 10) {
      _connectionTimes.removeAt(0);
    }
    
    _analytics.logEvent(
      AnalyticsEvent.custom,
      customEventName: 'socket_connection',
      parameters: {
        'connection_time_ms': milliseconds,
        'avg_connection_time_ms': averageConnectionTime,
      },
    );
  }
  
  /// Record message sent
  void recordMessageSent() {
    _messagesSent++;
    _lastActivityTime = DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Record message received
  void recordMessageReceived({int? size}) {
    _messagesReceived++;
    _lastActivityTime = DateTime.now().millisecondsSinceEpoch;
    
    if (size != null && size > 0) {
      _analytics.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_data_received',
        parameters: {'size_bytes': size},
      );
    }
  }
  
  /// Record message lag (ping/pong)
  void recordMessageLag(int milliseconds) {
    _messageLagTimes.add(milliseconds);
    if (_messageLagTimes.length > 50) {
      _messageLagTimes.removeAt(0);
    }
    
    if (milliseconds > 1000) {
      _analytics.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'socket_high_latency',
        parameters: {'latency_ms': milliseconds},
      );
    }
  }
  
  /// Record WebSocket error
  void recordError(String error) {
    _errors++;
    _analytics.logEvent(
      AnalyticsEvent.custom,
      customEventName: 'socket_error',
      parameters: {'error_message': error},
    );
  }
  
  /// Record reconnect attempt
  void recordReconnectAttempt() {
    _reconnectAttempts++;
    _analytics.logEvent(
      AnalyticsEvent.custom,
      customEventName: 'socket_reconnect',
      parameters: {'attempt_count': _reconnectAttempts},
    );
  }
  
  /// Record dropped message
  void recordDroppedMessage() {
    _droppedMessages++;
  }
  
  /// Get average connection time
  int get averageConnectionTime {
    if (_connectionTimes.isEmpty) {
      return 0;
    }
    return _connectionTimes.reduce((a, b) => a + b) ~/ _connectionTimes.length;
  }
  
  /// Get average message lag
  int get averageMessageLag {
    if (_messageLagTimes.isEmpty) {
      return 0;
    }
    return _messageLagTimes.reduce((a, b) => a + b) ~/ _messageLagTimes.length;
  }
  
  /// Check if connection is stable
  bool get isConnectionStable {
    // Connection is considered stable if average lag < 300ms
    return averageMessageLag < 300 && _errors == 0;
  }
  
  /// Get time since last activity
  int get timeSinceLastActivity {
    if (_lastActivityTime == 0) {
      return 0;
    }
    return DateTime.now().millisecondsSinceEpoch - _lastActivityTime;
  }
  
  /// Calculate packet loss percentage
  double get packetLossPercentage {
    if (_messagesSent == 0) {
      return 0.0;
    }
    return (_droppedMessages / _messagesSent) * 100;
  }
  
  /// Reset all metrics
  void reset() {
    _messagesSent = 0;
    _messagesReceived = 0;
    _reconnectAttempts = 0;
    _errors = 0;
    _droppedMessages = 0;
    _connectionTimes.clear();
    _messageLagTimes.clear();
    _lastActivityTime = 0;
  }
  
  /// Report metrics to analytics
  void reportMetrics() {
    if (!kReleaseMode) {
      return;
    }
    
    _analytics.logEvent(
      AnalyticsEvent.custom,
      customEventName: 'socket_stats',
      parameters: {
        'messages_sent': _messagesSent,
        'messages_received': _messagesReceived,
        'reconnect_attempts': _reconnectAttempts,
        'errors': _errors,
        'dropped_messages': _droppedMessages,
        'avg_connection_time_ms': averageConnectionTime,
        'avg_message_lag_ms': averageMessageLag,
        'packet_loss_pct': packetLossPercentage,
      },
    );
  }
} 