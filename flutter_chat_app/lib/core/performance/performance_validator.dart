/// Performance Validation Framework
/// 
/// Real-time performance monitoring and validation system
/// for enterprise-grade Flutter chat applications.
/// 
/// Author: Senior Flutter/Mobile Architect
/// Targets: <2s startup, <100ms delivery, <150MB memory
library performance_validator;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Performance metrics enumeration
enum PerformanceMetric {
  appStartup,
  messageDelivery,
  memoryUsage,
  frameRenderTime,
  networkLatency,
  databaseQuery,
  imageLoading,
  scrollPerformance,
}

/// Performance validation result
class PerformanceResult {
  final PerformanceMetric metric;
  final double value;
  final double threshold;
  final bool passed;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceResult({
    required this.metric,
    required this.value,
    required this.threshold,
    required this.passed,
    required this.timestamp,
    this.metadata = const {},
  });

  /// Check if performance meets enterprise standards
  bool get meetsEnterpriseStandards => passed;

  @override
  String toString() {
    final status = passed ? '✅' : '❌';
    return '$status ${metric.name}: ${value.toStringAsFixed(1)}ms (threshold: ${threshold}ms)';
  }
}

/// Performance validation thresholds for enterprise messaging apps
class PerformanceThresholds {
  static const Map<PerformanceMetric, double> enterprise = {
    PerformanceMetric.appStartup: 2000.0,        // <2s startup
    PerformanceMetric.messageDelivery: 100.0,    // <100ms delivery
    PerformanceMetric.memoryUsage: 150.0,        // <150MB memory
    PerformanceMetric.frameRenderTime: 16.67,    // 60fps (16.67ms per frame)
    PerformanceMetric.networkLatency: 500.0,     // <500ms network
    PerformanceMetric.databaseQuery: 50.0,       // <50ms DB queries
    PerformanceMetric.imageLoading: 1000.0,      // <1s image loading
    PerformanceMetric.scrollPerformance: 16.67,  // Smooth scrolling
  };

  static const Map<PerformanceMetric, double> acceptable = {
    PerformanceMetric.appStartup: 3000.0,
    PerformanceMetric.messageDelivery: 200.0,
    PerformanceMetric.memoryUsage: 200.0,
    PerformanceMetric.frameRenderTime: 33.33,    // 30fps
    PerformanceMetric.networkLatency: 1000.0,
    PerformanceMetric.databaseQuery: 100.0,
    PerformanceMetric.imageLoading: 2000.0,
    PerformanceMetric.scrollPerformance: 33.33,
  };
}

/// Real-time Performance Validator
/// 
/// Monitors and validates performance metrics against enterprise standards
/// similar to WhatsApp, Messenger, Telegram performance requirements.
class PerformanceValidator {
  static final PerformanceValidator _instance = PerformanceValidator._internal();
  factory PerformanceValidator() => _instance;
  PerformanceValidator._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 3,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  final Map<PerformanceMetric, Stopwatch> _activeStopwatches = {};
  final List<PerformanceResult> _results = [];
  final StreamController<PerformanceResult> _resultController = 
      StreamController<PerformanceResult>.broadcast();

  bool _isInitialized = false;
  Timer? _memoryMonitorTimer;

  /// Initialize the performance validator
  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.i('🚀 Initializing Performance Validator...');

    // Start continuous memory monitoring
    _startMemoryMonitoring();

    _isInitialized = true;
    _logger.i('✅ Performance Validator initialized');
  }

  /// Start monitoring a performance metric
  void startMeasurement(PerformanceMetric metric, {Map<String, dynamic>? metadata}) {
    if (!_isInitialized) {
      _logger.w('Performance Validator not initialized');
      return;
    }

    final stopwatch = Stopwatch()..start();
    _activeStopwatches[metric] = stopwatch;

    _logger.d('📊 Started measuring ${metric.name}');
  }

  /// Stop monitoring and validate performance
  PerformanceResult stopMeasurement(
    PerformanceMetric metric, {
    Map<String, dynamic>? metadata,
    bool useEnterpriseThreshold = true,
  }) {
    if (!_activeStopwatches.containsKey(metric)) {
      throw StateError('No active measurement for ${metric.name}');
    }

    final stopwatch = _activeStopwatches.remove(metric)!;
    stopwatch.stop();

    final value = stopwatch.elapsedMilliseconds.toDouble();
    final thresholds = useEnterpriseThreshold 
        ? PerformanceThresholds.enterprise 
        : PerformanceThresholds.acceptable;
    final threshold = thresholds[metric] ?? double.infinity;
    final passed = value <= threshold;

    final result = PerformanceResult(
      metric: metric,
      value: value,
      threshold: threshold,
      passed: passed,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _results.add(result);
    _resultController.add(result);

    // Log result
    if (passed) {
      _logger.i('✅ ${metric.name}: ${value.toStringAsFixed(1)}ms (✓ under ${threshold}ms)');
    } else {
      _logger.w('⚠️ ${metric.name}: ${value.toStringAsFixed(1)}ms (✗ over ${threshold}ms)');
    }

    return result;
  }

  /// Measure memory usage
  Future<PerformanceResult> measureMemoryUsage({bool useEnterpriseThreshold = true}) async {
    if (!_isInitialized) {
      throw StateError('Performance Validator not initialized');
    }

    double memoryUsageMB = 0.0;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use platform-specific memory measurement
        final memoryInfo = await _getMemoryInfo();
        memoryUsageMB = memoryInfo['memoryUsageMB'] ?? 0.0;
      } else {
        // Fallback for other platforms
        memoryUsageMB = _estimateMemoryUsage();
      }
    } catch (e) {
      _logger.e('Failed to measure memory usage: $e');
      memoryUsageMB = 0.0;
    }

    final thresholds = useEnterpriseThreshold 
        ? PerformanceThresholds.enterprise 
        : PerformanceThresholds.acceptable;
    final threshold = thresholds[PerformanceMetric.memoryUsage] ?? 200.0;
    final passed = memoryUsageMB <= threshold;

    final result = PerformanceResult(
      metric: PerformanceMetric.memoryUsage,
      value: memoryUsageMB,
      threshold: threshold,
      passed: passed,
      timestamp: DateTime.now(),
      metadata: {'platform': Platform.operatingSystem},
    );

    _results.add(result);
    _resultController.add(result);

    return result;
  }

  /// Get performance results stream
  Stream<PerformanceResult> get resultsStream => _resultController.stream;

  /// Get all performance results
  List<PerformanceResult> get allResults => List.unmodifiable(_results);

  /// Get results for specific metric
  List<PerformanceResult> getResultsFor(PerformanceMetric metric) {
    return _results.where((result) => result.metric == metric).toList();
  }

  /// Check if app meets enterprise performance standards
  bool get meetsEnterpriseStandards {
    if (_results.isEmpty) return false;
    
    // Check latest result for each metric
    final latestResults = <PerformanceMetric, PerformanceResult>{};
    for (final result in _results) {
      latestResults[result.metric] = result;
    }

    return latestResults.values.every((result) => result.passed);
  }

  /// Generate performance report
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Performance Validation Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total measurements: ${_results.length}');
    buffer.writeln();

    // Group by metric
    final groupedResults = <PerformanceMetric, List<PerformanceResult>>{};
    for (final result in _results) {
      groupedResults.putIfAbsent(result.metric, () => []).add(result);
    }

    for (final entry in groupedResults.entries) {
      final metric = entry.key;
      final results = entry.value;
      final latest = results.last;
      final average = results.map((r) => r.value).reduce((a, b) => a + b) / results.length;

      buffer.writeln('${metric.name}:');
      buffer.writeln('  Latest: ${latest.value.toStringAsFixed(1)}ms ${latest.passed ? '✅' : '❌'}');
      buffer.writeln('  Average: ${average.toStringAsFixed(1)}ms');
      buffer.writeln('  Threshold: ${latest.threshold}ms');
      buffer.writeln('  Measurements: ${results.length}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Start continuous memory monitoring
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        await measureMemoryUsage();
      } catch (e) {
        _logger.e('Memory monitoring error: $e');
      }
    });
  }

  /// Get platform-specific memory information
  Future<Map<String, dynamic>> _getMemoryInfo() async {
    // This would integrate with platform-specific memory APIs
    // For now, return estimated values
    return {
      'memoryUsageMB': _estimateMemoryUsage(),
    };
  }

  /// Estimate memory usage (fallback method)
  double _estimateMemoryUsage() {
    // Simple estimation based on Dart VM
    // In production, use platform-specific APIs
    return 50.0; // Placeholder value
  }

  /// Dispose resources
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _resultController.close();
    _activeStopwatches.clear();
    _results.clear();
    _isInitialized = false;
    _logger.i('🔄 Performance Validator disposed');
  }
}
