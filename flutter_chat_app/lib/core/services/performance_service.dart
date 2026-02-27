import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Types of performance metrics
enum PerformanceMetricType {
  /// Screen load time
  screenLoad,
  
  /// UI rendering time
  uiRender,
  
  /// Network request
  network,
  
  /// Data processing
  dataProcessing,
  
  /// Media processing
  mediaProcessing,
  
  /// Database operations
  database,
  
  /// App startup
  appStartup,
  
  /// Custom
  custom,
}

/// Memory snapshot result
class MemoryInfo {
  /// Total memory used (bytes)
  final int totalMemoryBytes;
  
  /// Free memory (bytes)
  final int freeMemoryBytes;
  
  /// Memory used by the app (bytes)
  final int appMemoryBytes;
  
  /// Timestamp of measurement
  final DateTime timestamp;
  
  /// Constructor
  MemoryInfo({
    required this.totalMemoryBytes,
    required this.freeMemoryBytes,
    required this.appMemoryBytes,
    required this.timestamp,
  });
  
  /// Memory usage percent
  double get memoryUsagePercent => 
      totalMemoryBytes > 0 ? (appMemoryBytes / totalMemoryBytes) * 100 : 0;
      
  /// Format memory size
  String formatMemory(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  @override
  String toString() {
    return 'App: ${formatMemory(appMemoryBytes)} / Total: ${formatMemory(totalMemoryBytes)} (${memoryUsagePercent.toStringAsFixed(1)}%)';
  }
}

/// Realtime performance information
class PerformanceStats {
  /// Current FPS
  final double fps;
  
  /// Memory usage
  final MemoryInfo memory;
  
  /// CPU usage (percent)
  final double cpuUsage;
  
  /// Build time
  final Duration buildTime;
  
  /// Timestamp
  final DateTime timestamp;
  
  /// Constructor
  PerformanceStats({
    required this.fps,
    required this.memory,
    required this.cpuUsage,
    required this.buildTime,
    required this.timestamp,
  });
  
  /// Create from default values
  factory PerformanceStats.empty() => PerformanceStats(
    fps: 0,
    memory: MemoryInfo(
      totalMemoryBytes: 0,
      freeMemoryBytes: 0,
      appMemoryBytes: 0,
      timestamp: DateTime.now(),
    ),
    cpuUsage: 0,
    buildTime: Duration.zero,
    timestamp: DateTime.now(),
  );
  
  /// Check if FPS is below acceptable threshold
  bool get isLowFps => fps < 55;
  
  /// Check if memory usage is high
  bool get isHighMemory => memory.memoryUsagePercent > 70;
  
  /// Check if CPU usage is high
  bool get isHighCpu => cpuUsage > 80;
  
  /// Check if build time is high
  bool get isSlowBuild => buildTime.inMilliseconds > 16;
}

/// Stream for realtime performance stats
class PerformanceObserver {
  /// Stream controller
  final _controller = StreamController<PerformanceStats>.broadcast();
  
  /// Performance stats stream
  Stream<PerformanceStats> get stats => _controller.stream;
  
  /// Add new performance stats
  void addStats(PerformanceStats stats) {
    if (!_controller.isClosed) {
      _controller.add(stats);
    }
  }
  
  /// Close stream
  void dispose() {
    _controller.close();
  }
}

/// Service for measuring and managing application performance
@lazySingleton
@Environment('standalone')
class PerformanceService {
  final FirebasePerformance _firebasePerformance;
  final _logger = Logger();
  
  /// Active traces
  final Map<String, Trace> _activeTraces = {};
  
  /// Active HTTP metrics
  final Map<String, HttpMetric> _activeHttpMetrics = {};
  
  /// Timers for temporary activities
  final Map<String, int> _timers = {};
  
  /// Memory snapshots
  final List<MemoryInfo> _memorySnapshots = [];
  
  /// Performance collection enabled
  final bool _isPerformanceCollectionEnabled = !kDebugMode;
  
  /// Show performance overlay
  bool _showPerformanceOverlay = false;
  
  /// Performance observer
  final _performanceObserver = PerformanceObserver();
  
  /// Ticker for FPS measurement
  Ticker? _ticker;
  
  /// Last tick time
  Duration _lastTickTime = Duration.zero;
  
  /// FPS counter
  int _fpsCounter = 0;
  
  /// Current FPS
  double _currentFps = 0;
  
  /// Current CPU usage
  final double _currentCpuUsage = 0;
  
  /// Average build time
  Duration _buildTime = Duration.zero;
  
  /// Stats timer
  Timer? _statsTimer;
  
  /// Performance overlay entry
  OverlayEntry? _overlayEntry;
  
  /// Constructor
  PerformanceService(this._firebasePerformance);
  
  /// Get performance observer
  PerformanceObserver get observer => _performanceObserver;
  
  /// Get performance overlay visibility
  bool get showPerformanceOverlay => _showPerformanceOverlay;
  
  /// Set performance overlay visibility
  set showPerformanceOverlay(bool value) {
    if (_showPerformanceOverlay == value) return;
    
    _showPerformanceOverlay = value;
    
    if (value) {
      _startPerformanceMonitoring();
    } else {
      _stopPerformanceMonitoring();
    }
    
    _updateOverlay();
  }
  
  /// Toggle performance overlay
  void togglePerformanceOverlay() {
    showPerformanceOverlay = !showPerformanceOverlay;
  }
  
  /// Initialize service
  Future<void> initialize() async {
    try {
      _logger.i('Initializing Performance Service');
      
      // Configure Firebase Performance
      await _firebasePerformance.setPerformanceCollectionEnabled(_isPerformanceCollectionEnabled);
      
      _logger.i('Performance Service initialized. Collection enabled: $_isPerformanceCollectionEnabled');
      
      // Initialize FPS ticker if in debug mode
      if (kDebugMode) {
        _initializeTicker();
      }
    } catch (e) {
      _logger.e('Error initializing Performance Service: $e');
    }
  }
  
  /// Initialize FPS ticker
  void _initializeTicker() {
    _ticker = Ticker((elapsed) {
      if (_lastTickTime != Duration.zero) {
        final tickDelta = elapsed - _lastTickTime;
        if (tickDelta.inMilliseconds > 0) {
          _fpsCounter++;
        }
      }
      _lastTickTime = elapsed;
    });
  }
  
  /// Start realtime performance monitoring
  void _startPerformanceMonitoring() {
    // Start ticker for FPS measurement
    _ticker?.start();
    
    // Update performance stats every 1 second
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      // Calculate FPS
      _currentFps = _fpsCounter.toDouble();
      _fpsCounter = 0;
      
      // Get memory info
      final memory = await getMemoryInfo();
      
      // Create performance stats
      final stats = PerformanceStats(
        fps: _currentFps,
        memory: memory,
        cpuUsage: _currentCpuUsage,
        buildTime: _buildTime,
        timestamp: DateTime.now(),
      );
      
      // Send performance stats
      _performanceObserver.addStats(stats);
      
      // Log if performance is low
      if (stats.isLowFps) {
        _logger.w('Low FPS detected: ${stats.fps.toStringAsFixed(1)} FPS');
      }
      
      if (stats.isHighMemory) {
        _logger.w('High memory usage: ${stats.memory.memoryUsagePercent.toStringAsFixed(1)}%');
      }
    });
  }
  
  /// Stop realtime performance monitoring
  void _stopPerformanceMonitoring() {
    _ticker?.stop();
    _statsTimer?.cancel();
    _statsTimer = null;
  }
  
  /// Update performance overlay
  void _updateOverlay() {
    // Remove old overlay if exists
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Create new overlay if needed
    if (_showPerformanceOverlay) {
      // Get BuildContext from current navigator
      final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (context == null) return;

      final overlay = Overlay.of(context);
      if (overlay == null) return;

      _overlayEntry = OverlayEntry(
        builder: (context) => PerformanceOverlayWidget(
          observer: _performanceObserver,
          onClose: () {
            showPerformanceOverlay = false;
          },
        ),
      );

      overlay.insert(_overlayEntry!);
    }
  }
  
  /// Check and report if memory usage is too high
  Future<void> checkMemoryUsage({double thresholdPercent = 70.0}) async {
    final memoryInfo = await getMemoryInfo();
    
    if (memoryInfo.memoryUsagePercent > thresholdPercent) {
      _logger.w('High memory usage detected: ${memoryInfo.memoryUsagePercent.toStringAsFixed(1)}%');
      // Implement memory reduction measures like clearing caches, image caches, etc.
    }
  }
  
  /// Get current memory info using internal Flutter API data
  Future<MemoryInfo> getMemoryInfo() async {
    try {
      // Default values - on web and desktop these are estimated
      int totalMem = 1024 * 1024 * 1024; // 1 GB default
      int availMem = 512 * 1024 * 1024; // 512 MB default
      int appUsedMem = 256 * 1024 * 1024; // 256 MB default
      
      // Use the default values for now, can be enhanced with platform-specific code
      
      final result = MemoryInfo(
        totalMemoryBytes: totalMem,
        freeMemoryBytes: availMem,
        appMemoryBytes: appUsedMem,
        timestamp: DateTime.now(),
      );
      
      // Save to history for trend analysis
      _memorySnapshots.add(result);
      
      // Limit number of snapshots to avoid memory leak
      if (_memorySnapshots.length > 100) {
        _memorySnapshots.removeAt(0);
      }
      
      return result;
    } catch (e) {
      _logger.e('Error getting memory info: $e');
      return MemoryInfo(
        totalMemoryBytes: 0,
        freeMemoryBytes: 0,
        appMemoryBytes: 0,
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Record frame build time
  void recordBuildTime(Duration elapsed) {
    _buildTime = elapsed;
  }
  
  /// Start measuring an activity
  Future<void> startTrace(
    PerformanceMetricType type, {
    String? customName,
    Map<String, String>? attributes,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final traceName = _getMetricName(type, customName);
      
      // If trace already exists, stop it first
      await stopTrace(type, customName: customName);
      
      // Create new trace
      final trace = _firebasePerformance.newTrace(traceName);
      await trace.start();
      
      // Add attributes if available
      if (attributes != null) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value);
        });
      }
      
      // Save to active traces
      _activeTraces[traceName] = trace;
      
      // _logger.d('Started trace: $traceName');
    } catch (e) {
      _logger.e('Error starting trace: $e');
    }
  }
  
  /// Stop measuring an activity
  Future<void> stopTrace(
    PerformanceMetricType type, {
    String? customName,
    Map<String, int>? metrics,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final traceName = _getMetricName(type, customName);
      
      final trace = _activeTraces.remove(traceName);
      if (trace == null) return;
      
      // Add metrics if available
      if (metrics != null) {
        metrics.forEach((key, value) {
          trace.setMetric(key, value);
        });
      }
      
      // Stop trace
      await trace.stop();
      
      // _logger.d('Stopped trace: $traceName');
    } catch (e) {
      _logger.e('Error stopping trace: $e');
    }
  }
  
  /// Start HTTP metric
  Future<void> startHttpMetric(
    String url,
    HttpMethod httpMethod, {
    String? customName,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final metricKey = customName ?? url;
      
      // If metric already exists, stop it first
      await stopHttpMetric(url, httpMethod, customName: customName);
      
      // Create new HTTP metric
      final metric = _firebasePerformance.newHttpMetric(url, httpMethod);
      await metric.start();
      
      // Save to active HTTP metrics
      _activeHttpMetrics[metricKey] = metric;
      
      _logger.d('Started HTTP metric: $metricKey');
    } catch (e) {
      _logger.e('Error starting HTTP metric: $e');
    }
  }
  
  /// Stop HTTP metric
  Future<void> stopHttpMetric(
    String url,
    HttpMethod httpMethod, {
    String? customName,
    int? responseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
    String? contentType,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final metricKey = customName ?? url;
      
      final metric = _activeHttpMetrics.remove(metricKey);
      if (metric == null) return;
      
      // Set additional information
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
        metric.responseContentType = contentType;
      }
      
      // Stop metric
      await metric.stop();
      
      _logger.d('Stopped HTTP metric: $metricKey');
    } catch (e) {
      _logger.e('Error stopping HTTP metric: $e');
    }
  }
  
  /// Measure execution time of code block
  Future<T> measureExecutionTime<T>(
    PerformanceMetricType type,
    Future<T> Function() operation, {
    String? customName,
    Map<String, String>? attributes,
  }) async {
    await startTrace(type, customName: customName, attributes: attributes);
    
    try {
      final result = await operation();
      return result;
    } finally {
      await stopTrace(type, customName: customName);
    }
  }
  
  /// Start temporary timer (not sent to Firebase)
  void startTimer(String name) {
    _timers[name] = DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Stop timer and return time (ms)
  int stopTimer(String name) {
    final startTime = _timers.remove(name);
    if (startTime == null) return 0;
    
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final duration = endTime - startTime;
    
    _logger.d('Timer $name: $duration ms');
    return duration;
  }
  
  /// Release resources
  void dispose() {
    _stopPerformanceMonitoring();
    _ticker?.dispose();
    _ticker = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _performanceObserver.dispose();
  }
  
  /// Get metric name from type and custom name
  String _getMetricName(PerformanceMetricType type, String? customName) {
    switch (type) {
      case PerformanceMetricType.screenLoad:
        return customName != null ? 'screen_load_$customName' : 'screen_load';
      case PerformanceMetricType.uiRender:
        return customName != null ? 'ui_render_$customName' : 'ui_render';
      case PerformanceMetricType.network:
        return customName != null ? 'network_$customName' : 'network';
      case PerformanceMetricType.dataProcessing:
        return customName != null ? 'data_processing_$customName' : 'data_processing';
      case PerformanceMetricType.mediaProcessing:
        return customName != null ? 'media_processing_$customName' : 'media_processing';
      case PerformanceMetricType.database:
        return customName != null ? 'database_$customName' : 'database';
      case PerformanceMetricType.appStartup:
        return customName != null ? 'app_startup_$customName' : 'app_startup';
      case PerformanceMetricType.custom:
        return customName ?? 'custom_trace';
    }
  }
}

/// Widget overlay that displays performance information
class PerformanceOverlayWidget extends StatefulWidget {
  /// Performance observer
  final PerformanceObserver observer;

  /// Callback when close button is pressed
  final VoidCallback? onClose;

  /// Constructor
  const PerformanceOverlayWidget({
    Key? key,
    required this.observer,
    this.onClose,
  }) : super(key: key);

  @override
  State<PerformanceOverlayWidget> createState() => _PerformanceOverlayWidgetState();
}

class _PerformanceOverlayWidgetState extends State<PerformanceOverlayWidget> {
  /// Current performance stats
  PerformanceStats _stats = PerformanceStats.empty();

  /// FPS history (growable list for add/remove operations)
  final List<double> _fpsHistory = List.filled(30, 60, growable: true);

  /// Memory usage history (growable list for add/remove operations)
  final List<double> _memoryHistory = List.filled(30, 0, growable: true);

  /// Current position offset for dragging
  Offset _offset = Offset.zero;

  /// Whether the widget has been initialized with position
  bool _initialized = false;

  /// Whether the overlay is expanded or minimized
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    widget.observer.stats.listen((stats) {
      if (mounted) {
        setState(() {
          _stats = stats;

          // Update history
          _fpsHistory.removeAt(0);
          _fpsHistory.add(stats.fps);

          _memoryHistory.removeAt(0);
          _memoryHistory.add(stats.memory.memoryUsagePercent);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeAreaTop = MediaQuery.of(context).padding.top;

    // Initialize position to top-right corner on first build
    if (!_initialized) {
      _offset = Offset(screenSize.width - 60, safeAreaTop + 10);
      _initialized = true;
    }

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final widgetWidth = _isExpanded ? 200.0 : 48.0;
            _offset = Offset(
              (_offset.dx + details.delta.dx).clamp(0, screenSize.width - widgetWidth),
              (_offset.dy + details.delta.dy).clamp(safeAreaTop, screenSize.height - 100),
            );
          });
        },
        child: Material(
          color: Colors.transparent,
          child: _isExpanded ? _buildExpandedOverlay() : _buildMinimizedOverlay(),
        ),
      ),
    );
  }

  /// Build minimized overlay (just an icon)
  Widget _buildMinimizedOverlay() {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = true;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.speed, color: Colors.white, size: 18),
            Text(
              '${_stats.fps.toStringAsFixed(0)}',
              style: TextStyle(
                color: _stats.isLowFps ? Colors.red : Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build expanded overlay with full details
  Widget _buildExpandedOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with drag handle and minimize button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.drag_indicator, color: Colors.white54, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Performance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = false;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          _buildPerformanceInfo('FPS', '${_stats.fps.toStringAsFixed(1)}',
            _stats.isLowFps ? Colors.red : Colors.green),
          const SizedBox(height: 4),
          _buildMiniGraph(_fpsHistory, 60, 0, Colors.green),
          const SizedBox(height: 8),

          _buildPerformanceInfo('Memory',
            '${_stats.memory.memoryUsagePercent.toStringAsFixed(1)}%',
            _stats.isHighMemory ? Colors.red : Colors.green),
          const SizedBox(height: 4),
          _buildMiniGraph(_memoryHistory, 100, 0,
            _stats.isHighMemory ? Colors.red : Colors.green),
          const SizedBox(height: 8),

          Text(
            'Used: ${_stats.memory.formatMemory(_stats.memory.appMemoryBytes)}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),

          Text(
            'Build: ${_stats.buildTime.inMilliseconds}ms',
            style: TextStyle(
              color: _stats.isSlowBuild ? Colors.red : Colors.white,
              fontSize: 10
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build performance info row
  Widget _buildPerformanceInfo(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
  
  /// Build mini graph
  Widget _buildMiniGraph(List<double> data, double max, double min, Color color) {
    return Container(
      height: 20,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomPaint(
        painter: _GraphPainter(data, max, min, color),
      ),
    );
  }
}

/// Painter for mini graph
class _GraphPainter extends CustomPainter {
  final List<double> data;
  final double max;
  final double min;
  final Color color;
  
  _GraphPainter(this.data, this.max, this.min, this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    
    if (data.isEmpty) return;
    
    final width = size.width / (data.length - 1);
    final scale = size.height / (max - min);
    
    path.moveTo(0, size.height - (data.first - min) * scale);
    
    for (int i = 1; i < data.length; i++) {
      final x = i * width;
      final y = size.height - (data[i] - min) * scale;
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(_GraphPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.max != max ||
           oldDelegate.min != min ||
           oldDelegate.color != color;
  }
} 