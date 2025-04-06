import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';

/// Các loại chuyển tiếp trang
enum PageTransitionType {
  /// Fade + slide từ phải sang
  fadeAndSlideFromRight,
  
  /// Fade + slide từ trái sang
  fadeAndSlideFromLeft,
  
  /// Fade + slide từ dưới lên
  fadeAndSlideFromBottom,
  
  /// Fade in/out
  fade,
  
  /// Scale từ trung tâm
  scale,
  
  /// Không có animation
  none,
}

/// Lớp quản lý chuyển tiếp trang
class PageTransitions {
  /// Service quản lý animation
  static final AnimationService _animationService = GetIt.I<AnimationService>();
  
  /// Tạo route với animation tùy chỉnh
  static Route<T> createRoute<T>({
    required Widget page,
    PageTransitionType type = PageTransitionType.fadeAndSlideFromRight,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: _animationService.config.pageTransitionDuration,
      reverseTransitionDuration: _animationService.config.pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(type, animation, child);
      },
    );
  }
  
  /// Tạo animation chuyển tiếp
  static Widget _buildTransition(
    PageTransitionType type,
    Animation<double> animation,
    Widget child,
  ) {
    const begin = 0.0;
    const end = 1.0;
    final curve = _animationService.config.defaultCurve;
    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);
    
    switch (type) {
      case PageTransitionType.fadeAndSlideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.25, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: offsetAnimation,
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
            opacity: offsetAnimation,
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
            opacity: offsetAnimation,
            child: child,
          ),
        );
        
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: offsetAnimation,
          child: child,
        );
        
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(animation),
          child: FadeTransition(
            opacity: offsetAnimation,
            child: child,
          ),
        );
        
      case PageTransitionType.none:
      default:
        return child;
    }
  }
  
  /// Extension cho Context
  static Route<T> createAnimatedRoute<T>(
    BuildContext context,
    Widget page, {
    PageTransitionType type = PageTransitionType.fadeAndSlideFromRight,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    return createRoute<T>(
      page: page,
      type: type,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
} 