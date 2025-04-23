import 'dart:collection';

import 'package:flutter/foundation.dart';
import '../../monitoring/logger.dart';
import '../../monitoring/analytics_service.dart';

/// Class để theo dõi và phân tích hiệu suất API requests
class ApiRequestTracker {
  static ApiRequestTracker? _instance;
  static ApiRequestTracker get instance => _instance!;
  
  final AppLogger _logger;
  final AnalyticsService _analytics;
  
  // Số lượng tối đa request được lưu trữ
  static const int _maxStoredRequests = 50;
  
  // Lưu trữ thông tin các request gần đây
  final ListQueue<ApiRequestInfo> _recentRequests = 
      ListQueue<ApiRequestInfo>(_maxStoredRequests);
  
  // Lưu trữ thời gian phản hồi trung bình theo endpoint
  final Map<String, _EndpointStats> _endpointStats = {};
  
  // Theo dõi các request đang hoạt động
  final Map<String, ApiRequestInfo> _activeRequests = {};
  
  static Future<void> init({
    required AppLogger logger,
    required AnalyticsService analytics,
  }) async {
    if (_instance != null) return;
    
    _instance = ApiRequestTracker._(
      logger: logger,
      analytics: analytics,
    );
    
    _instance!._logger.debug('ApiRequestTracker: Đã khởi tạo');
  }
  
  ApiRequestTracker._({
    required AppLogger logger,
    required AnalyticsService analytics,
  }) : _logger = logger,
       _analytics = analytics;
  
  /// Bắt đầu theo dõi một request API
  String startRequest(String method, String endpoint, {Map<String, dynamic>? params}) {
    final requestId = _generateRequestId();
    final timestamp = DateTime.now();
    
    final requestInfo = ApiRequestInfo(
      id: requestId,
      method: method,
      endpoint: endpoint,
      startTime: timestamp,
      params: params,
    );
    
    _activeRequests[requestId] = requestInfo;
    
    if (kDebugMode) {
      _logger.debug('API Request [$method] $endpoint started (ID: $requestId)');
    }
    
    return requestId;
  }
  
  /// Hoàn thành một request API
  void completeRequest(String requestId, int statusCode, {Object? response}) {
    final requestInfo = _activeRequests[requestId];
    if (requestInfo == null) {
      _logger.warn('Không tìm thấy request ID: $requestId để hoàn thành');
      return;
    }
    
    // Cập nhật thông tin request
    final endTime = DateTime.now();
    final duration = endTime.difference(requestInfo.startTime);
    
    requestInfo.endTime = endTime;
    requestInfo.duration = duration;
    requestInfo.statusCode = statusCode;
    requestInfo.success = statusCode >= 200 && statusCode < 300;
    
    // Lưu trữ request vào danh sách gần đây
    _addToRecentRequests(requestInfo);
    
    // Cập nhật thống kê theo endpoint
    _updateEndpointStats(requestInfo);
    
    // Gửi analytics nếu request không thành công
    if (!requestInfo.success) {
      _analytics.logEvent(
        AnalyticsEvent.apiError, 
        {
          'endpoint': requestInfo.endpoint,
          'method': requestInfo.method,
          'status_code': statusCode,
          'duration_ms': duration.inMilliseconds,
        },
      );
    }
    
    // Ghi log
    if (kDebugMode) {
      final durationMs = duration.inMilliseconds;
      final statusText = requestInfo.success ? 'success' : 'failed';
      _logger.debug(
        'API Request [$requestInfo.method] ${requestInfo.endpoint} $statusText '
        '(${durationMs}ms, Status: $statusCode)',
      );
    }
    
    // Xóa khỏi danh sách đang hoạt động
    _activeRequests.remove(requestId);
  }
  
  /// Đánh dấu request bị lỗi
  void failRequest(String requestId, dynamic error) {
    final requestInfo = _activeRequests[requestId];
    if (requestInfo == null) {
      _logger.warn('Không tìm thấy request ID: $requestId để đánh dấu lỗi');
      return;
    }
    
    // Cập nhật thông tin request
    final endTime = DateTime.now();
    final duration = endTime.difference(requestInfo.startTime);
    
    requestInfo.endTime = endTime;
    requestInfo.duration = duration;
    requestInfo.error = error.toString();
    requestInfo.success = false;
    
    // Lưu trữ request vào danh sách gần đây
    _addToRecentRequests(requestInfo);
    
    // Cập nhật thống kê theo endpoint
    _updateEndpointStats(requestInfo);
    
    // Gửi analytics
    _analytics.logEvent(
      AnalyticsEvent.apiError, 
      {
        'endpoint': requestInfo.endpoint,
        'method': requestInfo.method,
        'error': error.toString(),
        'duration_ms': duration.inMilliseconds,
      },
    );
    
    // Ghi log
    _logger.error(
      'API Request [${requestInfo.method}] ${requestInfo.endpoint} failed: $error '
      '(${duration.inMilliseconds}ms)',
    );
    
    // Xóa khỏi danh sách đang hoạt động
    _activeRequests.remove(requestId);
  }
  
  /// Lấy tất cả các request gần đây
  List<ApiRequestInfo> getRecentRequests() {
    return List.from(_recentRequests);
  }
  
  /// Lấy thống kê tổng quan
  ApiRequestStats getStats() {
    // Tính số lượng thành công/thất bại
    int totalRequests = 0;
    int successfulRequests = 0;
    int failedRequests = 0;
    int totalDurationMs = 0;
    
    for (final request in _recentRequests) {
      totalRequests++;
      if (request.success) {
        successfulRequests++;
      } else {
        failedRequests++;
      }
      
      if (request.duration != null) {
        totalDurationMs += request.duration!.inMilliseconds;
      }
    }
    
    // Tính thời gian phản hồi trung bình
    final avgResponseTime = totalRequests > 0 
        ? totalDurationMs / totalRequests 
        : 0;
    
    // Tính tỷ lệ thành công
    final successRate = totalRequests > 0 
        ? (successfulRequests / totalRequests) * 100 
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
            ))
        .toList();
    
    return ApiRequestStats(
      totalRequests: totalRequests,
      successfulRequests: successfulRequests,
      failedRequests: failedRequests,
      averageResponseTime: avgResponseTime,
      successRate: successRate,
      slowestEndpoints: slowestEndpoints,
    );
  }
  
  /// Thêm request vào danh sách gần đây
  void _addToRecentRequests(ApiRequestInfo request) {
    if (_recentRequests.length >= _maxStoredRequests) {
      _recentRequests.removeLast();
    }
    _recentRequests.addFirst(request);
  }
  
  /// Cập nhật thống kê theo endpoint
  void _updateEndpointStats(ApiRequestInfo request) {
    if (request.duration == null) return;
    
    final endpoint = request.endpoint;
    final stats = _endpointStats[endpoint] ?? _EndpointStats();
    
    // Cập nhật thống kê
    stats.totalCalls++;
    stats.totalDuration += request.duration!.inMilliseconds;
    if (request.success) {
      stats.successfulCalls++;
    }
    
    // Tính lại các giá trị
    stats.avgResponseTime = stats.totalDuration / stats.totalCalls;
    stats.successRate = (stats.successfulCalls / stats.totalCalls) * 100;
    
    _endpointStats[endpoint] = stats;
  }
  
  /// Tạo ID cho request
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '${timestamp}_$random';
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
}

/// Lưu trữ thống kê theo endpoint
class _EndpointStats {
  int totalCalls = 0;
  int successfulCalls = 0;
  int totalDuration = 0;
  double avgResponseTime = 0;
  double successRate = 0;
}

/// Thống kê tổng quan về API requests
class ApiRequestStats {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double averageResponseTime;
  final double successRate;
  final List<EndpointStat> slowestEndpoints;
  
  ApiRequestStats({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.averageResponseTime,
    required this.successRate,
    required this.slowestEndpoints,
  });
}

/// Thống kê về một endpoint cụ thể
class EndpointStat {
  final String endpoint;
  final double avgResponseTime;
  final double successRate;
  final int totalCalls;
  
  EndpointStat({
    required this.endpoint,
    required this.avgResponseTime,
    required this.successRate,
    required this.totalCalls,
  });
} 