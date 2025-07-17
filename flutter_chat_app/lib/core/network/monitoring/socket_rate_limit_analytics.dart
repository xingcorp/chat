
import 'package:flutter_chat_app/core/monitoring/analytics_service.dart';
import 'package:logger/logger.dart';

/// Lớp theo dõi phân tích rate limit Socket
class SocketRateLimitAnalytics {
  final AnalyticsService _analyticsService;
  final Logger _logger;
  
  // Rate limiting analytics
  final Map<String, int> _rateLimitedEvents = {};
  final Map<String, int> _queuedEvents = {};
  
  /// Constructor
  SocketRateLimitAnalytics({
    required AnalyticsService analyticsService,
    Logger? logger,
  }) : 
    _analyticsService = analyticsService,
    _logger = logger ?? Logger();
  
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
  
  /// Get number of times an event has been rate limited
  int getRateLimitedCount(String eventName) {
    return _rateLimitedEvents[eventName] ?? 0;
  }
  
  /// Get total number of rate limited events
  int get totalRateLimitedEvents {
    return _rateLimitedEvents.values.fold(0, (sum, count) => sum + count);
  }
  
  /// Get number of queued events by type
  int getQueuedCount(String eventName) {
    return _queuedEvents[eventName] ?? 0;
  }
  
  /// Get total number of queued events
  int get totalQueuedEvents {
    return _queuedEvents.values.fold(0, (sum, count) => sum + count);
  }
  
  /// Get rate limit statistics
  Map<String, dynamic> getRateLimitStats() {
    return {
      'rate_limited_events': Map.unmodifiable(_rateLimitedEvents),
      'queued_events': Map.unmodifiable(_queuedEvents),
      'total_rate_limited': totalRateLimitedEvents,
      'total_queued': totalQueuedEvents,
    };
  }
  
  /// Reset rate limit stats
  void reset() {
    _rateLimitedEvents.clear();
    _queuedEvents.clear();
  }
} 