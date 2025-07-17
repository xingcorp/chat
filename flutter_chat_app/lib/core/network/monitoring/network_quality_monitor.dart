import 'dart:async';

import 'package:logger/logger.dart';

import '../models/network_quality.dart';
import '../socket_analytics.dart';

/// Monitor theo dõi chất lượng kết nối mạng Socket
class NetworkQualityMonitor {
  final Logger _logger;
  final SocketAnalytics _analytics;
  
  // Timer kiểm tra chất lượng kết nối định kỳ
  Timer? _qualityCheckTimer;
  
  // Controller theo dõi chất lượng mạng
  final void Function(NetworkQuality) _onQualityChanged;
  
  // Chất lượng mạng hiện tại
  NetworkQuality _currentQuality = NetworkQuality.unknown;
  
  // Thời gian giữa các lần kiểm tra (ms)
  final int _checkIntervalMs;
  
  /// Constructor
  NetworkQualityMonitor({
    required SocketAnalytics analytics,
    required void Function(NetworkQuality) onQualityChanged,
    Logger? logger,
    int checkIntervalMs = 30000,
  }) : 
    _analytics = analytics,
    _onQualityChanged = onQualityChanged,
    _logger = logger ?? Logger(),
    _checkIntervalMs = checkIntervalMs;
  
  /// Khởi động monitor
  void start() {
    _qualityCheckTimer?.cancel();
    
    // Kiểm tra định kỳ
    _qualityCheckTimer = Timer.periodic(Duration(milliseconds: _checkIntervalMs), (_) {
      checkNetworkQuality();
    });
    
    // Thực hiện kiểm tra ngay lập tức
    checkNetworkQuality();
  }
  
  /// Dừng monitor
  void stop() {
    _qualityCheckTimer?.cancel();
    _qualityCheckTimer = null;
  }
  
  /// Kiểm tra chất lượng mạng
  Future<NetworkQuality> checkNetworkQuality() async {
    try {
      final health = await _analytics.checkConnectionHealth();
      
      // Cập nhật chất lượng mạng
      final quality = _mapQualityFromHealth(health);
      
      if (quality != _currentQuality) {
        _currentQuality = quality;
        _onQualityChanged(quality);
        
        _logger.i('Chất lượng mạng: $quality (latency: ${health['latency']['current']}ms)');
      }
      
      return quality;
    } catch (e) {
      _logger.e('Lỗi khi kiểm tra chất lượng kết nối: $e');
      return NetworkQuality.unknown;
    }
  }
  
  /// Chuyển đổi từ health data sang NetworkQuality
  NetworkQuality _mapQualityFromHealth(Map<String, dynamic> health) {
    final quality = health['quality'] as String;
    
    switch (quality) {
      case 'excellent':
        return NetworkQuality.excellent;
      case 'good':
        return NetworkQuality.good;
      case 'fair':
        return NetworkQuality.fair;
      case 'poor':
        return NetworkQuality.poor;
      default:
        return NetworkQuality.unknown;
    }
  }
  
  /// Chất lượng mạng hiện tại
  NetworkQuality get currentQuality => _currentQuality;
} 