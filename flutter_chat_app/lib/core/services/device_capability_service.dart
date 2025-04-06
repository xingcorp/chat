import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Class quản lý và đánh giá khả năng của thiết bị
/// để tự động điều chỉnh hiệu ứng và animation
class DeviceCapabilityService {
  /// Key lưu trữ điểm benchmark trong SharedPreferences
  static const String _benchmarkScoreKey = 'device_benchmark_score';
  
  /// Key lưu trữ mức animation trong SharedPreferences
  static const String _animationLevelKey = 'device_animation_level';
  
  /// Key lưu trữ ngày chạy benchmark gần nhất
  static const String _lastBenchmarkRunKey = 'last_benchmark_run';
  
  /// Số frames kiểm tra tối đa
  static const int _benchmarkFrames = 120;
  
  /// Thời gian tối đa chạy benchmark (ms)
  static const int _maxBenchmarkDuration = 5000;
  
  /// Số ngày sau khi chạy benchmark lại
  static const int _benchmarkIntervalDays = 30;
  
  /// Device Info plugin
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  /// Cấp độ animation hiện tại
  AnimationLevel _currentLevel = AnimationLevel.medium;
  
  /// Điểm benchmark
  double _benchmarkScore = 0;
  
  /// Trạng thái hoàn thành benchmark
  bool _isBenchmarkComplete = false;
  
  /// Stream thông báo thay đổi level
  final _levelChangeController = StreamController<AnimationLevel>.broadcast();
  
  /// Getter cho stream thay đổi level
  Stream<AnimationLevel> get onLevelChange => _levelChangeController.stream;
  
  /// Getter cho cấp độ animation hiện tại
  AnimationLevel get currentLevel => _currentLevel;
  
  /// Getter cho điểm benchmark
  double get benchmarkScore => _benchmarkScore;
  
  /// Getter cho trạng thái hoàn thành benchmark
  bool get isBenchmarkComplete => _isBenchmarkComplete;
  
  /// Khởi tạo service và load cấu hình
  Future<void> initialize() async {
    // Load cấu hình từ SharedPreferences
    await _loadSavedConfig();
    
    // Kiểm tra xem có cần chạy benchmark lại không
    if (_shouldRunBenchmark()) {
      // Chạy benchmark và cập nhật cấp độ
      await runBenchmark();
    }
  }
  
  /// Đánh giá khả năng thiết bị thông qua một benchmark đơn giản
  Future<void> runBenchmark() async {
    // Reset state
    _isBenchmarkComplete = false;
    
    // Lấy thông tin thiết bị trước
    final deviceInfo = await _getDeviceInfo();
    int framesRendered = 0;
    double totalFps = 0;
    int millisecondsElapsed = 0;
    
    final Stopwatch stopwatch = Stopwatch()..start();
    
    // Callback để đếm frames
    void frameCallback(Duration duration) {
      if (framesRendered < _benchmarkFrames && 
          stopwatch.elapsedMilliseconds < _maxBenchmarkDuration) {
        framesRendered++;
        millisecondsElapsed = stopwatch.elapsedMilliseconds;
        
        // Tiếp tục đếm frame tiếp theo
        WidgetsBinding.instance.scheduleFrameCallback(frameCallback);
      } else {
        // Tính FPS trung bình
        double averageFps = framesRendered / (millisecondsElapsed / 1000);
        
        // Lưu điểm benchmark là tổng hợp giữa FPS và thông tin thiết bị
        _calculateAndSaveBenchmarkScore(averageFps, deviceInfo);
      }
    }
    
    // Bắt đầu đếm frames
    WidgetsBinding.instance.scheduleFrameCallback(frameCallback);
    
    // Tạo một số animation để đo hiệu suất
    for (int i = 0; i < 3; i++) {
      await _runTestAnimation();
    }
    
    // Chờ benchmark hoàn thành
    while (!_isBenchmarkComplete && 
           stopwatch.elapsedMilliseconds < _maxBenchmarkDuration) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    stopwatch.stop();
    
    // Lưu ngày chạy benchmark
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBenchmarkRunKey, DateTime.now().toIso8601String());
  }
  
  /// Chạy animation test để đo hiệu suất
  Future<void> _runTestAnimation() async {
    return Future.delayed(const Duration(milliseconds: 500));
  }
  
  /// Tính toán và lưu điểm benchmark
  Future<void> _calculateAndSaveBenchmarkScore(double fps, Map<String, dynamic> deviceInfo) async {
    // Giới hạn FPS tối đa là 120
    fps = fps.clamp(0, 120);
    
    // Điểm dựa trên FPS (60% tỷ trọng)
    double fpsScore = (fps / 60) * 60;
    
    // Điểm dựa trên thông tin thiết bị (40% tỷ trọng)
    double deviceScore = _calculateDeviceScore(deviceInfo);
    
    // Tổng điểm (trên thang 100)
    _benchmarkScore = fpsScore + deviceScore;
    
    // Xác định cấp độ animation dựa trên điểm số
    _updateAnimationLevel(_benchmarkScore);
    
    // Lưu vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_benchmarkScoreKey, _benchmarkScore);
    await prefs.setInt(_animationLevelKey, _currentLevel.index);
    
    // Đánh dấu hoàn thành
    _isBenchmarkComplete = true;
  }
  
  /// Tính điểm dựa trên thông tin thiết bị
  double _calculateDeviceScore(Map<String, dynamic> deviceInfo) {
    // Điểm tối đa 40 cho thông tin thiết bị
    double score = 20.0; // Điểm cơ bản
    
    // Cộng điểm theo loại thiết bị và phiên bản OS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS điểm cao hơn do tối ưu tốt
      score += 5.0;
      
      // Điểm cho iOS version mới
      final String systemVersion = deviceInfo['systemVersion'] ?? '';
      final int majorVersion = int.tryParse(systemVersion.split('.').first) ?? 0;
      if (majorVersion >= 15) {
        score += 5.0;
      } else if (majorVersion >= 13) {
        score += 3.0;
      }
      
      // Kiểm tra model
      final String model = deviceInfo['model'] ?? '';
      if (model.contains('iPhone') && !model.contains('Simulator')) {
        // iPhone thật, không phải simulator
        score += 5.0;
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Điểm cho Android version mới
      final int sdkInt = deviceInfo['version']?['sdkInt'] ?? 0;
      if (sdkInt >= 31) { // Android 12+
        score += 5.0;
      } else if (sdkInt >= 29) { // Android 10+
        score += 3.0;
      }
      
      // Điểm cho RAM (giả định)
      if (deviceInfo.containsKey('totalMemory')) {
        final int totalMemory = deviceInfo['totalMemory'] ?? 0;
        if (totalMemory > 4 * 1024 * 1024 * 1024) { // > 4GB
          score += 5.0;
        } else if (totalMemory > 2 * 1024 * 1024 * 1024) { // > 2GB
          score += 3.0;
        }
      }
    }
    
    // Giới hạn điểm tối đa là 40
    return score.clamp(0, 40);
  }
  
  /// Cập nhật cấp độ animation dựa trên điểm benchmark
  void _updateAnimationLevel(double score) {
    AnimationLevel newLevel;
    
    if (score >= 80) {
      newLevel = AnimationLevel.high;
    } else if (score >= 50) {
      newLevel = AnimationLevel.medium;
    } else {
      newLevel = AnimationLevel.low;
    }
    
    // Chỉ thông báo nếu có thay đổi
    if (_currentLevel != newLevel) {
      _currentLevel = newLevel;
      _levelChangeController.add(_currentLevel);
    }
  }
  
  /// Lấy thông tin thiết bị
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return (await _deviceInfo.iosInfo).data;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        return (await _deviceInfo.androidInfo).data;
      } 
      return {};
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return {};
    }
  }
  
  /// Load cấu hình đã lưu
  Future<void> _loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load điểm benchmark
      _benchmarkScore = prefs.getDouble(_benchmarkScoreKey) ?? 0;
      
      // Load cấp độ animation
      final savedLevelIndex = prefs.getInt(_animationLevelKey);
      if (savedLevelIndex != null) {
        _currentLevel = AnimationLevel.values[savedLevelIndex];
      } else {
        // Mặc định nếu chưa có
        _currentLevel = AnimationLevel.medium;
      }
      
      // Đánh dấu đã hoàn thành nếu có điểm
      _isBenchmarkComplete = _benchmarkScore > 0;
    } catch (e) {
      debugPrint('Error loading saved config: $e');
    }
  }
  
  /// Kiểm tra xem có nên chạy benchmark lại không
  bool _shouldRunBenchmark() {
    // Chạy benchmark nếu chưa có điểm
    if (_benchmarkScore <= 0) {
      return true;
    }
    
    // Hoặc nếu đã quá thời gian quy định
    try {
      final prefs = SharedPreferences.getInstance();
      final lastRunStr = prefs.then((p) => p.getString(_lastBenchmarkRunKey));
      if (lastRunStr != null) {
        final lastRun = DateTime.parse(lastRunStr.toString());
        final daysSinceLastRun = DateTime.now().difference(lastRun).inDays;
        return daysSinceLastRun >= _benchmarkIntervalDays;
      }
    } catch (e) {
      debugPrint('Error checking benchmark interval: $e');
    }
    
    return true;
  }
  
  /// Thủ công set cấp độ animation (cho testing)
  Future<void> setAnimationLevel(AnimationLevel level) async {
    if (_currentLevel != level) {
      _currentLevel = level;
      _levelChangeController.add(_currentLevel);
      
      // Lưu cấu hình mới
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_animationLevelKey, _currentLevel.index);
    }
  }
  
  /// Dispose resources
  void dispose() {
    _levelChangeController.close();
  }
}

/// Các cấp độ animation hiệu ứng
enum AnimationLevel {
  /// Mức độ thấp: ít animation nhất, ưu tiên hiệu suất
  low,
  
  /// Mức độ trung bình: cân bằng giữa hiệu ứng và hiệu suất
  medium,
  
  /// Mức độ cao: đầy đủ hiệu ứng, giả định thiết bị mạnh
  high,
} 