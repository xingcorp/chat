import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/utils/animation_config.dart';
import 'package:flutter_chat_app/core/utils/device_performance_tier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_chat_app/core/services/device_capability_service.dart';
import 'package:get_it/get_it.dart';

/// Service quản lý animation trong ứng dụng
@singleton
class AnimationService {
  /// Cấp hiệu năng thiết bị hiện tại
  late DevicePerformanceTier _currentPerformanceTier;
  
  /// Cấu hình animation hiện tại
  late AnimationConfig _config;
  
  /// Getter cho cấu hình animation
  AnimationConfig get config => _config;
  
  /// Constructor
  AnimationService();
  
  /// Khởi tạo service
  Future<void> initialize() async {
    // Phát hiện khả năng thiết bị
    _currentPerformanceTier = await DeviceCapabilityDetector.detectCapabilities();
    
    // Tạo cấu hình animation dựa trên khả năng thiết bị
    _config = AnimationConfig(_currentPerformanceTier);
    
    print('Animation Service initialized with tier: $_currentPerformanceTier');
  }
  
  /// Reset cấu hình sau khi thay đổi cài đặt
  Future<void> resetConfig() async {
    _currentPerformanceTier = await DeviceCapabilityDetector.detectCapabilities();
    _config = AnimationConfig(_currentPerformanceTier);
  }
  
  /// Ghi đè cấp hiệu năng (hữu ích cho kiểm thử)
  void overridePerformanceTier(DevicePerformanceTier tier) {
    _currentPerformanceTier = tier;
    _config = AnimationConfig(tier);
    
    // Cập nhật vào SharedPreferences (không đợi kết quả)
    DeviceCapabilityDetector.overridePerformanceTier(tier);
  }
}

/// Service quản lý cấu hình animation toàn ứng dụng
/// Dựa trên khả năng thiết bị để tối ưu hiệu suất
class AnimationService {
  /// Service đánh giá khả năng thiết bị
  final DeviceCapabilityService _deviceCapabilityService;
  
  /// Cấu hình animation hiện tại
  late AnimationConfig _config;
  
  /// Có đang trong chế độ tiết kiệm điện không
  bool _isLowPowerMode = false;
  
  /// Constructor
  AnimationService(this._deviceCapabilityService) {
    // Khởi tạo cấu hình mặc định
    _config = _createConfig(_deviceCapabilityService.currentLevel);
    
    // Lắng nghe thay đổi cấp độ
    _deviceCapabilityService.onLevelChange.listen(_handleLevelChange);
  }
  
  /// Getter cho cấu hình hiện tại
  AnimationConfig get config => _config;
  
  /// Xử lý khi cấp độ animation thay đổi
  void _handleLevelChange(AnimationLevel level) {
    _config = _createConfig(level);
  }
  
  /// Tạo cấu hình dựa trên cấp độ animation
  AnimationConfig _createConfig(AnimationLevel level) {
    switch (level) {
      case AnimationLevel.low:
        return AnimationConfig(
          defaultDuration: const Duration(milliseconds: 150),
          longDuration: const Duration(milliseconds: 300),
          fastDuration: const Duration(milliseconds: 100),
          useHeroAnimations: false,
          useExtendedTransitions: false,
          useMicroAnimations: false,
          useAdvancedEffects: false,
          imageFilterQuality: FilterQuality.low,
          defaultCurve: Curves.linear,
        );
        
      case AnimationLevel.medium:
        return AnimationConfig(
          defaultDuration: const Duration(milliseconds: 250),
          longDuration: const Duration(milliseconds: 400),
          fastDuration: const Duration(milliseconds: 150),
          useHeroAnimations: true,
          useExtendedTransitions: true,
          useMicroAnimations: true,
          useAdvancedEffects: false,
          imageFilterQuality: FilterQuality.medium,
          defaultCurve: Curves.easeInOut,
        );
        
      case AnimationLevel.high:
        return AnimationConfig(
          defaultDuration: const Duration(milliseconds: 300),
          longDuration: const Duration(milliseconds: 500),
          fastDuration: const Duration(milliseconds: 200),
          useHeroAnimations: true,
          useExtendedTransitions: true,
          useMicroAnimations: true,
          useAdvancedEffects: true,
          imageFilterQuality: FilterQuality.high,
          defaultCurve: Curves.easeOutCubic,
        );
    }
  }
  
  /// Thiết lập chế độ tiết kiệm điện
  void setLowPowerMode(bool isLowPower) {
    if (_isLowPowerMode != isLowPower) {
      _isLowPowerMode = isLowPower;
      
      // Nếu bật chế độ tiết kiệm điện, giảm cấp độ animation
      if (_isLowPowerMode) {
        _config = _createConfig(AnimationLevel.low);
      } else {
        // Khôi phục về cấp độ ban đầu
        _config = _createConfig(_deviceCapabilityService.currentLevel);
      }
    }
  }
  
  /// Tạo PageRoute với animation phù hợp
  PageRoute<T> createRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    PageTransitionType transitionType = PageTransitionType.fadeAndSlideFromRight,
  }) {
    // Nếu thiết bị yếu, luôn dùng transition đơn giản
    if (_deviceCapabilityService.currentLevel == AnimationLevel.low || 
        !_config.useExtendedTransitions) {
      return MaterialPageRoute<T>(
        builder: builder,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      );
    }
    
    // Sử dụng custom transition theo loại
    return PageTransitions.createRoute<T>(
      page: builder,
      type: transitionType,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      duration: _config.defaultDuration,
      curve: _config.defaultCurve,
    );
  }
  
  /// Tạo heroTag với prefix
  String createHeroTag(String id, String prefix) {
    return '${prefix}_$id';
  }
  
  /// Tạo opacity animation theo cấu hình
  Widget wrapWithFadeAnimation(
    Widget child, {
    required bool visible,
    Duration? duration,
    Curve? curve,
  }) {
    // Nếu không dùng micro-animations, trả về luôn
    if (!_config.useMicroAnimations) {
      return visible ? child : const SizedBox.shrink();
    }
    
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: duration ?? _config.fastDuration,
      curve: curve ?? _config.defaultCurve,
      child: child,
    );
  }
  
  /// Tùy chỉnh kiểu haptic feedback theo cấu hình
  Future<void> performHapticFeedback(HapticFeedbackType type) async {
    // Nếu không dùng advanced effects, không thực hiện
    if (!_config.useAdvancedEffects) {
      return;
    }
    
    switch (type) {
      case HapticFeedbackType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        await HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        await HapticFeedback.vibrate();
        break;
    }
  }
}

/// Cấu hình animation cho toàn ứng dụng
class AnimationConfig {
  /// Thời gian animation mặc định
  final Duration defaultDuration;
  
  /// Thời gian animation dài
  final Duration longDuration;
  
  /// Thời gian animation nhanh
  final Duration fastDuration;
  
  /// Có sử dụng Hero animation không
  final bool useHeroAnimations;
  
  /// Có sử dụng chuyển trang nâng cao không
  final bool useExtendedTransitions;
  
  /// Có sử dụng micro-animations không
  final bool useMicroAnimations;
  
  /// Có sử dụng hiệu ứng nâng cao không
  final bool useAdvancedEffects;
  
  /// Chất lượng filter cho hình ảnh
  final FilterQuality imageFilterQuality;
  
  /// Curve mặc định cho animation
  final Curve defaultCurve;
  
  /// Constructor
  const AnimationConfig({
    required this.defaultDuration,
    required this.longDuration,
    required this.fastDuration,
    required this.useHeroAnimations,
    required this.useExtendedTransitions,
    required this.useMicroAnimations,
    required this.useAdvancedEffects,
    required this.imageFilterQuality,
    required this.defaultCurve,
  });
}

/// Kiểu chuyển trang
enum PageTransitionType {
  /// Fade và trượt từ phải sang
  fadeAndSlideFromRight,
  
  /// Fade và trượt từ trái sang
  fadeAndSlideFromLeft,
  
  /// Fade và trượt từ dưới lên
  fadeAndSlideFromBottom,
  
  /// Chỉ fade
  fade,
  
  /// Hiệu ứng phóng to
  scale,
  
  /// Không có hiệu ứng
  none,
}

/// Kiểu haptic feedback
enum HapticFeedbackType {
  /// Nhẹ
  light,
  
  /// Vừa
  medium,
  
  /// Mạnh
  heavy,
  
  /// Selection
  selection,
  
  /// Rung
  vibrate,
}

/// Utility class cho page transitions
class PageTransitions {
  /// Tạo route với animation
  static PageRoute<T> createRoute<T>({
    required WidgetBuilder page,
    required PageTransitionType type,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page(context),
      transitionDuration: duration,
      fullscreenDialog: fullscreenDialog,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(
          type,
          animation.drive(CurveTween(curve: curve)),
          secondaryAnimation.drive(CurveTween(curve: curve)),
          child,
        );
      },
    );
  }
  
  /// Tạo transition widget theo loại
  static Widget _buildTransition(
    PageTransitionType type,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (type) {
      case PageTransitionType.fadeAndSlideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.25, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
        
      case PageTransitionType.fadeAndSlideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.25, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
        
      case PageTransitionType.fadeAndSlideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.25),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
        
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
        
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
        
      case PageTransitionType.none:
        return child;
    }
  }
} 