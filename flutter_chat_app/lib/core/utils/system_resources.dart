import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Mức sử dụng CPU
enum CpuUsageLevel {
  /// Mức thấp (<30%)
  low,
  
  /// Mức trung bình (30-70%)
  medium,
  
  /// Mức cao (>70%)
  high,
}

/// Mức sử dụng memory
enum MemoryUsageLevel {
  /// Mức thấp (<40%)
  low,
  
  /// Mức trung bình (40-75%)
  medium,
  
  /// Mức cao (>75%)
  high,
}

/// Trạng thái tài nguyên hệ thống
class SystemResourceState {
  /// Mức sử dụng CPU hiện tại
  final CpuUsageLevel cpuLevel;
  
  /// Mức sử dụng memory hiện tại
  final MemoryUsageLevel memoryLevel;
  
  /// Độ trễ (lag) hiện tại (ms)
  final int uiLagMs;
  
  /// Số tác vụ đang chờ trong queue
  final int pendingTasksCount;
  
  SystemResourceState({
    required this.cpuLevel,
    required this.memoryLevel,
    required this.uiLagMs,
    required this.pendingTasksCount,
  });
  
  /// Tính điểm tải cho hệ thống (0-100)
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
  
  /// Kiểm tra xem có nên tăng worker không
  bool shouldScaleUp(int currentWorkers, int maxWorkers) {
    if (currentWorkers >= maxWorkers) return false;
    
    // Tăng worker khi:
    // 1. Load score cao
    // 2. Nhiều tác vụ đang chờ xử lý
    return loadScore > 60 || pendingTasksCount > currentWorkers * 3;
  }
  
  /// Kiểm tra xem có nên giảm worker không
  bool shouldScaleDown(int currentWorkers, int minWorkers) {
    if (currentWorkers <= minWorkers) return false;
    
    // Giảm worker khi:
    // 1. Load score thấp
    // 2. Ít tác vụ đang chờ xử lý
    return loadScore < 30 && pendingTasksCount < currentWorkers;
  }
}

/// Service theo dõi tài nguyên hệ thống
@singleton
class SystemResourceMonitor {
  /// Timer cho việc thu thập metrics
  Timer? _monitorTimer;
  
  /// CPU usage gần đây
  final List<double> _recentCpuUsage = [];
  
  /// Thời điểm thu thập cuối cùng
  DateTime? _lastCollectionTime;
  
  /// Stream controller để phát tín hiệu khi có thay đổi
  final _resourceStateController = StreamController<SystemResourceState>.broadcast();
  
  /// Stream của trạng thái tài nguyên hệ thống
  Stream<SystemResourceState> get resourceStateStream => _resourceStateController.stream;
  
  /// Trạng thái hiện tại
  SystemResourceState _currentState = SystemResourceState(
    cpuLevel: CpuUsageLevel.low,
    memoryLevel: MemoryUsageLevel.low,
    uiLagMs: 0,
    pendingTasksCount: 0,
  );
  
  /// Trạng thái tài nguyên hiện tại
  SystemResourceState get currentState => _currentState;
  
  /// Khởi tạo monitor
  void initialize({Duration monitorInterval = const Duration(seconds: 5)}) {
    if (_monitorTimer != null) return;
    
    _monitorTimer = Timer.periodic(monitorInterval, (_) {
      _collectMetrics();
    });
  }
  
  /// Thu thập metrics hệ thống
  Future<void> _collectMetrics() async {
    try {
      final now = DateTime.now();
      final elapsedMs = _lastCollectionTime != null 
          ? now.difference(_lastCollectionTime!).inMilliseconds 
          : 0;
      _lastCollectionTime = now;
      
      // Chỉ có thể đọc CPU trên nền tảng không phải web
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
      
      // Đọc memory usage
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
      
      // Ước tính độ trễ UI dựa trên thời gian thực thi (gần đúng)
      int uiLagMs = elapsedMs > monitorInterval.inMilliseconds
          ? (elapsedMs - monitorInterval.inMilliseconds).clamp(0, 1000)
          : 0;
      
      // Cập nhật trạng thái
      _currentState = SystemResourceState(
        cpuLevel: cpuLevel,
        memoryLevel: memoryLevel,
        uiLagMs: uiLagMs,
        pendingTasksCount: _pendingTasksCount,
      );
      
      // Phát tín hiệu thay đổi
      _resourceStateController.add(_currentState);
    } catch (e) {
      debugPrint('Error collecting system metrics: $e');
    }
  }
  
  /// Lấy thông tin CPU usage (%)
  Future<double?> _getCpuUsage() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        final result = await Process.run('top', ['-bn1']);
        final output = result.stdout.toString();
        
        // Phân tích output để lấy CPU usage
        // Cách phân tích phụ thuộc vào OS cụ thể
        
        // Ví dụ đơn giản cho macOS - cần điều chỉnh theo output thực tế
        final cpuLines = RegExp(r'CPU usage: ([0-9\.]+)% user, ([0-9\.]+)% sys')
            .firstMatch(output);
        
        if (cpuLines != null) {
          final userCpu = double.tryParse(cpuLines.group(1) ?? '0') ?? 0;
          final sysCpu = double.tryParse(cpuLines.group(2) ?? '0') ?? 0;
          return userCpu + sysCpu;
        }
      } else if (Platform.isWindows) {
        final result = await Process.run('wmic', ['cpu', 'get', 'loadpercentage']);
        final output = result.stdout.toString();
        
        final cpuMatch = RegExp(r'(\d+)').firstMatch(output);
        if (cpuMatch != null) {
          return double.tryParse(cpuMatch.group(1) ?? '0') ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error getting CPU usage: $e');
    }
    
    return null;
  }
  
  /// Lấy thông tin memory usage (%)
  Future<(double, double)?> _getMemoryInfo() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('free', ['-m']);
        final output = result.stdout.toString();
        
        final lines = output.split('\n');
        if (lines.length > 1) {
          final memoryLine = lines[1].trim().split(RegExp(r'\s+'));
          if (memoryLine.length > 6) {
            final total = double.tryParse(memoryLine[1]) ?? 0;
            final used = double.tryParse(memoryLine[2]) ?? 0;
            
            if (total > 0) {
              final usagePercent = (used / total) * 100;
              return (usagePercent, total);
            }
          }
        }
      } else if (Platform.isMacOS) {
        final result = await Process.run('vm_stat', []);
        final output = result.stdout.toString();
        
        // Parse vm_stat output
        final pageSize = RegExp(r'page size of (\d+) bytes').firstMatch(output)?.group(1);
        final pageBytes = int.tryParse(pageSize ?? '4096') ?? 4096;
        
        final freePages = RegExp(r'Pages free:\s+(\d+)').firstMatch(output)?.group(1);
        final activePages = RegExp(r'Pages active:\s+(\d+)').firstMatch(output)?.group(1);
        final inactivePages = RegExp(r'Pages inactive:\s+(\d+)').firstMatch(output)?.group(1);
        final wiredPages = RegExp(r'Pages wired down:\s+(\d+)').firstMatch(output)?.group(1);
        
        final free = int.tryParse(freePages ?? '0') ?? 0;
        final active = int.tryParse(activePages ?? '0') ?? 0;
        final inactive = int.tryParse(inactivePages ?? '0') ?? 0;
        final wired = int.tryParse(wiredPages ?? '0') ?? 0;
        
        final total = free + active + inactive + wired;
        final used = active + wired;
        
        if (total > 0) {
          final usagePercent = (used / total) * 100;
          return (usagePercent, total * pageBytes / (1024 * 1024));
        }
      } else if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'OS', 'get', 'FreePhysicalMemory,TotalVisibleMemorySize'
        ]);
        final output = result.stdout.toString();
        
        final lines = output.split('\n');
        if (lines.length > 1) {
          final memoryLine = lines[1].trim().split(RegExp(r'\s+'));
          if (memoryLine.length >= 2) {
            final free = double.tryParse(memoryLine[0]) ?? 0;
            final total = double.tryParse(memoryLine[1]) ?? 0;
            
            if (total > 0) {
              final used = total - free;
              final usagePercent = (used / total) * 100;
              return (usagePercent, total / 1024);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting memory info: $e');
    }
    
    return null;
  }
  
  /// Cập nhật số lượng tác vụ đang chờ xử lý
  int _pendingTasksCount = 0;
  void updatePendingTasksCount(int count) {
    if (_pendingTasksCount != count) {
      _pendingTasksCount = count;
      
      // Phân tích lại và phát tín hiệu
      _collectMetrics();
    }
  }
  
  /// Dispose resources
  void dispose() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _resourceStateController.close();
  }
} 