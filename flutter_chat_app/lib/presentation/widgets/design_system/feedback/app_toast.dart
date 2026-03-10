import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';

/// A lightweight toast notification component styled for desktop chat apps.
///
/// Features:
/// - Multiple types (success, error, warning, info)
/// - Positioned at top-right corner (desktop-friendly)
/// - Slides in from the right with fade animation
/// - Card-style with colored accent stripe
/// - Auto-dismiss with progress indicator
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
    this.duration,
    super.key,
  });

  /// The message to display.
  final String message;

  /// The type of toast.
  final FeedbackType type;

  /// The display duration (used for progress indicator).
  final Duration? duration;

  /// Maximum width of the toast card.
  static const double _maxWidth = 360.0;

  /// Shows a toast notification at the top-right corner.
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
        top: AppDimens.paddingXLarge + MediaQuery.of(context).padding.top,
        right: AppDimens.paddingMedium,
        child: _ToastAnimation(
          duration: effectiveDuration,
          child: AppToast(
            message: message,
            type: type,
            duration: effectiveDuration,
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
    final isDark = theme.brightness == Brightness.dark;

    final (accentColor, icon) = _getAccentAndIcon(type);
    final backgroundColor =
        isDark ? AppColors.surfaceDarkMode : AppColors.surface;
    final textColor =
        isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: AppDimens.paddingLarge,
                offset: const Offset(0, AppDimens.elevationMedium),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: AppDimens.elevationMedium,
                offset: const Offset(0, AppDimens.elevationSmall),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left accent stripe
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppDimens.radiusMedium),
                      bottomLeft: Radius.circular(AppDimens.radiusMedium),
                    ),
                  ),
                ),
                // Content
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingMedium,
                      vertical: AppDimens.paddingSmall + 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with subtle background circle
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: accentColor,
                            size: AppDimens.iconSmall,
                          ),
                        ),
                        const SizedBox(width: AppDimens.spaceSmall + 4),
                        // Message text
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTitle(type),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                message,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: textColor.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the title text for each toast type.
  static String _getTitle(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return 'Success';
      case FeedbackType.error:
        return 'Error';
      case FeedbackType.warning:
        return 'Warning';
      case FeedbackType.info:
        return 'Info';
    }
  }

  /// Returns the accent color and icon for each toast type.
  static (Color, IconData) _getAccentAndIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return (
          AppColors.success,
          Icons.check_circle_rounded,
        );
      case FeedbackType.error:
        return (
          AppColors.error,
          Icons.error_rounded,
        );
      case FeedbackType.warning:
        return (
          AppColors.warning,
          Icons.warning_amber_rounded,
        );
      case FeedbackType.info:
        return (
          AppColors.primary,
          Icons.info_rounded,
        );
    }
  }
}

/// Animation wrapper for toast — slides in from right with fade.
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
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Slide in from the right
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
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
