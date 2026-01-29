import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/theme/app_theme_extensions.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';

/// A customizable snack bar component with consistent styling.
///
/// Features:
/// - Multiple types (success, error, warning, info)
/// - Icon support
/// - Action button support
/// - Auto-dismiss with configurable duration
/// - Accessibility announcements
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppSnackBar.show(
///   context: context,
///   message: 'Item deleted successfully',
///   type: FeedbackType.success,
///   action: SnackBarAction(
///     label: 'Undo',
///     onPressed: () {
///       // Undo logic
///     },
///   ),
/// );
/// ```
class AppSnackBar {
  /// Shows a snack bar with the given message and type.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show({
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

    final theme = Theme.of(context);
    final extensions = theme.extension<AppThemeExtensions>();
    
    // Get colors based on type
    final (backgroundColor, foregroundColor, icon) = _getColorsAndIcon(
      theme,
      extensions,
      type,
    );

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            icon,
            color: foregroundColor,
            size: AppDimens.iconSizeMedium,
          ),
          SizedBox(width: AppDimens.spaceSmall),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      action: action,
      duration: duration,
      showCloseIcon: showCloseIcon,
      closeIconColor: foregroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      margin: EdgeInsets.all(AppDimens.paddingMedium),
    );

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Shows a success snack bar.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> success({
    required BuildContext context,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    return show(
      context: context,
      message: message,
      type: FeedbackType.success,
      action: action,
      duration: duration,
    );
  }

  /// Shows an error snack bar.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> error({
    required BuildContext context,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 6),
    bool showCloseIcon = true,
  }) {
    return show(
      context: context,
      message: message,
      type: FeedbackType.error,
      action: action,
      duration: duration,
      showCloseIcon: showCloseIcon,
    );
  }

  /// Shows a warning snack bar.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> warning({
    required BuildContext context,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
  }) {
    return show(
      context: context,
      message: message,
      type: FeedbackType.warning,
      action: action,
      duration: duration,
    );
  }

  /// Shows an info snack bar.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> info({
    required BuildContext context,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    return show(
      context: context,
      message: message,
      type: FeedbackType.info,
      action: action,
      duration: duration,
    );
  }

  static (Color, Color, IconData) _getColorsAndIcon(
    ThemeData theme,
    AppThemeExtensions? extensions,
    FeedbackType type,
  ) {
    switch (type) {
      case FeedbackType.success:
        return (
          extensions?.successColor ?? Colors.green,
          extensions?.onSuccessColor ?? Colors.white,
          Icons.check_circle_outline,
        );
      case FeedbackType.error:
        return (
          theme.colorScheme.error,
          theme.colorScheme.onError,
          Icons.error_outline,
        );
      case FeedbackType.warning:
        return (
          extensions?.warningColor ?? Colors.orange,
          extensions?.onWarningColor ?? Colors.white,
          Icons.warning_amber_outlined,
        );
      case FeedbackType.info:
        return (
          extensions?.infoColor ?? theme.colorScheme.primary,
          extensions?.onInfoColor ?? theme.colorScheme.onPrimary,
          Icons.info_outline,
        );
    }
  }
}
