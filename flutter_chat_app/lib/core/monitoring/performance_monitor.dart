import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Các loại trace hiệu suất được theo dõi
enum TraceType {
  /// Khởi động ứng dụng
  appStartup,
  
  /// Tải danh sách chat
  loadChats,
  
  /// Tải tin nhắn
  loadMessages,
  
  /// Gửi tin nhắn
  sendMessage,
  
  /// Upload media
  uploadMedia,
  
  /// Tải thông tin người dùng
  loadUserProfile,
  
  /// Đồng bộ dữ liệu nền
  backgroundSync,
  
  /// Tải trang
  pageLoad,
  
  /// Chuyển màn hình
  navigation,
  
  /// Custom trace
  custom,
}

/// Tên của các trace
const Map<TraceType, String> _traceNames = {
  TraceType.appStartup: 'app_startup',
  TraceType.loadChats: 'load_chats',
  TraceType.loadMessages: 'load_messages',
  TraceType.sendMessage: 'send_message',
  TraceType.uploadMedia: 'upload_media',
  TraceType.loadUserProfile: 'load_user_profile',
  TraceType.backgroundSync: 'background_sync',
  TraceType.pageLoad: 'page_load',
  TraceType.navigation: 'navigation',
  TraceType.custom: 'custom',
};

/// Class quản lý theo dõi hiệu suất
@singleton
class PerformanceMonitor {
  /// Logger
  final _logger = Logger();
  
  /// Firebase Performance instance
  final FirebasePerformance _performance;
  
  /// Các trace đang hoạt động
  final Map<String, Trace> _activeTraces = {};
  
  /// Các HTTP metrics đang hoạt động
  final Map<String, HttpMetric> _activeHttpMetrics = {};
  
  /// Có đang thu thập performance data hay không
  bool _isPerformanceCollectionEnabled = true;
  
  /// Constructor
  PerformanceMonitor(this._performance);
  
  /// Khởi tạo performance monitor
  Future<void> initialize() async {
    try {
      _logger.i('Khởi tạo Performance Monitor');
      
      // Disable trong chế độ debug
      _isPerformanceCollectionEnabled = !kDebugMode;
      
      // Cấu hình Firebase Performance
      await _performance.setPerformanceCollectionEnabled(_isPerformanceCollectionEnabled);
      
      _logger.i('Performance Monitor đã được khởi tạo. Bật thu thập: $_isPerformanceCollectionEnabled');
    } catch (e) {
      _logger.e('Lỗi khi khởi tạo Performance Monitor: $e');
    }
  }
  
  /// Bắt đầu trace một hoạt động
  Future<void> startTrace(
    TraceType type, {
    String? customTraceName,
    Map<String, String>? attributes,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final traceName = type == TraceType.custom && customTraceName != null
          ? customTraceName
          : _traceNames[type] ?? 'unknown';
      
      // Nếu trace đang tồn tại, dừng trace đó trước
      if (_activeTraces.containsKey(traceName)) {
        _logger.w('Trace $traceName đang hoạt động, dừng trước khi bắt đầu mới');
        await stopTrace(type, customTraceName: customTraceName);
      }
      
      // Tạo trace mới
      final trace = _performance.newTrace(traceName);
      await trace.start();
      
      // Thêm attributes nếu có
      if (attributes != null) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value);
        });
      }
      
      // Lưu vào danh sách đang hoạt động
      _activeTraces[traceName] = trace;
      
      _logger.v('Bắt đầu trace: $traceName');
    } catch (e) {
      _logger.e('Lỗi khi bắt đầu trace: $e');
    }
  }
  
  /// Kết thúc trace
  Future<void> stopTrace(
    TraceType type, {
    String? customTraceName,
    Map<String, int>? metrics,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final traceName = type == TraceType.custom && customTraceName != null
          ? customTraceName
          : _traceNames[type] ?? 'unknown';
      
      final trace = _activeTraces.remove(traceName);
      if (trace == null) {
        _logger.w('Không tìm thấy trace $traceName để dừng');
        return;
      }
      
      // Thêm metrics nếu có
      if (metrics != null) {
        metrics.forEach((key, value) {
          trace.putMetric(key, value);
        });
      }
      
      // Dừng trace
      await trace.stop();
      
      _logger.v('Dừng trace: $traceName');
    } catch (e) {
      _logger.e('Lỗi khi dừng trace: $e');
    }
  }
  
  /// Thêm metric vào trace đang hoạt động
  Future<void> addTraceMetric(
    TraceType type, {
    String? customTraceName,
    required String metricName,
    required int value,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final traceName = type == TraceType.custom && customTraceName != null
          ? customTraceName
          : _traceNames[type] ?? 'unknown';
      
      final trace = _activeTraces[traceName];
      if (trace == null) {
        _logger.w('Không tìm thấy trace $traceName để thêm metric');
        return;
      }
      
      // Thêm metric
      trace.putMetric(metricName, value);
      
      _logger.v('Thêm metric $metricName = $value cho trace $traceName');
    } catch (e) {
      _logger.e('Lỗi khi thêm metric cho trace: $e');
    }
  }
  
  /// Thêm attribute vào trace đang hoạt động
  Future<void> addTraceAttribute(
    TraceType type, {
    String? customTraceName,
    required String attributeName,
    required String value,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final traceName = type == TraceType.custom && customTraceName != null
          ? customTraceName
          : _traceNames[type] ?? 'unknown';
      
      final trace = _activeTraces[traceName];
      if (trace == null) {
        _logger.w('Không tìm thấy trace $traceName để thêm attribute');
        return;
      }
      
      // Thêm attribute
      trace.putAttribute(attributeName, value);
      
      _logger.v('Thêm attribute $attributeName = $value cho trace $traceName');
    } catch (e) {
      _logger.e('Lỗi khi thêm attribute cho trace: $e');
    }
  }
  
  /// Bắt đầu theo dõi HTTP request
  Future<void> startHttpMetric(
    String url,
    HttpMethod method, {
    Map<String, String>? attributes,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final key = '${method.toString()}_$url';
      
      // Nếu metric đã tồn tại, dừng lại trước
      if (_activeHttpMetrics.containsKey(key)) {
        _logger.w('HTTP metric $key đang hoạt động, dừng trước khi bắt đầu mới');
        await stopHttpMetric(url, method);
      }
      
      // Tạo HTTP metric mới
      final httpMetric = _performance.newHttpMetric(url, method);
      await httpMetric.start();
      
      // Thêm attributes nếu có
      if (attributes != null) {
        attributes.forEach((key, value) {
          httpMetric.putAttribute(key, value);
        });
      }
      
      // Lưu vào danh sách đang hoạt động
      _activeHttpMetrics[key] = httpMetric;
      
      _logger.v('Bắt đầu HTTP metric: $key');
    } catch (e) {
      _logger.e('Lỗi khi bắt đầu HTTP metric: $e');
    }
  }
  
  /// Kết thúc theo dõi HTTP request
  Future<void> stopHttpMetric(
    String url,
    HttpMethod method, {
    int? responseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
    String? contentType,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final key = '${method.toString()}_$url';
      
      final httpMetric = _activeHttpMetrics.remove(key);
      if (httpMetric == null) {
        _logger.w('Không tìm thấy HTTP metric $key để dừng');
        return;
      }
      
      // Thêm thông tin bổ sung
      if (responseCode != null) {
        httpMetric.httpResponseCode = responseCode;
      }
      
      if (requestPayloadSize != null) {
        httpMetric.requestPayloadSize = requestPayloadSize;
      }
      
      if (responsePayloadSize != null) {
        httpMetric.responsePayloadSize = responsePayloadSize;
      }
      
      if (contentType != null) {
        httpMetric.putAttribute('content_type', contentType);
      }
      
      // Dừng HTTP metric
      await httpMetric.stop();
      
      _logger.v('Dừng HTTP metric: $key');
    } catch (e) {
      _logger.e('Lỗi khi dừng HTTP metric: $e');
    }
  }
  
  /// Tạo và thực thi trace trong một hàm
  Future<T> traceFunction<T>(
    TraceType type,
    Future<T> Function() function, {
    String? customTraceName,
    Map<String, String>? attributes,
  }) async {
    // Bắt đầu trace
    await startTrace(type, customTraceName: customTraceName, attributes: attributes);
    
    try {
      // Thực thi hàm
      final result = await function();
      return result;
    } finally {
      // Đảm bảo dừng trace ngay cả khi có lỗi
      await stopTrace(type, customTraceName: customTraceName);
    }
  }
  
  /// Tạo và thực thi HTTP trace trong một hàm
  Future<T> traceHttpFunction<T>(
    String url,
    HttpMethod method,
    Future<T> Function() function, {
    Map<String, String>? attributes,
    void Function(T result)? onResult,
  }) async {
    // Bắt đầu HTTP metric
    await startHttpMetric(url, method, attributes: attributes);
    
    try {
      // Thực thi hàm
      final result = await function();
      
      // Gọi callback nếu có
      onResult?.call(result);
      
      return result;
    } catch (e) {
      // Ghi lại lỗi
      _activeHttpMetrics['${method.toString()}_$url']?.putAttribute('error', e.toString());
      rethrow;
    } finally {
      // Đảm bảo dừng HTTP metric ngay cả khi có lỗi
      await stopHttpMetric(url, method);
    }
  }
  
  /// Đặt thuộc tính chung sẽ được thêm vào tất cả các trace và HTTP metric
  Future<void> setGlobalAttributes(Map<String, String> attributes) async {
    try {
      // Thêm cho tất cả các trace đang hoạt động
      for (final trace in _activeTraces.values) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value);
        });
      }
      
      // Thêm cho tất cả các HTTP metric đang hoạt động
      for (final httpMetric in _activeHttpMetrics.values) {
        attributes.forEach((key, value) {
          httpMetric.putAttribute(key, value);
        });
      }
    } catch (e) {
      _logger.e('Lỗi khi đặt global attributes: $e');
    }
  }
} 