
import 'package:flutter_chat_app/core/monitoring/i_analytics_service.dart';
import 'package:logger/logger.dart';

/// Lớp theo dõi phân tích kết nối Socket
class SocketConnectionAnalytics {
  final IAnalyticsService _analyticsService;
  final Logger _logger;
  
  // Connection tracking
  int _disconnectionCount = 0;
  int _reconnectionCount = 0;
  int _connectionsInitiated = 0;
  DateTime? _lastDisconnection;
  DateTime? _lastConnection;
  
  /// Constructor
  SocketConnectionAnalytics({
    required IAnalyticsService analyticsService,
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
  
  /// Check connection uptime in seconds
  int getUptimeSeconds() {
    if (_lastConnection == null) return 0;
    return DateTime.now().difference(_lastConnection!).inSeconds;
  }
  
  /// Check time since last disconnection in seconds
  int? getTimeSinceDisconnectionSeconds() {
    if (_lastDisconnection == null) return null;
    return DateTime.now().difference(_lastDisconnection!).inSeconds;
  }
  
  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'disconnection_count': _disconnectionCount,
      'reconnection_count': _reconnectionCount,
      'connections_initiated': _connectionsInitiated,
      'last_disconnection': _lastDisconnection?.toIso8601String(),
      'last_connection': _lastConnection?.toIso8601String(),
      'current_uptime': getUptimeSeconds(),
    };
  }
} 