import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/utils/device_performance_tier.dart';

/// Lớp quản lý cấu hình animation dựa trên khả năng thiết bị
class AnimationConfig {
  /// Cấp hiệu năng thiết bị
  final DevicePerformanceTier performanceTier;
  
  /// Constructor
  const AnimationConfig(this.performanceTier);
  
  /// Thời lượng cho animation chung
  Duration get defaultDuration {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return const Duration(milliseconds: 150);
      case DevicePerformanceTier.medium:
        return const Duration(milliseconds: 250);
      case DevicePerformanceTier.high:
        return const Duration(milliseconds: 300);
    }
  }
  
  /// Thời lượng cho animation chuyển tiếp màn hình
  Duration get pageTransitionDuration {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return const Duration(milliseconds: 200);
      case DevicePerformanceTier.medium:
        return const Duration(milliseconds: 300);
      case DevicePerformanceTier.high:
        return const Duration(milliseconds: 350);
    }
  }
  
  /// Thời lượng cho animation typing indicator
  Duration get typingIndicatorDuration {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return const Duration(milliseconds: 500);
      case DevicePerformanceTier.medium:
      case DevicePerformanceTier.high:
        return const Duration(milliseconds: 400);
    }
  }
  
  /// Curve cho animation chung
  Curve get defaultCurve {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return Curves.easeInOut; // Đơn giản nhất
      case DevicePerformanceTier.medium:
        return Curves.fastOutSlowIn;
      case DevicePerformanceTier.high:
        return Curves.easeInOutCubic; // Mượt mà nhất
    }
  }
  
  /// Có sử dụng animation staggered không
  bool get useStaggeredAnimations => performanceTier != DevicePerformanceTier.low;
  
  /// Có sử dụng animation phức tạp không
  bool get useComplexAnimations => performanceTier == DevicePerformanceTier.high;
  
  /// Chất lượng hình ảnh khi zoom/scale
  FilterQuality get imageFilterQuality {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return FilterQuality.low;
      case DevicePerformanceTier.medium:
        return FilterQuality.medium;
      case DevicePerformanceTier.high:
        return FilterQuality.high;
    }
  }
  
  /// Độ trễ giữa các animation staggered
  Duration get staggeredDelay {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return const Duration(milliseconds: 30); // Hầu như không có độ trễ
      case DevicePerformanceTier.medium:
        return const Duration(milliseconds: 50);
      case DevicePerformanceTier.high:
        return const Duration(milliseconds: 80);
    }
  }
  
  /// Kích thước tối đa cho ListView.builder để tối ưu hiệu năng
  int get maxChatItemsPerBatch {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return 15; // Ít hơn cho thiết bị cấu hình thấp
      case DevicePerformanceTier.medium:
        return 25;
      case DevicePerformanceTier.high:
        return 35; // Nhiều hơn cho thiết bị cấu hình cao
    }
  }
} 