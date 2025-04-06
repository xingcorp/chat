import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:get_it/get_it.dart';

/// Types of animation in the application
enum AnimationType {
  /// Page transitions
  pageTransition,
  
  /// Message appearing in chat
  messageAppear,
  
  /// Media loading and display
  mediaDisplay,
  
  /// User interaction feedback
  interaction,
  
  /// Status changes (online/offline, typing, etc.)
  status,
  
  /// Message reaction animations
  reaction,
  
  /// Complex animations
  complex
}

/// Animation quality levels that can be applied
enum AnimationQuality {
  /// No animations
  off,
  
  /// Minimal animations (low-end devices)
  minimal,
  
  /// Standard animations (medium-end devices)
  standard,
  
  /// Rich animations (high-end devices)
  rich
}

/// A service that provides adaptive animations based on device capability
class AdaptiveAnimationManager {
  /// Current animation quality setting
  AnimationQuality _quality = AnimationQuality.standard;
  
  /// Performance monitor instance
  final PerformanceMonitor _performanceMonitor;
  
  /// Current frame rate (for adaptive timing)
  double _currentFrameRate = 60.0;
  
  /// Whether to reduce animations during low frame rates
  bool _adaptToFrameRate = true;
  
  /// Last time frame rate was checked
  DateTime _lastFrameRateCheck = DateTime.now();
  
  /// Count of frames since last check
  int _frameCount = 0;
  
  /// Current frame time target (in milliseconds)
  double get _frameTimeTarget => 1000.0 / _currentFrameRate;
  
  /// Creates an adaptive animation manager
  AdaptiveAnimationManager(this._performanceMonitor) {
    // Start monitoring frame rate
    _startFrameRateMonitoring();
    
    // Set initial quality based on device
    _determineOptimalQuality();
  }
  
  /// Get the current animation quality
  AnimationQuality get quality => _quality;
  
  /// Set the animation quality
  set quality(AnimationQuality newQuality) {
    _quality = newQuality;
    _performanceMonitor.recordCustomMetric(
      'animation_quality_set',
      _quality.index.toDouble(),
    );
  }
  
  /// Enable or disable frame rate adaptation
  set adaptToFrameRate(bool value) {
    _adaptToFrameRate = value;
  }
  
  /// Get appropriate duration for the given animation type
  Duration getDuration(AnimationType type) {
    final base = _getBaseDuration(type);
    
    // If adapting to frame rate and we're below target, shorten durations
    if (_adaptToFrameRate && _currentFrameRate < 45) {
      final factor = _currentFrameRate / 60.0;
      return Duration(milliseconds: (base.inMilliseconds * factor).round());
    }
    
    return base;
  }
  
  /// Get appropriate curve for the given animation type
  Curve getCurve(AnimationType type) {
    switch (quality) {
      case AnimationQuality.off:
        return Curves.linear;
        
      case AnimationQuality.minimal:
        return _getSimpleCurve(type);
        
      case AnimationQuality.standard:
        return _getStandardCurve(type);
        
      case AnimationQuality.rich:
        return _getRichCurve(type);
    }
  }
  
  /// Determine if animation should be skipped entirely
  bool shouldAnimate(AnimationType type) {
    if (quality == AnimationQuality.off) return false;
    
    // Skip non-essential animations during low frame rates
    if (_adaptToFrameRate && _currentFrameRate < 25) {
      switch (type) {
        case AnimationType.pageTransition:
        case AnimationType.status:
          return true; // These are important for UX
        case AnimationType.messageAppear:
        case AnimationType.mediaDisplay:
        case AnimationType.interaction:
        case AnimationType.reaction:
        case AnimationType.complex:
          return false; // These can be skipped during performance issues
      }
    }
    
    return true;
  }
  
  /// Create an optimized animation controller
  AnimationController createController({
    required TickerProvider vsync,
    required AnimationType type,
    Duration? duration,
    Duration? reverseDuration,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration ?? getDuration(type),
      reverseDuration: reverseDuration,
    );
  }
  
  /// Create a staggered animation group
  List<Animation<double>> createStaggeredGroup({
    required AnimationController controller,
    required int itemCount,
    required double startInterval,
    required double endInterval,
  }) {
    final animations = <Animation<double>>[];
    
    // Skip staggering for minimal quality or during performance issues
    if (quality == AnimationQuality.minimal || (_adaptToFrameRate && _currentFrameRate < 30)) {
      // Just use the controller directly for all animations
      for (int i = 0; i < itemCount; i++) {
        animations.add(controller);
      }
      return animations;
    }
    
    // Calculate interval size
    final intervalSize = (endInterval - startInterval) / (itemCount - 1).clamp(1, double.infinity);
    
    // Create staggered animations
    for (int i = 0; i < itemCount; i++) {
      final start = startInterval + (i * intervalSize);
      final end = start + ((1.0 - endInterval) / itemCount);
      
      animations.add(
        CurvedAnimation(
          parent: controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    }
    
    return animations;
  }
  
  /// Apply hero animation for media with adaptive settings
  Widget applyMediaHero({
    required Widget child,
    required String tag,
    bool enabled = true,
  }) {
    // Skip heroes for minimal quality or during performance issues
    if (!enabled || quality == AnimationQuality.minimal || 
        (_adaptToFrameRate && _currentFrameRate < 30)) {
      return child;
    }
    
    return Hero(
      tag: tag,
      child: child,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        // Use simpler animation for medium frame rates
        if (_currentFrameRate < 45) {
          return child;
        }
        
        // Full hero animation for high frame rates
        final Widget toHero = toHeroContext.widget as Hero;
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutQuad),
            ),
          ),
          child: toHero.child,
        );
      },
    );
  }
  
  /// Start monitoring frame rate
  void _startFrameRateMonitoring() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _frameCount++;
      
      final now = DateTime.now();
      final elapsed = now.difference(_lastFrameRateCheck).inMilliseconds;
      
      // Update frame rate every second
      if (elapsed >= 1000) {
        _currentFrameRate = (_frameCount * 1000 / elapsed).clamp(1, 120);
        
        _performanceMonitor.recordCustomMetric(
          'current_frame_rate',
          _currentFrameRate,
        );
        
        _frameCount = 0;
        _lastFrameRateCheck = now;
      }
      
      // Continue monitoring
      _startFrameRateMonitoring();
    });
  }
  
  /// Determine the optimal animation quality for the device
  void _determineOptimalQuality() {
    // Check device capabilities
    final deviceInfo = window.physicalSize;
    final refreshRate = window.refreshRate;
    final devicePixelRatio = window.devicePixelRatio;
    
    // High-end device check
    if (refreshRate >= 90 && devicePixelRatio >= 2.5) {
      quality = AnimationQuality.rich;
      return;
    }
    
    // Low-end device check
    if (devicePixelRatio <= 1.5 || refreshRate <= 30) {
      quality = AnimationQuality.minimal;
      return;
    }
    
    // Default to standard
    quality = AnimationQuality.standard;
  }
  
  /// Get base duration for animation based on quality and type
  Duration _getBaseDuration(AnimationType type) {
    switch (quality) {
      case AnimationQuality.off:
        return Duration.zero;
        
      case AnimationQuality.minimal:
        switch (type) {
          case AnimationType.pageTransition:
            return const Duration(milliseconds: 150);
          case AnimationType.messageAppear:
            return const Duration(milliseconds: 100);
          case AnimationType.mediaDisplay:
            return const Duration(milliseconds: 150);
          case AnimationType.interaction:
            return const Duration(milliseconds: 80);
          case AnimationType.status:
            return const Duration(milliseconds: 120);
          case AnimationType.reaction:
            return const Duration(milliseconds: 150);
          case AnimationType.complex:
            return const Duration(milliseconds: 200);
        }
        
      case AnimationQuality.standard:
        switch (type) {
          case AnimationType.pageTransition:
            return const Duration(milliseconds: 300);
          case AnimationType.messageAppear:
            return const Duration(milliseconds: 200);
          case AnimationType.mediaDisplay:
            return const Duration(milliseconds: 250);
          case AnimationType.interaction:
            return const Duration(milliseconds: 150);
          case AnimationType.status:
            return const Duration(milliseconds: 200);
          case AnimationType.reaction:
            return const Duration(milliseconds: 300);
          case AnimationType.complex:
            return const Duration(milliseconds: 400);
        }
        
      case AnimationQuality.rich:
        switch (type) {
          case AnimationType.pageTransition:
            return const Duration(milliseconds: 400);
          case AnimationType.messageAppear:
            return const Duration(milliseconds: 350);
          case AnimationType.mediaDisplay:
            return const Duration(milliseconds: 400);
          case AnimationType.interaction:
            return const Duration(milliseconds: 200);
          case AnimationType.status:
            return const Duration(milliseconds: 300);
          case AnimationType.reaction:
            return const Duration(milliseconds: 450);
          case AnimationType.complex:
            return const Duration(milliseconds: 600);
        }
    }
  }
  
  /// Get simplified curve for low-end devices
  Curve _getSimpleCurve(AnimationType type) {
    switch (type) {
      case AnimationType.pageTransition:
      case AnimationType.mediaDisplay:
        return Curves.easeOut;
      default:
        return Curves.easeInOut;
    }
  }
  
  /// Get standard curve for normal devices
  Curve _getStandardCurve(AnimationType type) {
    switch (type) {
      case AnimationType.pageTransition:
        return Curves.easeOutCubic;
      case AnimationType.messageAppear:
        return Curves.easeOutQuad;
      case AnimationType.mediaDisplay:
        return Curves.easeOutQuart;
      case AnimationType.interaction:
        return Curves.easeOutCirc;
      case AnimationType.status:
        return Curves.easeInOut;
      case AnimationType.reaction:
        return Curves.elasticOut;
      case AnimationType.complex:
        return Curves.easeInOutCubic;
    }
  }
  
  /// Get rich curve for high-end devices
  Curve _getRichCurve(AnimationType type) {
    switch (type) {
      case AnimationType.pageTransition:
        return Curves.easeOutCubic;
      case AnimationType.messageAppear:
        return Curves.easeOutCubic;
      case AnimationType.mediaDisplay:
        return Curves.easeOutQuart;
      case AnimationType.interaction:
        return Curves.easeOutCirc;
      case AnimationType.status:
        return Curves.easeInOutCubic;
      case AnimationType.reaction:
        return Curves.elasticOut;
      case AnimationType.complex:
        return Curves.easeInOutCubicEmphasized;
    }
  }
}

/// A widget that applies adaptive animations based on the current device capability
class AdaptiveAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration? duration;
  final Duration? reverseDuration;
  final AnimationType animationType;
  final Curve? curve;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Decoration? decoration;
  final BoxConstraints? constraints;
  final Matrix4? transform;
  
  const AdaptiveAnimatedContainer({
    Key? key,
    required this.child,
    this.duration,
    this.reverseDuration,
    this.animationType = AnimationType.interaction,
    this.curve,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.constraints,
    this.transform,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final animationManager = GetIt.I<AdaptiveAnimationManager>();
    
    // Skip animation if needed
    if (!animationManager.shouldAnimate(animationType)) {
      return Container(
        alignment: alignment,
        padding: padding,
        color: color,
        decoration: decoration,
        constraints: constraints,
        transform: transform,
        child: child,
      );
    }
    
    return AnimatedContainer(
      duration: duration ?? animationManager.getDuration(animationType),
      curve: curve ?? animationManager.getCurve(animationType),
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      constraints: constraints,
      transform: transform,
      child: child,
    );
  }
} 