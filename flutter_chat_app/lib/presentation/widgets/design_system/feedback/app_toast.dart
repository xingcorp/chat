import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';

/// A lightweight toast notification component.
///
/// Features:
/// - Multiple types (success, error, warning, info)
/// - Icon support
/// - Auto-dismiss
/// - Non-blocking
/// - Accessibility announcements
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppToast.show(
///   context: context,
///   message: 'Settings saved',
///   type: FeedbackType.success,
/// );
/// ```
class AppToast extends BaseStatelessWidget {
  /// Creates an [AppToast].
  const AppToast({
    required this.message,
    this.type = FeedbackType.info,
    super.key,
  });

  /// The message to display.
  final String message;

  /// The type of toast.
  final FeedbackType type;

  /// Shows a toast notification.
  static void show({
    required BuildContext context,
    required String message,
    FeedbackType type = FeedbackType.info,
    Duration? duration,
  }) {
    final effectiveDuration = duration ?? AppConstants.kToastDuration;
    
    // Announce to screen readers
    SemanticsService.announce(
      message,
      TextDirection.ltr,
      assertiveness: type == FeedbackType.error
          ? Assertiveness.assertive
          : Assertiveness.polite,
    );

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: AppDimens.paddingXLarge,
        left: AppDimens.paddingMedium,
        right: AppDimens.paddingMedium,
        child: _ToastAnimation(
          duration: effectiveDuration,
          child: AppToast(
            message: message,
            type: type,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss
    Future.delayed(
      effectiveDuration + AppConstants.kFastAnimationDuration,
      overlayEntry.remove,
    );
  }

  /// Shows a success toast.
  static void success({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      type: FeedbackType.success,
      duration: duration,
    );
  }

  /// Shows an error toast.
  static void error({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      type: FeedbackType.error,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shows a warning toast.
  static void warning({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      type: FeedbackType.warning,
      duration: duration,
    );
  }

  /// Shows an info toast.
  static void info({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      type: FeedbackType.info,
      duration: duration,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);

    final (backgroundColor, foregroundColor, icon) = _getColorsAndIcon(
      theme,
      type,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: foregroundColor,
              size: AppDimens.iconSmall,
            ),
            const SizedBox(width: AppDimens.spaceSmall),
            Flexible(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: foregroundColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (Color, Color, IconData) _getColorsAndIcon(
    ThemeData theme,
    FeedbackType type,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    
    switch (type) {
      case FeedbackType.success:
        return (
          AppColors.success,
          Colors.white,
          Icons.check_circle,
        );
      case FeedbackType.error:
        return (
          AppColors.error,
          Colors.white,
          Icons.error,
        );
      case FeedbackType.warning:
        return (
          AppColors.warning,
          Colors.white,
          Icons.warning_amber,
        );
      case FeedbackType.info:
        return (
          isDark ? AppColors.primary : AppColors.primary,
          Colors.white,
          Icons.info,
        );
    }
  }
}

/// Animation wrapper for toast.
class _ToastAnimation extends StatefulWidget {
  const _ToastAnimation({
    required this.child,
    required this.duration,
  });

  final Widget child;
  final Duration duration;

  @override
  State<_ToastAnimation> createState() => _ToastAnimationState();
}

class _ToastAnimationState extends State<_ToastAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.kDefaultAnimationDuration,
      reverseDuration: AppConstants.kFastAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Start fade out before removal
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
