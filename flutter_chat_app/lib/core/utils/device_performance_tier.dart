import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Các cấp độ hiệu năng thiết bị
enum DevicePerformanceTier {
  /// Thiết bị cấu hình thấp, cần giảm độ phức tạp animation
  low,
  
  /// Thiết bị cấu hình trung bình, sử dụng animation tiêu chuẩn
  medium,
  
  /// Thiết bị cấu hình cao, có thể sử dụng animation phức tạp
  high
}

/// Lớp quản lý phát hiện và xác định khả năng thiết bị
class DeviceCapabilityDetector {
  static const String _prefsKey = 'device_performance_tier';
  static DevicePerformanceTier? _cachedTier;
  
  /// Phát hiện khả năng thiết bị
  static Future<DevicePerformanceTier> detectCapabilities() async {
    // Nếu đã có cache, trả về giá trị cache
    if (_cachedTier != null) {
      return _cachedTier!;
    }
    
    // Kiểm tra xem đã có thông tin từ lần chạy trước không
    final prefs = await SharedPreferences.getInstance();
    final savedTier = prefs.getString(_prefsKey);
    if (savedTier != null) {
      try {
        _cachedTier = DevicePerformanceTier.values.firstWhere(
          (e) => e.toString() == savedTier
        );
        return _cachedTier!;
      } catch (_) {
        // Nếu có lỗi, tiếp tục với phát hiện mới
      }
    }
    
    // Phát hiện dựa trên nền tảng
    DevicePerformanceTier detectedTier;
    
    if (kIsWeb) {
      // Trên web, mặc định là medium vì khó phát hiện cấu hình chính xác
      detectedTier = DevicePerformanceTier.medium;
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Đối với thiết bị di động, thực hiện đánh giá đơn giản dựa trên RAM
      detectedTier = await _detectMobileCapabilities();
    } else {
      // Desktop mặc định là high
      detectedTier = DevicePerformanceTier.high;
    }
    
    // Lưu lại kết quả để lần sau sử dụng
    await prefs.setString(_prefsKey, detectedTier.toString());
    _cachedTier = detectedTier;
    
    return detectedTier;
  }
  
  /// Đánh giá khả năng thiết bị di động
  static Future<DevicePerformanceTier> _detectMobileCapabilities() async {
    // Thực hiện một kiểm tra đơn giản
    // Trong triển khai thực tế, cần sử dụng các package như device_info_plus
    // để lấy thông tin chi tiết hơn về thiết bị
    
    try {
      // Một micro-benchmark đơn giản để kiểm tra hiệu năng
      final startTime = DateTime.now();
      int sum = 0;
      
      // Thực hiện một số phép tính đơn giản để kiểm tra tốc độ
      for (int i = 0; i < 100000; i++) {
        sum += i;
      }
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      
      // Thời gian xử lý ngắn = thiết bị nhanh hơn
      if (duration < 30) {
        return DevicePerformanceTier.high;
      } else if (duration < 100) {
        return DevicePerformanceTier.medium;
      } else {
        return DevicePerformanceTier.low;
      }
    } catch (_) {
      // Nếu có lỗi, mặc định là medium để an toàn
      return DevicePerformanceTier.medium;
    }
  }
  
  /// Ghi đè cấp hiệu năng thiết bị (hữu ích cho kiểm thử)
  static Future<void> overridePerformanceTier(DevicePerformanceTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, tier.toString());
    _cachedTier = tier;
  }
  
  /// Xóa cấp hiệu năng đã lưu
  static Future<void> clearSavedPerformanceTier() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _cachedTier = null;
  }
} 