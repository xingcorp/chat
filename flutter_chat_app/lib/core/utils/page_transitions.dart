import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/utils/animation_config.dart';
import 'package:flutter_chat_app/core/utils/device_performance_tier.dart';

/// Types of page transitions
enum PageTransitionType {
  /// Fade + slide from right
  fadeAndSlideFromRight,
  
  /// Fade + slide from left
  fadeAndSlideFromLeft,
  
  /// Fade + slide from bottom
  fadeAndSlideFromBottom,
  
  /// Fade in/out
  fade,
  
  /// Scale from center
  scale,
  
  /// No animation
  none,
}

/// Page transition manager
class PageTransitions {
  /// Get the animation configuration
  static AnimationConfig get _animConfig {
    try {
      return GetIt.I<AnimationConfig>();
    } catch (e) {
      // Fallback to default if not registered
      return AnimationConfig(DevicePerformanceTier.medium);
    }
  }
  
  /// Create a route with custom animation
  static Route<T> createRoute<T>({
    required Widget page,
    PageTransitionType type = PageTransitionType.fadeAndSlideFromRight,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    Duration? duration,
    Curve? curve,
  }) {
    // Get transition duration from config or use provided one
    final transitionDuration = duration ?? _animConfig.pageTransitionDuration;
    
    // Use default curve from config or provided one
    final animationCurve = curve ?? _animConfig.defaultCurve;
    
    // For low-end devices or when animations are turned off, use simpler transitions
    if (!_animConfig.useExtendedTransitions) {
      if (type != PageTransitionType.none) {
        type = PageTransitionType.fade; // Simplify to just fade
      }
    }
    
    return PageRouteBuilder<T>(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      maintainState: true,
      opaque: true,
      barrierDismissible: false,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(type, animation, secondaryAnimation, child, animationCurve);
      },
    );
  }
  
  /// Build transition animation
  static Widget _buildTransition(
    PageTransitionType type,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    Curve curve,
  ) {
    // Create a curved animation
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
      reverseCurve: curve.flipped,
    );
    
    // Handle secondary animation (for exit transitions)
    final Widget secondaryTransition = FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.5).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOut,
        ),
      ),
      child: child,
    );
    
    switch (type) {
      case PageTransitionType.fadeAndSlideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.25, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: secondaryTransition,
          ),
        );
        
      case PageTransitionType.fadeAndSlideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.25, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: secondaryTransition,
          ),
        );
        
      case PageTransitionType.fadeAndSlideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.25),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: secondaryTransition,
          ),
        );
        
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: secondaryTransition,
        );
        
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: secondaryTransition,
          ),
        );
        
      case PageTransitionType.none:
      default:
        return child;
    }
  }
  
  /// Extension method for BuildContext
  static Route<T> createAnimatedRoute<T>(
    BuildContext context,
    Widget page, {
    PageTransitionType type = PageTransitionType.fadeAndSlideFromRight,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    Duration? duration,
    Curve? curve,
  }) {
    // Consider device orientation and screen size for transition type
    if (type == PageTransitionType.fadeAndSlideFromRight) {
      final size = MediaQuery.of(context).size;
      
      // For wide screens (landscape), slide from bottom might be more natural
      if (size.width > size.height * 1.2) {
        type = PageTransitionType.fadeAndSlideFromBottom;
      }
    }
    
    return createRoute<T>(
      page: page,
      type: type,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      duration: duration,
      curve: curve,
    );
  }
  
  /// Create a material-style route with optimized transitions
  static MaterialPageRoute<T> createMaterialRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute<T>(
      builder: builder,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }
} 