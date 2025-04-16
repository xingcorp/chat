import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// CPU usage levels
enum CpuUsageLevel {
  /// Low level (<30%)
  low,
  
  /// Medium level (30-70%)
  medium,
  
  /// High level (>70%)
  high,
}

/// Memory usage levels
enum MemoryUsageLevel {
  /// Low level (<40%)
  low,
  
  /// Medium level (40-75%)
  medium,
  
  /// High level (>75%)
  high,
}

/// System resource state
class SystemResourceState {
  /// Current CPU usage level
  final CpuUsageLevel cpuLevel;
  
  /// Current memory usage level
  final MemoryUsageLevel memoryLevel;
  
  /// Current UI lag (ms)
  final int uiLagMs;
  
  /// Number of tasks in queue
  final int pendingTasksCount;
  
  SystemResourceState({
    required this.cpuLevel,
    required this.memoryLevel,
    required this.uiLagMs,
    required this.pendingTasksCount,
  });
  
  /// Calculate system load score (0-100)
  int get loadScore {
    int cpuScore = 0;
    switch (cpuLevel) {
      case CpuUsageLevel.low: cpuScore = 10; break;
      case CpuUsageLevel.medium: cpuScore = 30; break;
      case CpuUsageLevel.high: cpuScore = 50; break;
    }
    
    int memoryScore = 0;
    switch (memoryLevel) {
      case MemoryUsageLevel.low: memoryScore = 10; break;
      case MemoryUsageLevel.medium: memoryScore = 20; break;
      case MemoryUsageLevel.high: memoryScore = 30; break;
    }
    
    // UI lag over 16ms (< 60fps) starts to contribute
    int lagScore = uiLagMs > 16 ? ((uiLagMs - 16) / 2).round().clamp(0, 20) : 0;
    
    return (cpuScore + memoryScore + lagScore).clamp(0, 100);
  }
  
  /// Check if we should scale up workers
  bool shouldScaleUp(int currentWorkers, int maxWorkers) {
    if (currentWorkers >= maxWorkers) return false;
    
    // Scale up when:
    // 1. High load score
    // 2. Many pending tasks
    return loadScore > 60 || pendingTasksCount > currentWorkers * 3;
  }
  
  /// Check if we should scale down workers
  bool shouldScaleDown(int currentWorkers, int minWorkers) {
    if (currentWorkers <= minWorkers) return false;
    
    // Scale down when:
    // 1. Low load score
    // 2. Few pending tasks
    return loadScore < 30 && pendingTasksCount < currentWorkers;
  }
}

/// System resource monitoring service
@singleton
class SystemResourceMonitor {
  /// Timer for metrics collection
  Timer? _monitorTimer;
  
  /// Recent CPU usage samples
  final List<double> _recentCpuUsage = [];
  
  /// Last collection time
  DateTime? _lastCollectionTime;
  
  /// Stream controller for state change signals
  final _resourceStateController = StreamController<SystemResourceState>.broadcast();
  
  /// Stream of system resource states
  Stream<SystemResourceState> get resourceStateStream => _resourceStateController.stream;
  
  /// Current system state
  SystemResourceState _currentState = SystemResourceState(
    cpuLevel: CpuUsageLevel.low,
    memoryLevel: MemoryUsageLevel.low,
    uiLagMs: 0,
    pendingTasksCount: 0,
  );
  
  /// Current pending tasks count
  int _pendingTasksCount = 0;
  
  /// Current resource state
  SystemResourceState get currentState => _currentState;
  
  /// Initialize the monitor
  void initialize({Duration monitorInterval = const Duration(seconds: 5)}) {
    if (_monitorTimer != null) return;
    
    _monitorTimer = Timer.periodic(monitorInterval, (_) {
      _collectMetrics();
    });
  }
  
  /// Update the pending tasks count
  void updatePendingTasksCount(int count) {
    _pendingTasksCount = count;
  }
  
  /// Collect system metrics
  Future<void> _collectMetrics() async {
    try {
      final now = DateTime.now();
      final elapsedMs = _lastCollectionTime != null 
          ? now.difference(_lastCollectionTime!).inMilliseconds 
          : 0;
      _lastCollectionTime = now;
      
      // Can only read CPU on non-web platforms
      CpuUsageLevel cpuLevel = CpuUsageLevel.low;
      if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
        final cpuUsage = await _getCpuUsage();
        if (cpuUsage != null) {
          _recentCpuUsage.add(cpuUsage);
          if (_recentCpuUsage.length > 5) {
            _recentCpuUsage.removeAt(0);
          }
          
          final avgCpuUsage = _recentCpuUsage.isNotEmpty
              ? _recentCpuUsage.reduce((a, b) => a + b) / _recentCpuUsage.length
              : 0.0;
          
          if (avgCpuUsage > 70) {
            cpuLevel = CpuUsageLevel.high;
          } else if (avgCpuUsage > 30) {
            cpuLevel = CpuUsageLevel.medium;
          }
        }
      }
      
      // Read memory usage
      MemoryUsageLevel memoryLevel = MemoryUsageLevel.low;
      if (!kIsWeb) {
        final memoryInfo = await _getMemoryInfo();
        if (memoryInfo != null) {
          final memoryUsage = memoryInfo.$1;
          
          if (memoryUsage > 75) {
            memoryLevel = MemoryUsageLevel.high;
          } else if (memoryUsage > 40) {
            memoryLevel = MemoryUsageLevel.medium;
          }
        }
      }
      
      // Estimate UI lag based on execution time (approximate)
      int uiLagMs = 0;
      if (_monitorTimer != null) {
        // Use fixed interval if timer exists
        final monitorInterval = 5000; // Default to 5 seconds in milliseconds
            
        uiLagMs = elapsedMs > monitorInterval
            ? (elapsedMs - monitorInterval).clamp(0, 1000).toInt()
            : 0;
      }
      
      // Update state
      _currentState = SystemResourceState(
        cpuLevel: cpuLevel,
        memoryLevel: memoryLevel,
        uiLagMs: uiLagMs,
        pendingTasksCount: _pendingTasksCount,
      );
      
      // Signal state change
      _resourceStateController.add(_currentState);
    } catch (e) {
      debugPrint('Error collecting system metrics: $e');
    }
  }
  
  /// Get CPU usage percentage
  Future<double?> _getCpuUsage() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        // Simplified approach - in real app would use platform-specific commands
        return 30.0; // Mock value - would need to implement platform-specific code
      } else if (Platform.isWindows) {
        // Windows-specific implementation would go here
        return 30.0; // Mock value
      }
    } catch (e) {
      debugPrint('Error getting CPU usage: $e');
    }
    return null;
  }
  
  /// Get memory usage information
  Future<(double, int)?> _getMemoryInfo() async {
    try {
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        // Simplified approach - in real app would use platform-specific commands
        // Returns (percentage used, total MB)
        return (45.0, 8192); // Mock values
      }
    } catch (e) {
      debugPrint('Error getting memory info: $e');
    }
    return null;
  }
  
  /// Dispose resources
  void dispose() {
    _monitorTimer?.cancel();
    _resourceStateController.close();
  }
} 