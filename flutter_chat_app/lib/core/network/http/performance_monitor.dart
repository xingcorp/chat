import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Enum for request result type
enum RequestResultType {
  success,
  error,
  timeout,
  canceled
}

/// Class representing a request metric
class RequestMetric {
  /// Request URL
  final String url;
  
  /// HTTP method
  final String method;
  
  /// Request start time
  final DateTime startTime;
  
  /// Request end time
  final DateTime endTime;
  
  /// Request size in bytes (if available)
  final int? requestSize;
  
  /// Response size in bytes (if available)
  final int? responseSize;
  
  /// Status code
  final int? statusCode;
  
  /// Result type
  final RequestResultType resultType;
  
  /// Cached response?
  final bool fromCache;
  
  /// Create a request metric
  RequestMetric({
    required this.url,
    required this.method,
    required this.startTime,
    required this.endTime,
    this.requestSize,
    this.responseSize,
    this.statusCode,
    required this.resultType,
    this.fromCache = false,
  });
  
  /// Calculate duration
  Duration get duration => endTime.difference(startTime);
  
  /// Convert to map for analytics
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'method': method,
      'durationMs': duration.inMilliseconds,
      'requestSize': requestSize,
      'responseSize': responseSize,
      'statusCode': statusCode,
      'resultType': resultType.name,
      'fromCache': fromCache,
    };
  }
}

/// Performance monitor for HTTP requests
class NetworkPerformanceMonitor {
  /// Singleton instance
  static final NetworkPerformanceMonitor _instance = NetworkPerformanceMonitor._internal();
  
  /// Factory constructor
  factory NetworkPerformanceMonitor() => _instance;
  
  /// Private constructor
  NetworkPerformanceMonitor._internal();
  
  /// Recent metrics (limited to last 100)
  final _recentMetrics = ListQueue<RequestMetric>(100);
  
  /// Slow request threshold (ms)
  int _slowRequestThreshold = 3000;
  
  /// Current active requests
  final Map<String, _ActiveRequest> _activeRequests = {};
  
  /// Stream controller for metrics
  final _metricsController = StreamController<RequestMetric>.broadcast();
  
  /// Stream of metrics
  Stream<RequestMetric> get metricsStream => _metricsController.stream;
  
  /// Get metrics
  List<RequestMetric> get metrics => List.unmodifiable(_recentMetrics);
  
  /// Set slow request threshold
  set slowRequestThreshold(int milliseconds) {
    _slowRequestThreshold = milliseconds;
  }
  
  /// Track request start
  String trackRequestStart(String url, String method) {
    final requestId = '${DateTime.now().millisecondsSinceEpoch}-${_activeRequests.length}';
    _activeRequests[requestId] = _ActiveRequest(
      url: url,
      method: method,
      startTime: DateTime.now(),
    );
    return requestId;
  }
  
  /// Track request end
  void trackRequestEnd(
    String requestId, {
    required RequestResultType resultType,
    int? statusCode,
    int? requestSize,
    int? responseSize,
    bool fromCache = false,
  }) {
    final request = _activeRequests.remove(requestId);
    if (request == null) return;
    
    final endTime = DateTime.now();
    final metric = RequestMetric(
      url: request.url,
      method: request.method,
      startTime: request.startTime,
      endTime: endTime,
      requestSize: requestSize,
      responseSize: responseSize,
      statusCode: statusCode,
      resultType: resultType,
      fromCache: fromCache,
    );
    
    // Add to recent metrics
    _recentMetrics.add(metric);
    if (_recentMetrics.length > 100) {
      _recentMetrics.removeFirst();
    }
    
    // Emit metric
    _metricsController.add(metric);
    
    // Log slow requests
    final duration = endTime.difference(request.startTime).inMilliseconds;
    if (duration > _slowRequestThreshold && !fromCache) {
      _logSlowRequest(metric);
    }
  }
  
  /// Log slow request
  void _logSlowRequest(RequestMetric metric) {
    if (kDebugMode) {
      print('SLOW REQUEST (${metric.duration.inMilliseconds}ms): '
          '${metric.method} ${metric.url}');
    }
  }
  
  /// Calculate average response time for an endpoint
  Duration? getAverageResponseTime(String endpoint, {String? method}) {
    final filteredMetrics = _recentMetrics.where((m) => 
      m.url.contains(endpoint) && 
      (method == null || m.method == method) &&
      m.resultType == RequestResultType.success
    ).toList();
    
    if (filteredMetrics.isEmpty) return null;
    
    final totalMs = filteredMetrics.fold<int>(
      0, (sum, metric) => sum + metric.duration.inMilliseconds);
    
    return Duration(milliseconds: totalMs ~/ filteredMetrics.length);
  }
  
  /// Get success rate for an endpoint
  double? getSuccessRate(String endpoint, {String? method}) {
    final filteredMetrics = _recentMetrics.where((m) => 
      m.url.contains(endpoint) && 
      (method == null || m.method == method)
    ).toList();
    
    if (filteredMetrics.isEmpty) return null;
    
    final successCount = filteredMetrics.where(
      (m) => m.resultType == RequestResultType.success
    ).length;
    
    return successCount / filteredMetrics.length;
  }
  
  /// Get endpoints by performance (slowest first)
  List<Map<String, dynamic>> getEndpointsByPerformance() {
    final endpointMetrics = <String, List<RequestMetric>>{};
    
    // Group metrics by endpoint
    for (final metric in _recentMetrics) {
      final endpoint = _extractEndpoint(metric.url);
      endpointMetrics.putIfAbsent(endpoint, () => []).add(metric);
    }
    
    // Calculate average times
    final result = endpointMetrics.entries.map((entry) {
      final metrics = entry.value;
      final successMetrics = metrics.where(
        (m) => m.resultType == RequestResultType.success
      ).toList();
      
      final totalMs = successMetrics.fold<int>(
        0, (sum, metric) => sum + metric.duration.inMilliseconds);
      
      final avgTimeMs = successMetrics.isNotEmpty 
        ? totalMs / successMetrics.length 
        : 0;
      
      return {
        'endpoint': entry.key,
        'avgTimeMs': avgTimeMs,
        'callCount': metrics.length,
        'successRate': metrics.isNotEmpty 
          ? successMetrics.length / metrics.length 
          : 0,
      };
    }).toList();
    
    // Sort by average time (slowest first)
    result.sort((a, b) => (b['avgTimeMs'] as double).compareTo(a['avgTimeMs'] as double));
    
    return result;
  }
  
  /// Extract endpoint from URL
  String _extractEndpoint(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path;
    } catch (_) {
      return url;
    }
  }
  
  /// Reset metrics
  void reset() {
    _recentMetrics.clear();
    _activeRequests.clear();
  }
  
  /// Dispose
  void dispose() {
    _metricsController.close();
  }
}

/// Class for tracking active requests
class _ActiveRequest {
  final String url;
  final String method;
  final DateTime startTime;
  
  _ActiveRequest({
    required this.url,
    required this.method,
    required this.startTime,
  });
} 