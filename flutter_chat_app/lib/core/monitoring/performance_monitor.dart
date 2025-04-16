import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Performance trace types
enum TraceType {
  /// App startup
  appStartup,
  
  /// Loading chat list
  loadChats,
  
  /// Loading messages
  loadMessages,
  
  /// Sending messages
  sendMessage,
  
  /// Media uploads
  uploadMedia,
  
  /// Loading user profile
  loadUserProfile,
  
  /// Background data sync
  backgroundSync,
  
  /// Page loading
  pageLoad,
  
  /// Screen navigation
  navigation,
  
  /// Custom trace
  custom,
}

/// Names of traces
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

/// Performance monitoring management class
@singleton
class PerformanceMonitor {
  /// Logger
  final _logger = Logger();
  
  /// Firebase Performance instance
  final FirebasePerformance _performance;
  
  /// Active traces
  final Map<String, Trace> _activeTraces = {};
  
  /// Active HTTP metrics
  final Map<String, HttpMetric> _activeHttpMetrics = {};
  
  /// Whether performance data collection is enabled
  bool _isPerformanceCollectionEnabled = true;
  
  /// Constructor
  PerformanceMonitor(this._performance);
  
  /// Initialize performance monitor
  Future<void> initialize() async {
    try {
      _logger.i('Initializing Performance Monitor');
      
      // Disable in debug mode
      _isPerformanceCollectionEnabled = !kDebugMode;
      
      // Configure Firebase Performance
      await _performance.setPerformanceCollectionEnabled(_isPerformanceCollectionEnabled);
      
      _logger.i('Performance Monitor initialized. Collection enabled: $_isPerformanceCollectionEnabled');
    } catch (e) {
      _logger.e('Error initializing Performance Monitor: $e');
    }
  }
  
  /// Start tracing an activity
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
      
      // If trace already exists, stop it before starting a new one
      if (_activeTraces.containsKey(traceName)) {
        _logger.w('Trace $traceName is already active, stopping before starting a new one');
        await stopTrace(type, customTraceName: customTraceName);
      }
      
      // Create new trace
      final trace = _performance.newTrace(traceName);
      await trace.start();
      
      // Add attributes if available
      if (attributes != null) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value);
        });
      }
      
      // Save to active traces list
      _activeTraces[traceName] = trace;
      
      _logger.v('Started trace: $traceName');
    } catch (e) {
      _logger.e('Error starting trace: $e');
    }
  }
  
  /// Stop a trace
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
        _logger.w('Trace $traceName not found to stop');
        return;
      }
      
      // Add metrics if available
      if (metrics != null) {
        metrics.forEach((key, value) {
          trace.setMetric(key, value);
        });
      }
      
      // Stop trace
      await trace.stop();
      
      _logger.v('Stopped trace: $traceName');
    } catch (e) {
      _logger.e('Error stopping trace: $e');
    }
  }
  
  /// Add metric to active trace
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
        _logger.w('Trace $traceName not found to add metric');
        return;
      }
      
      // Add metric
      trace.setMetric(metricName, value);
      
      _logger.v('Added metric $metricName = $value for trace $traceName');
    } catch (e) {
      _logger.e('Error adding metric to trace: $e');
    }
  }
  
  /// Add attribute to active trace
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
        _logger.w('Trace $traceName not found to add attribute');
        return;
      }
      
      // Add attribute
      trace.putAttribute(attributeName, value);
      
      _logger.v('Added attribute $attributeName = $value for trace $traceName');
    } catch (e) {
      _logger.e('Error adding attribute to trace: $e');
    }
  }
  
  /// Start tracking HTTP metric
  Future<void> startHttpMetric(
    String url,
    HttpMethod method, {
    Map<String, String>? attributes,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      // Create a unique key for this HTTP request
      final key = '${method.toString()}_$url';
      
      // If metric already exists, stop it first
      if (_activeHttpMetrics.containsKey(key)) {
        _logger.w('HTTP Metric for $key already exists, stopping first');
        await stopHttpMetric(url, method);
      }
      
      // Start new metric
      final metric = _performance.newHttpMetric(url, method);
      await metric.start();
      
      // Add attributes if available
      if (attributes != null) {
        attributes.forEach((attrKey, value) {
          metric.putAttribute(attrKey, value);
        });
      }
      
      // Save to active metrics
      _activeHttpMetrics[key] = metric;
      
      _logger.v('Started HTTP metric: $key');
    } catch (e) {
      _logger.e('Error starting HTTP metric: $e');
    }
  }
  
  /// Stop tracking HTTP metric
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
      
      final metric = _activeHttpMetrics.remove(key);
      if (metric == null) {
        _logger.w('HTTP Metric for $key not found to stop');
        return;
      }
      
      // Set additional info if available
      if (responseCode != null) {
        metric.httpResponseCode = responseCode;
      }
      
      if (requestPayloadSize != null) {
        metric.requestPayloadSize = requestPayloadSize;
      }
      
      if (responsePayloadSize != null) {
        metric.responsePayloadSize = responsePayloadSize;
      }
      
      if (contentType != null) {
        metric.putAttribute('content_type', contentType);
      }
      
      // Stop metric
      await metric.stop();
      
      _logger.v('Stopped HTTP metric: $key');
    } catch (e) {
      _logger.e('Error stopping HTTP metric: $e');
    }
  }
  
  /// Record custom metric (outside of a trace)
  void recordCustomMetric(String name, double value) {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      _logger.v('Recorded custom metric: $name = $value');
      // Implementation depends on analytics system
    } catch (e) {
      _logger.e('Error recording custom metric: $e');
    }
  }
  
  /// Record custom event
  void recordEvent(String name, {Map<String, dynamic>? parameters}) {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      _logger.v('Recorded event: $name with params: $parameters');
      // Implementation depends on analytics system
    } catch (e) {
      _logger.e('Error recording event: $e');
    }
  }
} 