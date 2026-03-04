import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/monitoring/i_analytics_service.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// Statistics for an API endpoint
class EndpointStat {
  final String endpoint;
  final double avgResponseTime;
  final double successRate;
  final int totalCalls;
  final double p90ResponseTime;
  
  EndpointStat({
    required this.endpoint,
    required this.avgResponseTime,
    required this.successRate,
    required this.totalCalls,
    required this.p90ResponseTime,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'avgResponseTime': avgResponseTime,
      'successRate': successRate,
      'totalCalls': totalCalls,
      'p90ResponseTime': p90ResponseTime,
    };
  }
}

/// Performance statistics for an endpoint
class EndpointPerformance {
  int totalCalls = 0;
  int successfulCalls = 0;
  int failedCalls = 0;
  int totalDuration = 0;
  List<int> responseTimes = [];
  List<String> errors = [];
  
  double get avgResponseTime => 
      totalCalls > 0 ? totalDuration / totalCalls : 0;
      
  double get successRate => 
      totalCalls > 0 ? (successfulCalls / totalCalls) * 100 : 0;
      
  double get errorRate => 
      totalCalls > 0 ? (failedCalls / totalCalls) * 100 : 0;
      
  double get p90ResponseTime {
    if (responseTimes.isEmpty) return 0;
    
    // Sort response times
    final sorted = List.of(responseTimes)..sort();
    
    // Calculate p90 index
    final index = (sorted.length * 0.9).ceil() - 1;
    return index >= 0 ? sorted[index].toDouble() : 0;
  }
  
  // Recalculate derived metrics
  void recalculateMetrics() {
    // Update error rate and success rate
    successfulCalls = totalCalls - failedCalls;
  }
  
  // Get most common errors
  List<String> getMostCommonErrors(int limit) {
    if (errors.isEmpty) return [];
    
    // Count occurrences of each error
    final errorCounts = <String, int>{};
    for (final error in errors) {
      errorCounts[error] = (errorCounts[error] ?? 0) + 1;
    }
    
    // Sort by count (descending)
    final sortedErrors = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return top errors
    return sortedErrors
        .take(limit)
        .map((e) => e.key)
        .toList();
  }
  
  // Get error frequency
  Map<String, int> getErrorFrequency() {
    if (errors.isEmpty) return {};
    
    final errorCounts = <String, int>{};
    for (final error in errors) {
      errorCounts[error] = (errorCounts[error] ?? 0) + 1;
    }
    
    return errorCounts;
  }
}

/// API request statistics
class ApiRequestStats {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int activeRequests;
  final double averageResponseTime;
  final double fastestResponseTime;
  final double slowestResponseTime;
  final double successRate;
  final List<EndpointStat> slowestEndpoints;
  final List<EndpointStat> errorProneEndpoints;
  
  ApiRequestStats({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.activeRequests,
    required this.averageResponseTime,
    required this.fastestResponseTime,
    required this.slowestResponseTime,
    required this.successRate,
    required this.slowestEndpoints,
    required this.errorProneEndpoints,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'totalRequests': totalRequests,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'activeRequests': activeRequests,
      'averageResponseTime': averageResponseTime,
      'fastestResponseTime': fastestResponseTime,
      'slowestResponseTime': slowestResponseTime,
      'successRate': successRate,
      'slowestEndpoints': slowestEndpoints.map((e) => e.toJson()).toList(),
      'errorProneEndpoints': errorProneEndpoints.map((e) => e.toJson()).toList(),
    };
  }
}

/// API request tracker for monitoring performance and errors
/// 
/// Uses dependency injection for logger and analytics.
/// Injectable manages the singleton lifecycle automatically.
@lazySingleton
class ApiRequestTracker {
  // Dependencies (injected via constructor)
  final AppLogger _logger;
  final IAnalyticsService _analytics;
  
  // Storage for requests
  final LinkedHashMap<String, ApiRequestInfo> _recentRequests = LinkedHashMap();
  final Map<String, ApiRequestInfo> _activeRequests = {};
  final Map<String, EndpointPerformance> _endpointStats = {};
  
  // Configuration
  final int _maxStoredRequests = 100;
  final int _abandonedRequestTimeout = 30000; // 30 seconds
  bool _autoCleanupEnabled = true;
  Timer? _cleanupTimer;
  int _lastCleanupTime = 0;
  
  // Performance metrics
  int _totalRequestsCount = 0;
  int _successfulRequestsCount = 0;
  int _failedRequestsCount = 0;
  int _totalResponseTime = 0;
  int? _fastestResponseTime;
  int? _slowestResponseTime;
  
  // Add new analysis metrics
  final Map<String, List<int>> _hourlyRequestCounts = {};
  final Map<String, Map<int, int>> _statusCodeDistribution = {};
  int _apdexThreshold = 500; // ms - target response time
  
  /// Constructor with dependency injection
  /// 
  /// Dependencies are automatically injected by Injectable.
  /// Starts cleanup timer on initialization.
  ApiRequestTracker(this._logger, this._analytics) {
    _startCleanupTimer();
  }
  
  /// Start tracking a request
  String startRequest(String method, String endpoint, {Map<String, dynamic>? params}) {
    final id = _generateRequestId();
    final request = ApiRequestInfo(
      id: id,
      method: method,
      endpoint: endpoint,
      startTime: DateTime.now(),
      params: params,
    );
    
    _activeRequests[id] = request;
    _totalRequestsCount++;
    
    // Track hourly distribution
    final hour = DateTime.now().hour;
    _hourlyRequestCounts[endpoint] ??= List.filled(24, 0);
    _hourlyRequestCounts[endpoint]![hour]++;
    
    return id;
  }
  
  /// Complete a request successfully
  void completeRequest(String id, int statusCode) {
    final request = _activeRequests.remove(id);
    if (request == null) {
      _logger.warn('ApiRequestTracker: Attempted to complete unknown request ID: $id');
      return;
    }
    
    // Set completion information
    request.endTime = DateTime.now();
    request.duration = request.endTime!.difference(request.startTime);
    request.statusCode = statusCode;
    request.success = _isSuccessStatusCode(statusCode);
    
    // Update stats
    final durationMs = request.duration!.inMilliseconds;
    _totalResponseTime += durationMs;
    
    // Update fastest/slowest times
    if (_fastestResponseTime == null || durationMs < _fastestResponseTime!) {
      _fastestResponseTime = durationMs;
    }
    
    if (_slowestResponseTime == null || durationMs > _slowestResponseTime!) {
      _slowestResponseTime = durationMs;
    }
    
    // Update status code distribution
    _statusCodeDistribution[request.endpoint] ??= {};
    _statusCodeDistribution[request.endpoint]![statusCode] = 
        (_statusCodeDistribution[request.endpoint]![statusCode] ?? 0) + 1;
    
    // Update success/failure counts
    if (request.success) {
      _successfulRequestsCount++;
      
      // Log slow but successful requests for analysis
      if (durationMs > _apdexThreshold * 4) {
        _logger.warn(
          'ApiRequestTracker: Very slow request [${request.method}] ${request.endpoint} took ${durationMs}ms'
        );
        
        _analytics.logEvent(
          AnalyticsEvent.custom,
          customEventName: 'api_performance_issue',
          parameters: {
            'endpoint': request.endpoint,
            'method': request.method,
            'duration_ms': durationMs,
            'threshold_ms': _apdexThreshold * 4,
            'status_code': statusCode,
          }
        );
      }
    } else {
      _failedRequestsCount++;
      
      // Log error requests
      _logger.warn(
        'ApiRequestTracker: Failed request [${request.method}] ${request.endpoint} with status $statusCode'
      );
      
      _analytics.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'api_error',
        parameters: {
          'endpoint': request.endpoint,
          'method': request.method,
          'status_code': statusCode,
          'duration_ms': durationMs,
        }
      );
    }
    
    // Add request to recent requests
    _addToRecentRequests(request);
    
    // Update endpoint stats
    _updateEndpointStats(request);
  }
  
  /// Mark a request as failed
  void failRequest(String id, dynamic error) {
    final request = _activeRequests.remove(id);
    if (request == null) {
      _logger.warn('ApiRequestTracker: Attempted to fail unknown request ID: $id');
      return;
    }
    
    // Set failure information
    request.endTime = DateTime.now();
    request.duration = request.endTime!.difference(request.startTime);
    request.success = false;
    request.error = error.toString();
    
    // Update stats
    _failedRequestsCount++;
    
    // Update total response time
    if (request.duration != null) {
      _totalResponseTime += request.duration!.inMilliseconds;
    }
    
    // Add request to recent requests
    _addToRecentRequests(request);
    
    // Update endpoint stats
    _updateEndpointStats(request);
    
    // Log error
    _logger.error(
      'ApiRequestTracker: Request [${request.method}] ${request.endpoint} failed with error: ${error.toString()}'
    );
    
    // Log to analytics
    _analytics.logError(
      errorType: 'api_error',
      errorMessage: error.toString(),
      errorDetails: '${request.method} ${request.endpoint}',
      fatal: false,
    );
  }
  
  /// Calculate Apdex score (Application Performance Index)
  /// Returns a score between 0 and 1, where:
  /// - 0-0.5: Frustrated users
  /// - 0.5-0.85: Tolerating users
  /// - 0.85-1.0: Satisfied users
  double calculateApdexScore() {
    final recentRequests = _recentRequests.values.where((r) => r.duration != null).toList();
    if (recentRequests.isEmpty) return 1.0;
    
    final satisfied = recentRequests.where((r) => 
        r.duration!.inMilliseconds <= _apdexThreshold).length;
        
    final tolerating = recentRequests.where((r) => 
        r.duration!.inMilliseconds > _apdexThreshold && 
        r.duration!.inMilliseconds <= _apdexThreshold * 4).length;
        
    return (satisfied + (tolerating / 2)) / recentRequests.length;
  }
  
  /// Get API request statistics
  ApiRequestStats getStats() {
    // Tính thời gian phản hồi trung bình
    final avgResponseTime = _totalRequestsCount > 0 
        ? _totalResponseTime / _totalRequestsCount 
        : 0;
    
    // Tính tỷ lệ thành công
    final successRate = _totalRequestsCount > 0 
        ? (_successfulRequestsCount / _totalRequestsCount) * 100 
        : 0;
    
    // Lấy endpoints chậm nhất
    final sortedEndpoints = _endpointStats.entries.toList()
      ..sort((a, b) => b.value.avgResponseTime.compareTo(a.value.avgResponseTime));
    
    final slowestEndpoints = sortedEndpoints
        .take(5)
        .map((e) => EndpointStat(
              endpoint: e.key,
              avgResponseTime: e.value.avgResponseTime,
              successRate: e.value.successRate,
              totalCalls: e.value.totalCalls,
              p90ResponseTime: e.value.p90ResponseTime,
            ))
        .toList();
    
    // Lấy endpoints có tỷ lệ lỗi cao nhất
    final errorProneEndpoints = sortedEndpoints
        .where((e) => e.value.errorRate > 0)
        .take(5)
        .map((e) => EndpointStat(
              endpoint: e.key,
              avgResponseTime: e.value.avgResponseTime,
              successRate: e.value.successRate,
              totalCalls: e.value.totalCalls,
              p90ResponseTime: e.value.p90ResponseTime,
            ))
        .toList();
    
    return ApiRequestStats(
      totalRequests: _totalRequestsCount,
      successfulRequests: _successfulRequestsCount,
      failedRequests: _failedRequestsCount,
      activeRequests: _activeRequests.length,
      averageResponseTime: avgResponseTime.toDouble(),
      fastestResponseTime: (_fastestResponseTime ?? 0).toDouble(),
      slowestResponseTime: (_slowestResponseTime ?? 0).toDouble(),
      successRate: successRate.toDouble(),
      slowestEndpoints: slowestEndpoints,
      errorProneEndpoints: errorProneEndpoints,
    );
  }
  
  /// Thêm request vào danh sách gần đây
  void _addToRecentRequests(ApiRequestInfo request) {
    _recentRequests[request.id] = request;
    
    // Giới hạn kích thước cache bằng cách xóa các requests cũ nhất
    if (_recentRequests.length > _maxStoredRequests) {
      final oldestKey = _recentRequests.keys.first;
      _recentRequests.remove(oldestKey);
    }
  }
  
  /// Cập nhật thống kê theo endpoint
  void _updateEndpointStats(ApiRequestInfo request) {
    if (request.duration == null) return;
    
    final endpoint = request.endpoint;
    final stats = _endpointStats[endpoint] ?? EndpointPerformance();
    final durationMs = request.duration!.inMilliseconds;
    
    // Cập nhật thống kê
    stats.totalCalls++;
    stats.totalDuration += durationMs;
    stats.responseTimes.add(durationMs);
    
    // Giới hạn số lượng response times để tránh sử dụng quá nhiều bộ nhớ
    if (stats.responseTimes.length > 100) {
      stats.responseTimes.removeAt(0);
    }
    
    if (request.success) {
      stats.successfulCalls++;
    } else {
      stats.failedCalls++;
      stats.errors.add(request.error ?? 'Unknown error');
      
      // Giới hạn số lượng lỗi được lưu
      if (stats.errors.length > 20) {
        stats.errors.removeAt(0);
      }
    }
    
    // Cập nhật performance metrics
    stats.recalculateMetrics();
    
    // Lưu lại vào map
    _endpointStats[endpoint] = stats;
  }
  
  /// Bắt đầu timer để dọn dẹp các request bị bỏ quên
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_autoCleanupEnabled) {
        _cleanupAbandonedRequests();
      }
    });
  }
  
  /// Dọn dẹp các request bị bỏ quên
  void _cleanupAbandonedRequests() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastCleanupTime = now;
    
    // Không cần dọn dẹp nếu không có request đang hoạt động
    if (_activeRequests.isEmpty) return;
    
    final abandonedIds = <String>[];
    
    // Tìm các request bị bỏ quên
    _activeRequests.forEach((id, request) {
      final elapsedTime = now - request.startTime.millisecondsSinceEpoch;
      
      if (elapsedTime > _abandonedRequestTimeout) {
        abandonedIds.add(id);
      }
    });
    
    // Xử lý các request bị bỏ quên
    for (final id in abandonedIds) {
      final request = _activeRequests[id]!;
      
      _logger.warn(
        'API Request [${request.method}] ${request.endpoint} bị bỏ quên sau ${_abandonedRequestTimeout}ms và sẽ bị hủy'
      );
      
      failRequest(id, 'Request abandoned (timeout after ${_abandonedRequestTimeout}ms)');
    }
    
    if (abandonedIds.isNotEmpty) {
      _logger.debug('ApiRequestTracker: Đã dọn dẹp ${abandonedIds.length} request bị bỏ quên');
    }
  }
  
  /// Tạo ID cho request với entropy cao để tránh va chạm
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(1000000);
    final counter = _totalRequestsCount;
    return '${timestamp}_${random}_$counter';
  }
  
  /// Bật/tắt tự động dọn dẹp các request bị bỏ quên
  void setAutoCleanupEnabled(bool enabled) {
    _autoCleanupEnabled = enabled;
    if (enabled && _cleanupTimer == null) {
      _startCleanupTimer();
    } else if (!enabled && _cleanupTimer != null) {
      _cleanupTimer?.cancel();
      _cleanupTimer = null;
    }
  }
  
  /// Set the Apdex target response time threshold
  void setApdexThreshold(int milliseconds) {
    _apdexThreshold = milliseconds;
  }
  
  /// Get hourly distribution of requests for an endpoint
  List<int> getHourlyDistribution(String endpoint) {
    return _hourlyRequestCounts[endpoint] ?? List.filled(24, 0);
  }
  
  /// Get distribution of status codes for an endpoint
  Map<int, int> getStatusCodeDistribution(String endpoint) {
    return Map.from(_statusCodeDistribution[endpoint] ?? {});
  }
  
  /// Get most common errors for an endpoint
  List<String> getMostCommonErrors(String endpoint, {int limit = 5}) {
    final stats = _endpointStats[endpoint];
    if (stats == null) return [];
    return stats.getMostCommonErrors(limit);
  }
  
  /// Get error details for advanced troubleshooting
  Map<String, dynamic> getErrorAnalysis() {
    final analysis = <String, dynamic>{};
    
    // Top error endpoints
    final errorEndpoints = _endpointStats.entries
        .where((e) => e.value.failedCalls > 0)
        .toList()
      ..sort((a, b) => b.value.failedCalls.compareTo(a.value.failedCalls));
    
    analysis['topErrorEndpoints'] = errorEndpoints
        .take(10)
        .map((e) => {
          'endpoint': e.key,
          'errorCount': e.value.failedCalls,
          'errorRate': e.value.errorRate,
          'mostCommonErrors': e.value.getMostCommonErrors(3),
        })
        .toList();
    
    // Error patterns (find common error strings)
    final allErrors = <String>[];
    _endpointStats.values.forEach((stats) {
      allErrors.addAll(stats.errors);
    });
    
    // Count error occurrences
    final errorCounts = <String, int>{};
    for (final error in allErrors) {
      errorCounts[error] = (errorCounts[error] ?? 0) + 1;
    }
    
    // Get top errors
    final topErrors = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    analysis['topErrors'] = topErrors
        .take(10)
        .map((e) => {
          'error': e.key,
          'count': e.value,
        })
        .toList();
    
    return analysis;
  }
  
  /// Xóa toàn bộ dữ liệu thống kê (thường gọi khi logout)
  void reset() {
    _recentRequests.clear();
    _endpointStats.clear();
    _activeRequests.clear();
    _totalRequestsCount = 0;
    _successfulRequestsCount = 0;
    _failedRequestsCount = 0;
    _totalResponseTime = 0;
    _fastestResponseTime = null;
    _slowestResponseTime = null;
    _hourlyRequestCounts.clear();
    _statusCodeDistribution.clear();
    _logger.debug('ApiRequestTracker: Đã reset tất cả dữ liệu thống kê');
  }
  
  /// Hủy tracker và giải phóng tài nguyên
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _logger.debug('ApiRequestTracker: Đã hủy');
  }
  
  /// Check if a status code indicates success
  bool _isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}

/// Lưu trữ thông tin về một request API
class ApiRequestInfo {
  final String id;
  final String method;
  final String endpoint;
  final DateTime startTime;
  final Map<String, dynamic>? params;
  
  DateTime? endTime;
  Duration? duration;
  int? statusCode;
  bool success = false;
  String? error;
  
  ApiRequestInfo({
    required this.id,
    required this.method,
    required this.endpoint,
    required this.startTime,
    this.params,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'endpoint': endpoint,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'statusCode': statusCode,
      'success': success,
      'error': error,
      'params': params,
    };
  }
}