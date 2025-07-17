import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/core/services/device_capability_service.dart';
import 'package:flutter_chat_app/core/utils/animation_config.dart';
import 'package:flutter_chat_app/core/utils/device_performance_tier.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Tipos de transição de página
enum PageTransitionType {
  /// Fade e slide da direita
  fadeAndSlideFromRight,
  
  /// Fade e slide da esquerda
  fadeAndSlideFromLeft,

  fadeAndSlideFromBottom,
  
  /// Scale e fade do centro
  scaleAndFade,
  
  /// Fade simples
  fade,

  scale,
  
  /// Slide de baixo para cima
  slideFromBottom,
  
  /// Slide simples da direita
  slideFromRight,
  
  /// Transição material padrão
  material,
  
  /// Transição cupertino padrão
  cupertino,
  
  /// Sem animação
  none,
}

/// Níveis de animação para configurar a experiência do usuário
enum AnimationLevel {
  /// Animações mínimas (dispositivos de baixo desempenho)
  low,
  
  /// Animações padrão (dispositivos de médio desempenho)
  medium,
  
  /// Animações ricas (dispositivos de alto desempenho)
  high,
}

/// Service quản lý animation trong ứng dụng
@singleton
class AnimationService {
  /// Service đánh giá khả năng thiết bị
  final DeviceCapabilityService? _deviceCapabilityService;
  
  /// Monitor de desempenho
  final PerformanceMonitor? _performanceMonitor;

  /// Logger instance
  final Logger _logger = Logger();

  /// Cấp hiệu năng thiết bị hiện tại
  late DevicePerformanceTier _currentPerformanceTier;
  
  /// Cấu hình animation hiện tại
  late AnimationConfig _config;
  
  /// Có đang trong chế độ tiết kiệm điện không
  bool _isLowPowerMode = false;
  
  /// Should preload images for optimized transitions
  bool _shouldPreloadImages = true;
  
  /// Current animation frame rate (for adaptive timing)
  double _currentFrameRate = 60.0;
  
  /// Contador de frames para monitorar o desempenho
  int _frameCount = 0;
  
  /// Timestamp do último check de taxa de quadros
  DateTime _lastFrameRateCheck = DateTime.now();
  
  /// Metric collection
  final bool _collectMetrics = true;
  
  /// Map of animation durations for performance analysis
  final Map<String, List<Duration>> _animationMetrics = {};
  
  /// Getter cho cấu hình animation
  AnimationConfig get config => _config;
  
  /// Get the current animation level based on performance tier
  AnimationLevel get currentLevel {
    switch (_currentPerformanceTier) {
      case DevicePerformanceTier.low:
        return AnimationLevel.low;
      case DevicePerformanceTier.medium:
        return AnimationLevel.medium;
      case DevicePerformanceTier.high:
        return AnimationLevel.high;
    }
  }
  
  /// Should preload images for smoother transitions
  bool get shouldPreloadImages => _shouldPreloadImages;
  
  /// Constructor
  AnimationService([this._deviceCapabilityService, this._performanceMonitor]);
  
  /// Khởi tạo service
  Future<void> initialize() async {
    // Phát hiện khả năng thiết bị
    _currentPerformanceTier = await DeviceCapabilityDetector.detectCapabilities();
    
    // Tạo cấu hình animation dựa trên khả năng thiết bị
    _config = _createConfig(currentLevel);
    
    // Start frame monitoring
    _startFrameMonitoring();
    
    _logger.i('Animation Service initialized with tier: $_currentPerformanceTier');
  }
  
  /// Start monitoring frame rate to adapt animations
  void _startFrameMonitoring() {
    // Use SchedulerBinding to monitor frame callbacks
    SchedulerBinding.instance.addPostFrameCallback(_monitorFrameRate);
  }
  
  /// Monitor frame rate to adjust animations
  void _monitorFrameRate(Duration timeStamp) {
    _frameCount++;
    
    final now = DateTime.now();
    final elapsed = now.difference(_lastFrameRateCheck);
    
    // Calculate frame rate every second
    if (elapsed.inMilliseconds >= 1000) {
      final newFrameRate = _frameCount * 1000 / elapsed.inMilliseconds;
      
      // Use exponential moving average for smoother transitions
      _currentFrameRate = _currentFrameRate * 0.7 + newFrameRate * 0.3;
      
      // Reset counters
      _frameCount = 0;
      _lastFrameRateCheck = now;
      
      // Adapt animations if framerate drops
      _adaptToFrameRate();
    }
    
    // Continue monitoring
    SchedulerBinding.instance.addPostFrameCallback(_monitorFrameRate);
  }
  
  /// Adapt animations to current frame rate
  void _adaptToFrameRate() {
    // If frame rate drops below 40fps, adjust animation settings
    if (_currentFrameRate < 40 && currentLevel != AnimationLevel.low) {
      // Temporarily downgrade animations
      _config = _createConfig(AnimationLevel.low);
      
      // Record metric
      if (_performanceMonitor != null) {
        _performanceMonitor!.addTraceMetric(
          TraceType.custom,
          customTraceName: 'animation_performance',
          metricName: 'framerate_drop',
          value: _currentFrameRate.toInt(),
        );
      }
    } 
    // If frame rate improves, restore original settings
    else if (_currentFrameRate > 55 && !_isLowPowerMode) {
      _config = _createConfig(currentLevel);
    }
  }
  
  /// Reset cấu hình sau khi thay đổi cài đặt
  Future<void> resetConfig() async {
    _currentPerformanceTier = await DeviceCapabilityDetector.detectCapabilities();
    _config = _createConfig(currentLevel);
  }
  
  /// Ghi đè cấp hiệu năng (hữu ích cho kiểm thử)
  void overridePerformanceTier(DevicePerformanceTier tier) {
    _currentPerformanceTier = tier;
    _config = _createConfig(currentLevel);
    
    // Cập nhật vào SharedPreferences (không đợi kết quả)
    DeviceCapabilityDetector.overridePerformanceTier(tier);
  }
  
  /// Tạo cấu hình dựa trên cấp độ animation
  AnimationConfig _createConfig(AnimationLevel level) {
    switch (level) {
      case AnimationLevel.low:
        return const AnimationConfig(
          defaultDuration: Duration(milliseconds: 150),
          longDuration: Duration(milliseconds: 300),
          fastDuration: Duration(milliseconds: 100),
          useHeroAnimations: false,
          useExtendedTransitions: false,
          useMicroAnimations: false,
          useAdvancedEffects: false,
          imageFilterQuality: FilterQuality.low,
          defaultCurve: Curves.linear,
        );
        
      case AnimationLevel.medium:
        return const AnimationConfig(
          defaultDuration: Duration(milliseconds: 250),
          longDuration: Duration(milliseconds: 400),
          fastDuration: Duration(milliseconds: 150),
          useHeroAnimations: true,
          useExtendedTransitions: true,
          useMicroAnimations: true,
          useAdvancedEffects: false,
          imageFilterQuality: FilterQuality.medium,
          defaultCurve: Curves.easeInOut,
        );
        
      case AnimationLevel.high:
        return const AnimationConfig(
          defaultDuration: Duration(milliseconds: 300),
          longDuration: Duration(milliseconds: 500),
          fastDuration: Duration(milliseconds: 200),
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
        _config = _createConfig(currentLevel);
      }
    }
  }
  
  /// Toggle image preloading
  void setImagePreloading(bool enabled) {
    _shouldPreloadImages = enabled;
  }
  
  /// Tạo PageRoute với animation phù hợp
  PageRoute<T> createRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    PageTransitionType transitionType = PageTransitionType.fadeAndSlideFromRight,
  }) {
    final type = _currentFrameRate < 30 ? PageTransitionType.none : transitionType;
    
    // Measure performance if enabled
    final String routeName = settings?.name ?? 'unknown_route';
    final startTime = _collectMetrics ? DateTime.now() : null;
    
    // Log transition start
    if (_performanceMonitor != null) {
      _performanceMonitor!.startTrace(
        TraceType.navigation,
        attributes: {'route': routeName},
      );
    }
    
    // Nếu thiết bị yếu hoặc cấu hình không dùng transition nâng cao
    if (type == PageTransitionType.none || 
        currentLevel == AnimationLevel.low || 
        !_config.useExtendedTransitions) {
      return MaterialPageRoute<T>(
        builder: (context) {
          if (startTime != null) {
            _recordTransitionCompletion(routeName, startTime);
          }
          return builder(context);
        },
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      );
    }
    
    // Sử dụng custom transition theo loại
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        if (startTime != null) {
          _recordTransitionCompletion(routeName, startTime);
        }
        return builder(context);
      },
      transitionDuration: _config.defaultDuration,
      fullscreenDialog: fullscreenDialog,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(
          type,
          animation.drive(CurveTween(curve: _config.defaultCurve)),
          secondaryAnimation.drive(CurveTween(curve: _config.defaultCurve)),
          child,
        );
      },
    );
  }
  
  /// Record transition completion for performance analysis
  void _recordTransitionCompletion(String routeName, DateTime startTime) {
    // Complete performance trace
    if (_performanceMonitor != null) {
      _performanceMonitor!.stopTrace(TraceType.navigation);
    }
    
    if (_collectMetrics) {
      final duration = DateTime.now().difference(startTime);
      
      if (!_animationMetrics.containsKey(routeName)) {
        _animationMetrics[routeName] = [];
      }
      
      // Keep last 5 measurements
      final metrics = _animationMetrics[routeName]!;
      metrics.add(duration);
      if (metrics.length > 5) {
        metrics.removeAt(0);
      }
      
      // Report metrics if slow
      if (duration.inMilliseconds > 500) {
        _logger.w('Slow page transition to $routeName: ${duration.inMilliseconds}ms');
      }
    }
  }
  
  /// Tạo transition widget theo loại
  Widget _buildTransition(
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
      
      case PageTransitionType.scaleAndFade:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
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
      
      case PageTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.25),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      
      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      
      case PageTransitionType.material:
      case PageTransitionType.cupertino:
      case PageTransitionType.none:
      default:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
    }
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
      case HapticFeedbackType.error:
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

/// Kiểu haptic feedback
enum HapticFeedbackType {
  /// Phản hồi nhẹ
  light,
  
  /// Phản hồi trung bình
  medium,
  
  /// Phản hồi nặng
  heavy,
  
  /// Phản hồi khi chọn
  selection,
  
  /// Phản hồi khi có lỗi
  error,
  
  /// Phản hồi rung
  vibrate,
}

/// Trạng thái animation cho components
enum AnimationState {
  /// Đang hiển thị bình thường
  normal,
  
  /// Đang hiển thị loading
  loading,
  
  /// Đang disabled
  disabled,
  
  /// Đang chọn
  selected,
  
  /// Đang rung lắc
  wobble,
  
  /// Đang pulse để thu hút sự chú ý
  pulse,
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

      case PageTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.25),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );

      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );

      case PageTransitionType.scaleAndFade:
        // TODO: Handle this case.
      case PageTransitionType.material:
        // TODO: Handle this case.
      case PageTransitionType.cupertino:


      default:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
    }
  }
} 