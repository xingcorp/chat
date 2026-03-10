import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/theme/app_theme_extensions.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';

/// A desktop-style snack bar notification.
///
/// Displays a card notification at the **top-right** corner with:
/// - Colored left accent stripe per type
/// - Icon in a soft-colored circle
/// - Bold title + message body
/// - Optional close button
/// - Slide-in from right animation
/// - Auto-dismiss with configurable duration
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppSnackBar.show(
///   context: context,
///   message: 'Item deleted successfully',
///   type: FeedbackType.success,
/// );
/// ```
class AppSnackBar {
  AppSnackBar._();

  /// Maximum width constraint for the toast card.
  static const double _maxWidth = 380.0;

  /// Left accent stripe width.
  static const double _stripeWidth = 4.0;

  /// Icon circle diameter.
  static const double _iconCircleSize = 34.0;

  /// Stack of active toasts for positioning.
  static final List<_ActiveToast> _activeToasts = [];

  /// Shows a snack bar with the given message and type.
  static void show({
    required BuildContext context,
    required String message,
    FeedbackType type = FeedbackType.info,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    bool showCloseIcon = false,
  }) {
    // Announce to screen readers
    SemanticsService.announce(
      message,
      TextDirection.ltr,
      assertiveness: type == FeedbackType.error
          ? Assertiveness.assertive
          : Assertiveness.polite,
    );

    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    late OverlayEntry overlayEntry;
    late _ActiveToast activeToast;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final index = _activeToasts.indexWhere(
          (t) => t.entry == overlayEntry,
        );
        // Each toast stacks below the previous one
        final topOffset = mediaQuery.padding.top +
            AppDimens.paddingMedium +
            (index >= 0 ? index * 76.0 : 0);

        return Positioned(
          top: topOffset,
          right: AppDimens.paddingMedium,
          child: _SnackBarAnimation(
            duration: duration,
            child: _SnackBarCard(
              message: message,
              type: type,
              theme: theme,
              action: action,
              showCloseIcon: showCloseIcon,
              onClose: () => _removeToast(activeToast),
            ),
          ),
        );
      },
    );

    activeToast = _ActiveToast(entry: overlayEntry);
    _activeToasts.add(activeToast);
    overlay.insert(overlayEntry);

    // Rebuild all toasts to recalculate positions
    _rebuildAll();

    // Auto-dismiss
    final totalDuration =
        duration + AppConstants.kDefaultAnimationDuration;
    Future.delayed(totalDuration, () => _removeToast(activeToast));
  }

  /// Shows a success snack bar.
  static void success({
    required BuildContext context,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context: context,
      message: message,
      type: FeedbackType.success,
      action: action,
      duration: duration,
    );
  }

  /// Shows an error snack bar.
  static void error({
    required BuildContext context,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 6),
    bool showCloseIcon = true,
  }) {
    show(
      context: context,
      message: message,
      type: FeedbackType.error,
      action: action,
      duration: duration,
      showCloseIcon: showCloseIcon,
    );
  }

  /// Shows a warning snack bar.
  static void warning({
    required BuildContext context,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
  }) {
    show(
      context: context,
      message: message,
      type: FeedbackType.warning,
      action: action,
      duration: duration,
    );
  }

  /// Shows an info snack bar.
  static void info({
    required BuildContext context,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context: context,
      message: message,
      type: FeedbackType.info,
      action: action,
      duration: duration,
    );
  }

  /// Removes a toast from the stack and rebuilds positions.
  static void _removeToast(_ActiveToast toast) {
    if (!toast.removed) {
      toast.removed = true;
      toast.entry.remove();
      _activeToasts.remove(toast);
      _rebuildAll();
    }
  }

  /// Rebuilds all overlay entries so positions update after removal.
  static void _rebuildAll() {
    for (final toast in _activeToasts) {
      if (!toast.removed) {
        toast.entry.markNeedsBuild();
      }
    }
  }
}

/// Tracks an active overlay toast entry.
class _ActiveToast {
  _ActiveToast({required this.entry});

  final OverlayEntry entry;
  bool removed = false;
}

// ---------------------------------------------------------------------------
// Card UI
// ---------------------------------------------------------------------------

/// The visual card widget for a snack bar notification.
class _SnackBarCard extends StatelessWidget {
  const _SnackBarCard({
    required this.message,
    required this.type,
    required this.theme,
    required this.onClose,
    this.action,
    this.showCloseIcon = false,
  });

  final String message;
  final FeedbackType type;
  final ThemeData theme;
  final SnackBarAction? action;
  final bool showCloseIcon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final extensions = theme.extension<AppThemeExtensions>();
    final (accentColor, icon) = _getAccentAndIcon(extensions, type);

    final backgroundColor =
        isDark ? AppColors.surfaceDarkMode : AppColors.surface;
    final textColor =
        isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary;
    final subtitleColor = textColor.withValues(alpha: 0.68);

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSnackBar._maxWidth,
          minWidth: 280,
        ),
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
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Left accent stripe ───
                Container(
                  width: AppSnackBar._stripeWidth,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppDimens.radiusMedium),
                      bottomLeft: Radius.circular(AppDimens.radiusMedium),
                    ),
                  ),
                ),

                // ─── Content area ───
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.paddingSmall + 4,
                      AppDimens.paddingSmall + 2,
                      AppDimens.paddingSmall,
                      AppDimens.paddingSmall + 2,
                    ),
                    child: Row(
                      children: [
                        // Icon with tinted background circle
                        Container(
                          width: AppSnackBar._iconCircleSize,
                          height: AppSnackBar._iconCircleSize,
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

                        const SizedBox(width: AppDimens.spaceSmall + 2),

                        // Title + message
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _typeTitle(type),
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
                                  color: subtitleColor,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Action button (if provided)
                        if (action != null) ...[
                          const SizedBox(width: AppDimens.spaceSmall),
                          TextButton(
                            onPressed: () {
                              action?.onPressed();
                              onClose();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.paddingSmall,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              action?.label ?? '',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        // Close icon (error toasts by default)
                        if (showCloseIcon) ...[
                          const SizedBox(width: 2),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              onPressed: onClose,
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              splashRadius: 14,
                              color: textColor.withValues(alpha: 0.45),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ],
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

  /// Display title for each feedback type.
  static String _typeTitle(FeedbackType type) {
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

  /// Returns accent color and icon for each feedback type.
  static (Color, IconData) _getAccentAndIcon(
    AppThemeExtensions? extensions,
    FeedbackType type,
  ) {
    switch (type) {
      case FeedbackType.success:
        return (
          extensions?.successColor ?? AppColors.success,
          Icons.check_circle_rounded,
        );
      case FeedbackType.error:
        return (
          AppColors.error,
          Icons.error_rounded,
        );
      case FeedbackType.warning:
        return (
          extensions?.warningColor ?? AppColors.warning,
          Icons.warning_amber_rounded,
        );
      case FeedbackType.info:
        return (
          extensions?.infoColor ?? AppColors.primary,
          Icons.info_rounded,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Animation
// ---------------------------------------------------------------------------

/// Slide-in from right + fade animation wrapper.
class _SnackBarAnimation extends StatefulWidget {
  const _SnackBarAnimation({
    required this.child,
    required this.duration,
  });

  final Widget child;
  final Duration duration;

  @override
  State<_SnackBarAnimation> createState() => _SnackBarAnimationState();
}

class _SnackBarAnimationState extends State<_SnackBarAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.kDefaultAnimationDuration,
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _controller.forward();

    // Begin exit animation before removal
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
