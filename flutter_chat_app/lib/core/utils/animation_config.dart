import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/utils/device_performance_tier.dart';

/// Animation configuration manager based on device capability
class AnimationConfig {
  /// Device performance tier
  final DevicePerformanceTier performanceTier;
  
  /// Default animation duration
  final Duration? _defaultDuration;
  
  /// Long animation duration
  final Duration? _longDuration;
  
  /// Fast/short animation duration
  final Duration? _fastDuration;
  
  /// Default animation curve
  final Curve? _defaultCurve;
  
  /// Use Hero animations
  final bool? _useHeroAnimations;
  
  /// Use extended transitions
  final bool? _useExtendedTransitions;
  
  /// Use micro animations
  final bool? _useMicroAnimations;
  
  /// Use advanced effects
  final bool? _useAdvancedEffects;
  
  /// Image filter quality when zooming/scaling
  final FilterQuality? _imageFilterQuality;
  
  /// Basic constructor
  const AnimationConfig(this.performanceTier)
      : _defaultDuration = null,
        _longDuration = null,
        _fastDuration = null,
        _defaultCurve = null,
        _useHeroAnimations = null,
        _useExtendedTransitions = null,
        _useMicroAnimations = null,
        _useAdvancedEffects = null,
        _imageFilterQuality = null;
  
  /// Full constructor for detailed customization
  const AnimationConfig.custom({
    required this.performanceTier,
    Duration? defaultDuration,
    Duration? longDuration,
    Duration? fastDuration,
    Curve? defaultCurve,
    bool? useHeroAnimations,
    bool? useExtendedTransitions,
    bool? useMicroAnimations,
    bool? useAdvancedEffects,
    FilterQuality? imageFilterQuality,
  })  : _defaultDuration = defaultDuration,
        _longDuration = longDuration,
        _fastDuration = fastDuration,
        _defaultCurve = defaultCurve,
        _useHeroAnimations = useHeroAnimations,
        _useExtendedTransitions = useExtendedTransitions,
        _useMicroAnimations = useMicroAnimations,
        _useAdvancedEffects = useAdvancedEffects,
        _imageFilterQuality = imageFilterQuality;
  
  /// Default animation duration
  Duration get defaultDuration {
    if (_defaultDuration != null) return _defaultDuration!;
    
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return const Duration(milliseconds: 150);
      case DevicePerformanceTier.medium:
        return const Duration(milliseconds: 250);
      case DevicePerformanceTier.high:
        return const Duration(milliseconds: 300);
    }
  }
  
  /// Long animation duration
  Duration get longDuration {
    if (_longDuration != null) return _longDuration!;
    
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return const Duration(milliseconds: 300);
      case DevicePerformanceTier.medium:
        return const Duration(milliseconds: 400);
      case DevicePerformanceTier.high:
        return const Duration(milliseconds: 500);
    }
  }
  
  /// Fast/short animation duration
  Duration get fastDuration {
    if (_fastDuration != null) return _fastDuration!;
    
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return const Duration(milliseconds: 100);
      case DevicePerformanceTier.medium:
        return const Duration(milliseconds: 150);
      case DevicePerformanceTier.high:
        return const Duration(milliseconds: 200);
    }
  }
  
  /// Page transition animation duration
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
  
  /// Typing indicator animation duration
  Duration get typingIndicatorDuration {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return const Duration(milliseconds: 500);
      case DevicePerformanceTier.medium:
      case DevicePerformanceTier.high:
        return const Duration(milliseconds: 400);
    }
  }
  
  /// Default animation curve
  Curve get defaultCurve {
    if (_defaultCurve != null) return _defaultCurve!;
    
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return Curves.easeInOut; // Simplest
      case DevicePerformanceTier.medium:
        return Curves.fastOutSlowIn;
      case DevicePerformanceTier.high:
        return Curves.easeInOutCubic; // Smoothest
    }
  }
  
  /// Whether to use Hero animations
  bool get useHeroAnimations {
    if (_useHeroAnimations != null) return _useHeroAnimations!;
    return performanceTier != DevicePerformanceTier.low;
  }
  
  /// Whether to use extended transitions
  bool get useExtendedTransitions {
    if (_useExtendedTransitions != null) return _useExtendedTransitions!;
    return performanceTier != DevicePerformanceTier.low;
  }
  
  /// Whether to use micro animations
  bool get useMicroAnimations {
    if (_useMicroAnimations != null) return _useMicroAnimations!;
    return performanceTier != DevicePerformanceTier.low;
  }
  
  /// Whether to use advanced effects
  bool get useAdvancedEffects {
    if (_useAdvancedEffects != null) return _useAdvancedEffects!;
    return performanceTier == DevicePerformanceTier.high;
  }
  
  /// Whether to use staggered animations
  bool get useStaggeredAnimations => performanceTier != DevicePerformanceTier.low;
  
  /// Whether to use complex animations
  bool get useComplexAnimations => performanceTier == DevicePerformanceTier.high;
  
  /// Image filter quality when zooming/scaling
  FilterQuality get imageFilterQuality {
    if (_imageFilterQuality != null) return _imageFilterQuality!;
    
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return FilterQuality.low;
      case DevicePerformanceTier.medium:
        return FilterQuality.medium;
      case DevicePerformanceTier.high:
        return FilterQuality.high;
    }
  }
  
  /// Delay between staggered animations
  Duration get staggeredDelay {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return const Duration(milliseconds: 30); // Almost no delay
      case DevicePerformanceTier.medium:
        return const Duration(milliseconds: 50);
      case DevicePerformanceTier.high:
        return const Duration(milliseconds: 70);
    }
  }
  
  /// Number of message items to animate at once when scrolling
  int get maxAnimatedMessagesAtOnce {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return 3;
      case DevicePerformanceTier.medium:
        return 6;
      case DevicePerformanceTier.high:
        return 10;
    }
  }

  /// Cache extent for images in pixels
  double get imageCacheExtent {
    switch (performanceTier) {
      case DevicePerformanceTier.low:
        return 500;
      case DevicePerformanceTier.medium:
        return 800;
      case DevicePerformanceTier.high:
        return 1200;
    }
  }
  
  /// Whether to preload images
  bool get preloadImages {
    return performanceTier != DevicePerformanceTier.low;
  }
  
  /// Whether to use optimized repaint boundaries
  bool get useRepaintBoundaries => true;
} 