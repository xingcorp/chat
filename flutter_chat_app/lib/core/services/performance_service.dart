import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_memory_info/flutter_memory_info.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Các loại đo lường hiệu suất
enum PerformanceMetricType {
  /// Thời gian tải màn hình
  screenLoad,
  
  /// Thời gian render UI
  uiRender,
  
  /// Network request
  network,
  
  /// Xử lý dữ liệu
  dataProcessing,
  
  /// Media processing
  mediaProcessing,
  
  /// Database operations
  database,
  
  /// Khởi động ứng dụng
  appStartup,
  
  /// Tuỳ chỉnh
  custom,
}

/// Kết quả của memory snapshot
class MemoryInfo {
  /// Total memory sử dụng (bytes)
  final int totalMemoryBytes;
  
  /// Free memory (bytes)
  final int freeMemoryBytes;
  
  /// Memory sử dụng bởi ứng dụng (bytes)
  final int appMemoryBytes;
  
  /// Thời điểm đo
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

/// Thông tin hiệu suất realtime
class PerformanceStats {
  /// FPS hiện tại
  final double fps;
  
  /// Memory usage
  final MemoryInfo memory;
  
  /// CPU usage (phần trăm)
  final double cpuUsage;
  
  /// Thời điểm render frame
  final Duration buildTime;
  
  /// Thời điểm khởi tạo
  final DateTime timestamp;
  
  /// Constructor
  PerformanceStats({
    required this.fps,
    required this.memory,
    required this.cpuUsage,
    required this.buildTime,
    required this.timestamp,
  });
  
  /// Tạo từ giá trị mặc định
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
  
  /// Kiểm tra xem FPS có dưới ngưỡng chấp nhận được
  bool get isLowFps => fps < 55;
  
  /// Kiểm tra xem memory usage có cao
  bool get isHighMemory => memory.memoryUsagePercent > 70;
  
  /// Kiểm tra xem CPU usage có cao
  bool get isHighCpu => cpuUsage > 80;
  
  /// Kiểm tra xem build time có cao
  bool get isSlowBuild => buildTime.inMilliseconds > 16;
}

/// Stream thông tin hiệu suất realtime
class PerformanceObserver {
  /// Stream controller
  final _controller = StreamController<PerformanceStats>.broadcast();
  
  /// Stream thông tin hiệu suất
  Stream<PerformanceStats> get stats => _controller.stream;
  
  /// Thêm thông tin hiệu suất mới
  void addStats(PerformanceStats stats) {
    if (!_controller.isClosed) {
      _controller.add(stats);
    }
  }
  
  /// Đóng stream
  void dispose() {
    _controller.close();
  }
}

/// Service đo lường và quản lý hiệu suất ứng dụng
@lazySingleton
class PerformanceService {
  final FirebasePerformance _firebasePerformance;
  final _logger = Logger();
  
  /// Traces đang hoạt động
  final Map<String, Trace> _activeTraces = {};
  
  /// HTTP metrics đang hoạt động
  final Map<String, HttpMetric> _activeHttpMetrics = {};
  
  /// Lưu trữ thời gian cho các hoạt động tạm thời
  final Map<String, int> _timers = {};
  
  /// Lưu trữ memory snapshots
  final List<MemoryInfo> _memorySnapshots = [];
  
  /// Đang thu thập hiệu suất
  bool _isPerformanceCollectionEnabled = !kDebugMode;
  
  /// Hiển thị overlay hiệu suất
  bool _showPerformanceOverlay = false;
  
  /// Performance observer
  final _performanceObserver = PerformanceObserver();
  
  /// Ticker để đo FPS
  Ticker? _ticker;
  
  /// Ticker callback
  Duration _lastTickTime = Duration.zero;
  
  /// FPS counter
  int _fpsCounter = 0;
  
  /// FPS hiện tại
  double _currentFps = 0;
  
  /// CPU usage hiện tại
  double _currentCpuUsage = 0;
  
  /// Thời gian build trung bình
  Duration _buildTime = Duration.zero;
  
  /// Timer cho việc thu thập thông tin hiệu suất
  Timer? _statsTimer;
  
  /// Overlay entry cho widget hiệu suất
  OverlayEntry? _overlayEntry;
  
  /// Tạo mới service
  PerformanceService(this._firebasePerformance);
  
  /// Lấy performance observer
  PerformanceObserver get observer => _performanceObserver;
  
  /// Hiển thị có overlay hiệu suất không
  bool get showPerformanceOverlay => _showPerformanceOverlay;
  
  /// Thiết lập trạng thái hiển thị overlay hiệu suất
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
  
  /// Hiển thị/ẩn overlay hiệu suất
  void togglePerformanceOverlay() {
    showPerformanceOverlay = !showPerformanceOverlay;
  }
  
  /// Khởi tạo service
  Future<void> initialize() async {
    try {
      _logger.i('Initializing Performance Service');
      
      // Cấu hình Firebase Performance
      await _firebasePerformance.setPerformanceCollectionEnabled(_isPerformanceCollectionEnabled);
      
      _logger.i('Performance Service initialized. Collection enabled: $_isPerformanceCollectionEnabled');
      
      // Khởi tạo FPS ticker nếu trong chế độ debug
      if (kDebugMode) {
        _initializeTicker();
      }
    } catch (e) {
      _logger.e('Error initializing Performance Service: $e');
    }
  }
  
  /// Khởi tạo ticker để đo FPS
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
  
  /// Bắt đầu theo dõi hiệu suất realtime
  void _startPerformanceMonitoring() {
    // Bắt đầu ticker để đo FPS
    _ticker?.start();
    
    // Cập nhật thông tin hiệu suất mỗi 1 giây
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      // Tính toán FPS
      _currentFps = _fpsCounter.toDouble();
      _fpsCounter = 0;
      
      // Lấy thông tin memory
      final memory = await getMemoryInfo();
      
      // Tạo thông tin hiệu suất
      final stats = PerformanceStats(
        fps: _currentFps,
        memory: memory,
        cpuUsage: _currentCpuUsage,
        buildTime: _buildTime,
        timestamp: DateTime.now(),
      );
      
      // Gửi thông tin hiệu suất
      _performanceObserver.addStats(stats);
      
      // Ghi log nếu hiệu suất thấp
      if (stats.isLowFps) {
        _logger.w('Low FPS detected: ${stats.fps.toStringAsFixed(1)} FPS');
      }
      
      if (stats.isHighMemory) {
        _logger.w('High memory usage: ${stats.memory.memoryUsagePercent.toStringAsFixed(1)}%');
      }
    });
  }
  
  /// Dừng theo dõi hiệu suất realtime
  void _stopPerformanceMonitoring() {
    _ticker?.stop();
    _statsTimer?.cancel();
    _statsTimer = null;
  }
  
  /// Cập nhật overlay hiệu suất
  void _updateOverlay() {
    // Xóa overlay cũ nếu có
    _overlayEntry?.remove();
    _overlayEntry = null;
    
    // Tạo overlay mới nếu cần hiển thị
    if (_showPerformanceOverlay) {
      // Lấy BuildContext từ navigator hiện tại
      final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (context == null) return;
      
      final overlay = Overlay.of(context);
      if (overlay == null) return;
      
      _overlayEntry = OverlayEntry(
        builder: (context) => PerformanceOverlay(observer: _performanceObserver),
      );
      
      overlay.insert(_overlayEntry!);
    }
  }
  
  /// Kiểm tra và report nếu sử dụng quá nhiều memory
  Future<void> checkMemoryUsage({double thresholdPercent = 70.0}) async {
    final memoryInfo = await getMemoryInfo();
    
    if (memoryInfo.memoryUsagePercent > thresholdPercent) {
      _logger.w('High memory usage detected: ${memoryInfo.memoryUsagePercent.toStringAsFixed(1)}%');
      // Thực hiện các biện pháp giảm memory như clear caches, image caches, v.v...
    }
  }
  
  /// Lấy thông tin memory hiện tại
  Future<MemoryInfo> getMemoryInfo() async {
    final memoryInfo = await FlutterMemoryInfo().memoryInfo;
    
    final result = MemoryInfo(
      totalMemoryBytes: memoryInfo.totalMem,
      freeMemoryBytes: memoryInfo.availMem,
      appMemoryBytes: memoryInfo.appUsedMem,
      timestamp: DateTime.now(),
    );
    
    // Lưu vào history để phân tích xu hướng
    _memorySnapshots.add(result);
    
    // Giới hạn số lượng snapshots để tránh memory leak
    if (_memorySnapshots.length > 100) {
      _memorySnapshots.removeAt(0);
    }
    
    return result;
  }
  
  /// Ghi lại thời gian build frame
  void recordBuildTime(Duration elapsed) {
    _buildTime = elapsed;
  }
  
  /// Bắt đầu đo thời gian một hoạt động
  Future<void> startTrace(
    PerformanceMetricType type, {
    String? customName,
    Map<String, String>? attributes,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final traceName = _getMetricName(type, customName);
      
      // Nếu trace đang tồn tại, dừng trace đó trước
      await stopTrace(type, customName: customName);
      
      // Tạo trace mới
      final trace = _firebasePerformance.newTrace(traceName);
      await trace.start();
      
      // Thêm attributes nếu có
      if (attributes != null) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value);
        });
      }
      
      // Lưu vào danh sách đang hoạt động
      _activeTraces[traceName] = trace;
      
      _logger.d('Started trace: $traceName');
    } catch (e) {
      _logger.e('Error starting trace: $e');
    }
  }
  
  /// Dừng đo thời gian một hoạt động
  Future<void> stopTrace(
    PerformanceMetricType type, {
    String? customName,
    Map<String, int>? metrics,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final traceName = _getMetricName(type, customName);
      
      final trace = _activeTraces.remove(traceName);
      if (trace == null) {
        return;
      }
      
      // Thêm metrics nếu có
      if (metrics != null) {
        metrics.forEach((key, value) {
          trace.setMetric(key, value);
        });
      }
      
      // Dừng trace
      await trace.stop();
      
      _logger.d('Stopped trace: $traceName');
    } catch (e) {
      _logger.e('Error stopping trace: $e');
    }
  }
  
  /// Bắt đầu HTTP metric
  Future<void> startHttpMetric(
    String url,
    HttpMethod method, {
    Map<String, String>? attributes,
  }) async {
    if (!_isPerformanceCollectionEnabled) return;
    
    try {
      final metricKey = '$method-$url';
      
      // Nếu metric đang tồn tại, dừng metric đó trước
      await stopHttpMetric(url, method);
      
      // Tạo metric mới
      final metric = _firebasePerformance.newHttpMetric(url, method);
      
      // Thêm attributes nếu có
      if (attributes != null) {
        attributes.forEach((key, value) {
          metric.putAttribute(key, value);
        });
      }
      
      await metric.start();
      
      // Lưu vào danh sách đang hoạt động
      _activeHttpMetrics[metricKey] = metric;
      
      _logger.d('Started HTTP metric: $metricKey');
    } catch (e) {
      _logger.e('Error starting HTTP metric: $e');
    }
  }
  
  /// Dừng HTTP metric
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
      final metricKey = '$method-$url';
      
      final metric = _activeHttpMetrics.remove(metricKey);
      if (metric == null) {
        return;
      }
      
      // Thêm thông tin
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
      
      // Dừng metric
      await metric.stop();
      
      _logger.d('Stopped HTTP metric: $metricKey');
    } catch (e) {
      _logger.e('Error stopping HTTP metric: $e');
    }
  }
  
  /// Đo thời gian một đoạn code
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
  
  /// Bắt đầu timer tạm thời (không gửi lên Firebase)
  void startTimer(String name) {
    _timers[name] = DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Dừng timer và trả về thời gian (ms)
  int stopTimer(String name) {
    final startTime = _timers.remove(name);
    if (startTime == null) return 0;
    
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final duration = endTime - startTime;
    
    _logger.d('Timer $name: $duration ms');
    return duration;
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _stopPerformanceMonitoring();
    _ticker?.dispose();
    _ticker = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _performanceObserver.dispose();
  }
  
  /// Lấy tên metric từ loại và tên tuỳ chỉnh
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

/// Widget overlay hiển thị thông tin hiệu suất
class PerformanceOverlay extends StatefulWidget {
  /// Performance observer
  final PerformanceObserver observer;
  
  /// Constructor
  const PerformanceOverlay({Key? key, required this.observer}) : super(key: key);
  
  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  /// Thông tin hiệu suất hiện tại
  PerformanceStats _stats = PerformanceStats.empty();
  
  /// Lịch sử FPS
  final List<double> _fpsHistory = List.filled(30, 60);
  
  /// Lịch sử memory usage
  final List<double> _memoryHistory = List.filled(30, 0);
  
  @override
  void initState() {
    super.initState();
    widget.observer.stats.listen((stats) {
      if (mounted) {
        setState(() {
          _stats = stats;
          
          // Cập nhật lịch sử
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
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.all(8),
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              
              // Phiên bản chi tiết hơn có thể thêm các thông tin khác ở đây
            ],
          ),
        ),
      ),
    );
  }
  
  /// Tạo dòng thông tin hiệu suất
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
  
  /// Tạo đồ thị mini
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

/// Painter để vẽ đồ thị mini
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