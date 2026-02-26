
import 'package:flutter_chat_app/core/monitoring/i_analytics_service.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

/// Lớp theo dõi phân tích tin nhắn Socket
class SocketMessageAnalytics {
  final IAnalyticsService _analyticsService;
  final AppLogger _logger;
  
  // Event tracking
  final Map<String, int> _eventCounts = {};
  final Map<String, List<int>> _eventLatencies = {};
  
  // Message metrics
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _bytesSent = 0;
  int _bytesReceived = 0;
  
  // Sampling rate for detailed analytics (1 out of every X messages)
  final int _samplingRate;
  
  /// Constructor
  SocketMessageAnalytics({
    required IAnalyticsService analyticsService,
    AppLogger? logger,
    int samplingRate = 100,
  }) : 
    _analyticsService = analyticsService,
    _logger = logger ?? AppLogger(),
    _samplingRate = samplingRate;
  
  /// Track a socket event being sent
  void trackEventSent(String eventName, {int? byteSize}) {
    _messagesSent++;
    if (byteSize != null) {
      _bytesSent += byteSize;
    }
    
    _eventCounts[eventName] = (_eventCounts[eventName] ?? 0) + 1;
    
    // Only log detailed analytics for every Nth message to reduce overhead
    if (_messagesSent % _samplingRate == 0) {
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
    
    // Only log detailed analytics for every Nth message to reduce overhead
    if (_messagesReceived % _samplingRate == 0) {
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
  
  /// Get total number of messages sent
  int get messagesSent => _messagesSent;
  
  /// Get total number of messages received
  int get messagesReceived => _messagesReceived;
  
  /// Get total bytes sent
  int get bytesSent => _bytesSent;
  
  /// Get total bytes received
  int get bytesReceived => _bytesReceived;
  
  /// Get average latency for a specific event type
  double getAverageLatency(String eventName) {
    final latencies = _eventLatencies[eventName];
    if (latencies == null || latencies.isEmpty) {
      return 0.0;
    }
    return latencies.reduce((a, b) => a + b) / latencies.length;
  }
  
  /// Get overall average latency across all event types
  double get overallAverageLatency {
    if (_eventLatencies.isEmpty) return 0.0;
    
    int totalMeasurements = 0;
    int totalLatency = 0;
    
    _eventLatencies.forEach((_, latencies) {
      if (latencies.isNotEmpty) {
        totalMeasurements += latencies.length;
        totalLatency += latencies.reduce((a, b) => a + b);
      }
    });
    
    if (totalMeasurements == 0) return 0.0;
    return totalLatency / totalMeasurements;
  }
  
  /// Get message statistics
  Map<String, dynamic> getMessageStats() {
    return {
      'messages_sent': _messagesSent,
      'messages_received': _messagesReceived,
      'bytes_sent': _bytesSent,
      'bytes_received': _bytesReceived,
      'event_counts': _eventCounts,
      'average_latencies': _eventLatencies.map(
        (eventName, latencies) => MapEntry(
          eventName,
          latencies.isEmpty ? 0 : latencies.reduce((a, b) => a + b) / latencies.length,
        )
      ),
      'overall_latency': overallAverageLatency,
    };
  }
  
  /// Reset message stats
  void reset() {
    _messagesSent = 0;
    _messagesReceived = 0;
    _bytesSent = 0;
    _bytesReceived = 0;
    _eventCounts.clear();
    _eventLatencies.clear();
  }
} 